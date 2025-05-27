import os
from re import findall
import sys
from typing import Any, TypedDict

import datetime
import pymongo
from flask import (
    Flask,
    Response,
    flash,
    jsonify,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from flask_socketio import SocketIO, emit, join_room, leave_room
from pymongo import MongoClient
from werkzeug.security import check_password_hash, generate_password_hash
from bson import json_util, ObjectId

#
# error_log = 'error_log.txt'
# sys.stderr = open(error_log, 'w')

app = Flask(__name__)
app.config["SECRET_KEY"] = os.urandom(24)

# Initialize extensions
socketio = SocketIO(app)


client: MongoClient[dict[str, Any]] = MongoClient(
    "mongodb://root:mysecretpassword123@localhost:27017/"
)
db = client.get_database("chat")


def convert_doc(doc: dict[str, Any]):
    return doc | {"id": str(doc["_id"])}


def now():
    return datetime.datetime.now(datetime.timezone.utc)


def db_user_is_member(group_id: ObjectId, user_id: ObjectId):
    group_members = db.get_collection("group_members")
    group_member = group_members.find_one(dict(group_id=group_id, user_id=user_id))
    return group_member is not None


def db_group_insert(group_name: str):
    groups = db.get_collection("groups")
    new_group = dict(
        name=group_name,
        created_by=ObjectId(session["user_id"]),
        created_at=now(),
    )
    new_group_id: ObjectId = groups.insert_one(new_group).inserted_id
    return new_group_id


def db_group_member_insert(group_id: ObjectId, user_id: ObjectId):
    group_members = db.get_collection("group_members")
    new_group_member = dict(group_id=group_id, user_id=user_id, joined_at=now())
    return group_members.insert_one(new_group_member)


def db_message_get(group_id: ObjectId):
    messages = db.get_collection("messages")
    users = db.get_collection("users")

    messages = messages.find(dict(group_id=group_id)).sort("created_at")
    messages = [
        {
            "id": str(msg["_id"]),
            "user_id": str(msg["user_id"]),
            "user": users.find_one({"_id": msg["user_id"]}),
            "content": msg["content"],
            "created_at": msg["created_at"],
        }
        for msg in messages
    ]
    return messages


def db_message_insert(user_id: ObjectId, group_id: ObjectId, content: str):
    messages = db.get_collection("messages")
    new_message = dict(
        content=content, group_id=group_id, user_id=user_id, created_at=now()
    )
    _ = messages.insert_one(new_message)


# Routes
@app.route("/")
def index():
    if "user_id" not in session:
        return redirect(url_for("login"))

    groups = db.get_collection("groups")
    groups = groups.find()
    groups = [convert_doc(group) for group in groups]
    return render_template("index.html", groups=groups)


@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        users = db.get_collection("users")
        # Check if username already exists
        existing_user = users.find_one(dict(username=username))

        if existing_user is not None:
            flash("Username already exists!")
            return redirect(url_for("register"))

        # Create new user
        hashed_password = generate_password_hash(password)
        new_user = dict(
            username=username,
            password=hashed_password,
            created_at=now(),
        )
        _ = users.insert_one(new_user)
        flash("Registration successful! Please login.")
        return redirect(url_for("login"))

    return render_template("register.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        users = db.get_collection("users")
        # Check if username already exists
        user = users.find_one(dict(username=username))

        if user and check_password_hash(user["password"], password):
            session["user_id"] = str(user["_id"])
            session["username"] = user["username"]
            flash("Login successful!")
            return redirect(url_for("index"))
        else:
            flash("Invalid username or password")

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    flash("You have been logged out.")
    return redirect(url_for("login"))


@app.route("/create_group", methods=["GET", "POST"])
def create_group():
    if "user_id" not in session:
        return redirect(url_for("login"))

    user_id = ObjectId(session["user_id"])

    if request.method == "POST":
        group_name = request.form["group_name"]

        # Create new group
        new_group_id = db_group_insert(group_name)
        db_group_member_insert(new_group_id, user_id)
        flash(f'Group "{group_name}" created successfully!')
        return redirect(url_for("index"))

    return render_template("create_group.html")


@app.route("/group/<group_id>")
def group_chat(group_id):
    if "user_id" not in session:
        return redirect(url_for("login"))

    group_id = ObjectId(group_id)
    user_id = ObjectId(session["user_id"])

    groups = db.get_collection("groups")
    group = groups.find_one(dict(_id=group_id))
    group = convert_doc(group)

    if group is None:
        # TODO: Return proper 404
        return Response("Group not found", 404)

    if not db_user_is_member(group_id, user_id):
        db_group_member_insert(group_id, user_id)

    messages = db_message_get(group_id)
    return render_template("group_chat.html", group=group, messages=messages)


@app.route("/join_group/<group_id>")
def join_group(group_id):
    if "user_id" not in session:
        return redirect(url_for("login"))

    group_id = ObjectId(group_id)
    user_id = ObjectId(session["user_id"])

    if not db_user_is_member(group_id, user_id):
        db_group_member_insert(group_id, user_id)
        flash("You have joined the group!")
    else:
        flash("You are already a member of this group.")

    return redirect(url_for("group_chat", group_id=group_id))


@app.route("/api/messages/<group_id>")
def get_messages(group_id):
    group_id = ObjectId(group_id)

    if "user_id" not in session:
        return jsonify({"error": "Not authenticated"}), 401

    return jsonify(db_message_get(group_id))


# SocketIO event handlers
@socketio.on("join")
def handle_join(data):
    room = data["room"]
    join_room(room)
    emit(
        "status", {"message": f"{session['username']} has joined the room."}, room=room
    )


@socketio.on("leave")
def handle_leave(data):
    room = data["room"]
    leave_room(room)
    emit("status", {"message": f"{session['username']} has left the room."}, room=room)


@socketio.on("message")
def handle_message(data):
    room = data["room"]
    content = data["message"]
    user_id = ObjectId(session["user_id"])
    group_id = ObjectId(room)

    db_message_insert(user_id, group_id, content)

    # Broadcast message to room
    emit(
        "message",
        {
            "user": session["username"],
            "message": content,
            "time": now().strftime("%Y-%m-%d %H:%M:%S"),
        },
        room=room,
    )


if __name__ == "__main__":
    socketio.run(app, debug=True)
