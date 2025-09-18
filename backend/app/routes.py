from flask import Blueprint, jsonify, request, render_template, \
                    session, redirect, url_for
from backend.app import db
from backend.app.models import Poll, Choice, User

bp = Blueprint("main", __name__)


@bp.route("/healthz")
def healthz():
    return jsonify(status="ok")


@bp.route("/")
def index():
    return render_template("index.html")


@bp.route("/vote")
def vote():
    if "user_id" not in session:
        return redirect(url_for("main.index"))
    user_email = session.get("user_email", "unknown")
    polls = Poll.query.all()
    return render_template("vote.html", polls=polls,
                           session={"user_email": user_email})


@bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data["email"]).first()
    if user and user.check_password(data["password"]):
        session["user_id"] = user.id
        session["user_email"] = user.email
        return jsonify({"status": "logged_in"}), 200
    return jsonify({"error": "Invalid credentials"}), 401


@bp.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return jsonify({"status": "logged_out"}), 200


@bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    user = User(email=data.get("email"))
    user.set_password(data.get("password"))
    db.session.add(user)
    db.session.commit()
    return jsonify({"status": "registered"}), 200


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
    if "user_id" not in session:
        return jsonify({"error": "Authentication required"}), 401
    data = request.get_json()
    choice_id = data.get("choice_id")
    choice = Choice.query.filter_by(id=choice_id, poll_id=poll_id).first()
    if not choice:
        return jsonify({"error": "Invalid choice ID"}), 404
    choice.votes += 1
    db.session.commit()
    return jsonify({"status": "ok", "choice_id": choice.id,
                    "votes": choice.votes}), 200
