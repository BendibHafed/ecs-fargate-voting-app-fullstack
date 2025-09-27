# seed.py
import sys
import os
from backend.app import create_app, db
from backend.app.models import Poll, Choice
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))


def seed_data():
    app = create_app()
    with app.app_context():
        db.drop_all()   # Reset database
        db.create_all()

        # Example poll
        poll1 = Poll(question="Best programming language?")
        poll1.choices = [
            Choice(text="Python"),
            Choice(text="C++"),
            Choice(text="Java")
        ]

        # Another poll
        poll2 = Poll(question="Favorite web framework?")
        poll2.choices = [
            Choice(text="Flask"),
            Choice(text="Django"),
            Choice(text="FastAPI")
        ]

        db.session.add_all([poll1, poll2])
        db.session.commit()
        print("Database seeded successfully!!")


if __name__ == "__main__":
    seed_data()
