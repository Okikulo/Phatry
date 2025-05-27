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
     #image("login.png", width: 100%)   
    ][
     #image("register.png", width: 100%)   
    ]
  ]
]

#slide[
  #align(top)[
    #text(3em, blue)[*Outcome*]
    #only(1)[
      
    ]
    #toolbox.side-by-side[
     #image("groupview.png", width: 100%)   
    ][
     #image("chat.png", width: 100%)   
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
    #set text(size: 16pt)
    #figure(
      [
        ```python
        client: MongoClient[dict[str, Any]] = MongoClient(
            # NOTE: Actual username and password should go here
            "mongodb://root:mysecretpassword123@localhost:27017/"
        )
        db = client.get_database("chat")
        @@,```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Setting up MongoDB connection],
    )
  ]
  #only(2)[
    #set text(size: 16pt)
    #figure(
      [
        ```python
def convert_doc(doc: dict[str, Any]):
    return doc | {"id": str(doc["_id"])}


def now():
    return datetime.datetime.now(datetime.timezone.utc)

        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Define some utility functions],
    )
  ]
  #only(3)[
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
      caption: [Original SQL schema for reference],
    )
  ]
  #only(4)[
    #figure(
      [
        ```python
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
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Common database operations as functions for convenience (1)],
    )
  ]
  #only(5)[
    #figure(
      [
        ```python
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
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Common database operations as functions for convenience (2)],
    )
  ]
  #only(6)[
    #figure(
      [
        ```python
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
              return Response("Group not found", 404)

          if not db_user_is_member(group_id, user_id):
              db_group_member_insert(group_id, user_id)

          messages = db_message_get(group_id)
          return render_template("group_chat.html", group=group, messages=messages)
        ```  
      ],
      kind: "code snippet",
      supplement: [Code],
      caption: [Common database operations as functions for convenience (2)],
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
      #text(2em)[*Some things I learned doing this project:*]
      #linebreak()
      #linebreak()
      #text(1.8em)[
         - How a database is used in a real-world scenario.
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
      #text(2em)[*Some things I learned doing this project:*]
      #linebreak()
      #linebreak()
      #text(1.8em)[
         - How to use pymongodb
         - How is login actually implemented in projects
         - MongoDB barely requires any setup (even database creation is unnecessary). In contrast, we needed to create a setup script for Postgres.
         - SQL errors were easier to debug than MongoDB errors due to the predefined schema.
         - Python type checking is very important for medium-to-large projects
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
         - `docker-compose.yml` file and Docker container setup. 
         - `uv` project setup (dependency and virtual environment management)
         - `mongo.py` file.
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
