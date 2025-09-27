from flask import Blueprint, jsonify, request
from backend.app import db
from backend.app.models import Poll, Choice, User
from .auth_utils import generate_token, verify_token

bp = Blueprint("main", __name__)


@bp.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@bp.route("/")
def index():
    return jsonify({"message": "Backend is running"}), 200


@bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data["email"]).first()
    if user and user.check_password(data["password"]):
        token = generate_token(user.email)
        return jsonify({"token": token, "email": user.email}), 200
    return jsonify({"error": "Invalid credentials"}), 401


@bp.route("/logout", methods=["POST"])
def logout():
    return jsonify({"status": "logged_out"}), 200


@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    user = User(email=data.get("email"))
    user.set_password(data.get("password"))
    db.session.add(user)
    db.session.commit()
    return jsonify({"email": user.email}), 200


@bp.route("/api/polls")
def api_polls():
    polls = Poll.query.all()
    data = [{"id": p.id, "question": p.question} for p in polls]
    return jsonify(data)


@bp.route("/api/polls/<int:poll_id>/choices")
def api_choices(poll_id):
    choices = Choice.query.filter_by(poll_id=poll_id).all()
    data = [{"id": c.id, "text": c.text, "votes": c.votes} for c in choices]
    return jsonify(data)


@bp.route("/api/polls/<int:poll_id>/vote", methods=["POST"])
def api_vote(poll_id):
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return jsonify({"error": "Missing or Invalid token"}), 401
    token = auth_header.split(" ")[1]
    email = verify_token(token)
    if not email:
        return jsonify({"error": "Invalid or Expired token"}), 401

    data = request.get_json()
    choice_id = data.get("choice_id")
    choice = Choice.query.filter_by(id=choice_id, poll_id=poll_id).first()
    if not choice:
        return jsonify({"error": "Invalid choice ID"}), 404
    choice.votes += 1
    db.session.commit()
    return jsonify({"status": "ok", "choice_id": choice.id, "votes": choice.votes}), 200
