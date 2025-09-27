import pytest
from backend.app import create_app, db
from backend.app.models import Poll, Choice, User


@pytest.fixture
def app():
    app = create_app("testing")

    with app.app_context():
        db.create_all()

        # Seed test data
        user = User(email="test@example.com")
        user.set_password("secret")
        db.session.add(user)

        poll = Poll(question="Best programming language?")
        db.session.add(poll)
        db.session.commit()

        db.session.add_all([
            Choice(poll_id=poll.id, text="Python"),
            Choice(poll_id=poll.id, text="JavaScript")
        ])
        db.session.commit()

        yield app
        db.drop_all()


@pytest.fixture
def client(app):
    return app.test_client()
