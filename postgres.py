from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from flask_socketio import SocketIO, join_room, leave_room, emit
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import os
import sys

# error_log = 'error_log.txt'
# sys.stderr = open(error_log, 'w')

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://final:mysecretpassword123@localhost/phatry_db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# Initialize extensions
db = SQLAlchemy(app)
socketio = SocketIO(app)

# Database Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(200), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Group(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    created_by = db.Column(db.Integer, db.ForeignKey('user.id'))

class GroupMember(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.Text, nullable=False)
    group_id = db.Column(db.Integer, db.ForeignKey('group.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Define relationships for easy access
    user = db.relationship('User', backref='messages')
    group = db.relationship('Group', backref='messages')

# Create all tables
with app.app_context():
    db.create_all()

# Routes
@app.route('/')
def index():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    groups = Group.query.all()
    return render_template('index.html', groups=groups)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        # Check if username already exists
        existing_user = User.query.filter_by(username=username).first()
        if existing_user:
            flash('Username already exists!')
            return redirect(url_for('register'))
        
        # Create new user
        hashed_password = generate_password_hash(password)
        new_user = User(username=username, password=hashed_password)
        db.session.add(new_user)
        db.session.commit()
        
        flash('Registration successful! Please login.')
        return redirect(url_for('login'))
    
    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = User.query.filter_by(username=username).first()
        
        if user and check_password_hash(user.password, password):
            session['user_id'] = user.id
            session['username'] = user.username
            flash('Login successful!')
            return redirect(url_for('index'))
        else:
            flash('Invalid username or password')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out.')
    return redirect(url_for('login'))

@app.route('/create_group', methods=['GET', 'POST'])
def create_group():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        group_name = request.form['group_name']
        
        # Create new group
        new_group = Group(name=group_name, created_by=session['user_id'])
        db.session.add(new_group)
        db.session.commit()
        
        # Add creator as a member
        member = GroupMember(group_id=new_group.id, user_id=session['user_id'])
        db.session.add(member)
        db.session.commit()
        
        flash(f'Group "{group_name}" created successfully!')
        return redirect(url_for('index'))
    
    return render_template('create_group.html')

@app.route('/group/<int:group_id>')
def group_chat(group_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    group = Group.query.get_or_404(group_id)
    
    # Check if user is a member of the group
    is_member = GroupMember.query.filter_by(
        group_id=group_id, 
        user_id=session['user_id']
    ).first()
    
    if not is_member:
        # Join the group if not already a member
        new_member = GroupMember(group_id=group_id, user_id=session['user_id'])
        db.session.add(new_member)
        db.session.commit()
    
    # Get all messages for this group
    messages = Message.query.filter_by(group_id=group_id).order_by(Message.created_at).all()
    
    return render_template('group_chat.html', group=group, messages=messages)

@app.route('/join_group/<int:group_id>')
def join_group(group_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    # Check if user is already a member
    is_member = GroupMember.query.filter_by(
        group_id=group_id, 
        user_id=session['user_id']
    ).first()
    
    if not is_member:
        new_member = GroupMember(group_id=group_id, user_id=session['user_id'])
        db.session.add(new_member)
        db.session.commit()
        flash('You have joined the group!')
    else:
        flash('You are already a member of this group.')
    
    return redirect(url_for('group_chat', group_id=group_id))

@app.route('/api/messages/<int:group_id>')
def get_messages(group_id):
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    messages = Message.query.filter_by(group_id=group_id).order_by(Message.created_at).all()
    
    message_list = []
    for message in messages:
        message_list.append({
            'id': message.id,
            'content': message.content,
            'username': message.user.username,
            'created_at': message.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    
    return jsonify(message_list)

# SocketIO event handlers
@socketio.on('join')
def handle_join(data):
    room = data['room']
    join_room(room)
    emit('status', {'message': f"{session['username']} has joined the room."}, room=room)

@socketio.on('leave')
def handle_leave(data):
    room = data['room']
    leave_room(room)
    emit('status', {'message': f"{session['username']} has left the room."}, room=room)

@socketio.on('message')
def handle_message(data):
    room = data['room']
    content = data['message']
    
    # Save message to database
    new_message = Message(
        content=content,
        group_id=int(room),
        user_id=session['user_id']
    )
    db.session.add(new_message)
    db.session.commit()
    
    # Broadcast message to room
    emit('message', {
        'user': session['username'],
        'message': content,
        'time': datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    }, room=room)

if __name__ == '__main__':
    socketio.run(app, debug=True)
