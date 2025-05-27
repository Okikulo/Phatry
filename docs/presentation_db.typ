#import "@preview/polylux:0.4.0": *
#import "@preview/cetz:0.3.4"  
#import "@preview/cetz-plot:0.1.1": plot, chart

#set page(paper: "presentation-4-3")
#set text(font: "New Computer Modern")
#set par(justify: true)

#show raw.where(block: true): block.with(
    fill: luma(240),
    inset:12pt,
    radius: 8pt,
  )

#slide[
  #align(horizon)[
    #text(4em, blue)[*Database Final Project*\ ]
    #text(4em, blue)[*Phatry*]
    #linebreak()
    #linebreak()
    #linebreak()
    #text(1.5em)[*Minimal Chat App written using `Python`, `PostgreSQL`, `MongoDB` and `Flask Micro Web Framework` *]
    #linebreak()
    #linebreak()
  ]
  #align(bottom)[
    #text(1.5em)[_Database Systems_ | _Final Project Presentation and Demo_ | _May 28, 2025_]
    #text(1.5em)[_\ Presentation by: Aldo Acevedo, Fabrizio Diaz_ ]
  ]
]

#set page(numbering: "1")

#slide[
  #align(top)[
    #text(3em, blue)[*Outcome*]
    #only(1)[
      
    ]
    #toolbox.side-by-side[
     #image("screenshot_2025-05-27_17-01-14.png", width: 100%)   
    ][
     #image("screenshot_2025-05-27_18-04-19.png", width: 100%)   
    ]
    #toolbox.side-by-side[
     #image("screenshot_2025-05-27_17-59-38.png", width: 100%)   
    ][
     #image("screenshot_2025-05-27_17-35-07.png", width: 100%)   
    ]
  ]
]


#slide[
  #align(top)[
    // #text(3em, blue)[*`PostgreSQL` #box(image("PostgreSQL_logo.3colors.svg", width: 1cm, height: 1.1cm, fit: "contain")) Implementation*]
    #text(3em, blue)[*`PostgreSQL`  Implementation*]
  ]
  #only(1)[
    #set text(size: 16pt)
    #figure(
      [
        ```python
        # Initial config
        app.config['SECRET_KEY'] = os.urandom(24)
        app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@localhost/database_db'
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
        
        
        # Initialize extensions
        db = SQLAlchemy(app)
        socketio = SocketIO(app)

        # Definition of classes, 
        # .....

        # Create all tables
        with app.app_context():
            db.create_all()
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Setting basic config and Initializing Database],
    )
  ]
  #only(2)[
    #set text(size: 16pt)
    #figure(
      [
        ```python
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
        ```  
        
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Declaring the `User` and `Group` Database Models.],
    )
  ]
  #only(3)[
    #set text(size: 16pt)
    #figure(
      [
        ```python
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
        ```  
        
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Declaring the `GroupMember` and `Message` Database Models and also defining relationships.],
    )
    
  ]
  #only(4)[
    #set text(size: 14pt)
    #figure(
      [
        ```python
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

        ```  
        
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [```python register()``` function.],
    )
    
  ]
  #only(5)[
    #set text(size: 16pt)
    #figure(
      [
        ```python
        @app.route('/login', methods=['GET', 'POST'])
        def login():
            if request.method == 'POST':
                username = request.form['username']
                password = request.form['password']
                
                user = User.query.filter_by(username=username).first()
                
                # Checking User Credentials.
                if user and check_password_hash(user.password, password):
                    session['user_id'] = user.id
                    session['username'] = user.username
                    flash('Login successful!')
                    return redirect(url_for('index'))
                else:
                    flash('Invalid username or password')
            
            return render_template('login.html')
        ```  
        
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [```python login()``` function.],
    )
    
  ]
]

#slide[
  #align(top)[
    #text(3em, blue)[*`MongoDB` Implementation*]
  ]
  #only(1)[
    #figure(
      [
        ```python
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [],
    )
  ]
  #only(2)[
    #figure(
      [
        ```python
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [],
    )
  ]
  #only(3)[
    #figure(
      [
        ```python
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [],
    )
  ]
  #only(4)[
    #figure(
      [
        ```python
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [],
    )
  ]
  #only(5)[
    #figure(
      [
        ```python
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [],
    )
  ]
]

#slide[
  #align(top)[
    #text(3em, blue)[*What we learn*]
  ]
  #only(1)[
    #align(top)[
      #text(2em, blue)[*Fabrizio Diaz*]
      #linebreak()
      #linebreak()
      #text(2em)[*Some of things I learn whe doing this project:*]
      #linebreak()
      #linebreak()
      #text(1.8em)[
         - How to a database is used in a real-world scenario.
         - How to use database tools on Linux.
         - Web-Related Tools (HTML, CSS).
         - Python Frameworks.
         - Docker Files and Docker Compose.
         - Importance of Enviroment Variables (how to use .env files).
      ]
    ]
  ]
  #only(2)[
    #align(top)[
      #text(2em, blue)[*Aldo Acevedo*]
      #linebreak()
      #linebreak()
      #text(2em)[*Some of things I learn whe doing this project:*]
      #linebreak()
      #linebreak()
      #text(1.8em)[
         - 
         - 
         - 
         - 
         - 
      ]
    ]
  ]
]

#slide[
  #align(top)[
    #text(3em, blue)[*Contributions*]
  ]
    #align(top)[
      #text(2em, blue)[*Fabrizio Diaz*]
      #text(1.8em)[
         - PostgreSQL Implementation.
         - HTML Templates.
         - CSS Style file.
         - GitHub Repository setup.
         - `postgres.py` file.
      ]
    ]
    #align(horizon)[
      #text(2em, blue)[*Aldo Acevedo*]
      #text(1.8em)[
         - MongoDB Implementation
         - `docker-compose.yml` file and Docker support. 
         - `mongo.py` file.
         - 
      ]
    ]
  ]


#set page(numbering: none)

#slide[
  #align(center + horizon)[
    #text(4em, blue)[
      = Thank you \ for your time!
    ]
  ]
  #align(center + bottom)[
    #text(2em)[
      *To view the full project visit: \ * #link("https://github.com/Okikulo/Phatry")
    ]
  ]

]
