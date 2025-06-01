#import "uni_template.typ": database_hw, section, subsection, formatted_text

#show raw.where(block: true): block.with(
    fill: luma(240),
    inset:10pt,
    radius: 8pt,
)

#database_hw([Database Systems],[Final Project Report], [Phatry], [6/04])

#section([Outcome])
#formatted_text([
  #columns(2)[
    #figure(
      image("assets/login.png", width: 80%),
      caption:[Login Page]
    )
    #figure(
      image("assets/register.png", width: 80%),
      caption:[Register Page]
    )
    #figure(
      image("assets/groupview.png", width: 80%),
      caption:[Home Page]
    )
    #figure(
      image("assets/chat.png", width: 80%),
      caption:[Chat Example]
    )
  ]
  #show link: set text(fill: blue)
  Here we can see a basic overview of our chat app, we decided in a minimal implementation with a good design. There is a login page, if it is your first time using the app, we can redirect the user to a register. Once registered, the user logs in and is directed to the homepage. Here the user can see all the available groups to start chatting right away!. If you are interesting to try _Phatry_, you can visit the #link("https://github.com/Okikulo/Phatry")[github] page and follow the guidelines.
  #pagebreak()
])
#section([How are SQL and NoSQL used])
#subsection([`PostgreSQL`])
#formatted_text([
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
  ) <code1>

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
  ) <code2>

  In @code1 and @code2 we can see the most important part of the Postgres Implementation, which is the declaration of the tables and relationships of the database. We defined the tables with its corresponding fields, also using foreign keys using the ```python db.Model``` class. We can also see at the bottom of @code2 how realtionships are defined for the messages table specifically. This means that when a message is selected, two extra fields are added to have the same structure as the `User` and `Group` table, this performs a `JOIN` operation with both tables. @code3 shows us how the initial config looks, we can see how the `SQLALCHEMY_DATABASE_URI` is defined, this enviroment variable is crucial to setup, we can also see the two main classes `db` and `socketio`, being declared as well as the creation of all the classes (tables) seen earlier. This the main use of `SQL` in this version of the app, which is found in the `postgres.py` file, as explained in the presentation, we basically made two version of the same chat app, one with `PostgreSQL` and `MongoDB`.
   

  #figure(
      [
        ```python
        # Initial config
        app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@localhost/database_db'
       
        
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
  ) <code3>
])
#subsection[`MongoDB`]
#formatted_text([
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
    ) <code4>

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
    ) <code5>

    Since the logic and overall use of the database is similar to the postgres implementation, we are going to show how we did the 'transalation' to NoSQL. In @code4, @code5 and @code6 we can see how we implement some utility functions to help achieve a efficient database managenet.
    #pagebreak()
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
    ) <code6>
])
#section([What do you learn through this project])
#formatted_text([
  Here are something that we learn through the process of building the project. We can conclude that this was a enriching since expose us to professional development enviroment and teach us a lot of how the foundation of crucial modern technologies.
  #linebreak()

  #text(1em, blue)[*Aldo Acevedo*]
         - How to use pymongodb
         - How is login actually implemented in projects
         - MongoDB barely requires any setup (even database creation is unnecessary). In contrast, we needed to create a setup script for Postgres.
         - SQL errors were easier to debug than MongoDB errors due to the predefined schema.
         - Python type checking is very important for medium-to-large projects
  #linebreak()
  #text(1em, blue)[*Fabrizio Diaz*]
         - How a database is used in a real-world scenario.
         - How to use database tools on Linux.
         - Web-Related Tools (HTML, CSS).
         - Python Frameworks.
         - Docker Files and Docker Compose.
         - Importance of Enviroment Variables (how to use .env files).
])
#pagebreak()
#section([What’s the contribution of each member in your team?])
#formatted_text([
  #text(1em, blue)[*Aldo Acevedo*]
         - MongoDB Implementation
         - `docker-compose.yml` file and Docker container setup. 
         - `uv` project setup (dependency and virtual environment management)
         - `mongo.py` file.
  #linebreak()
  #text(1em, blue)[*Fabrizio Diaz*]
         - PostgreSQL Implementation.
         - HTML Templates.
         - CSS Style file.
         - GitHub Repository setup.
         - `postgres.py` file.
])






























