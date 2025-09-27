import jwt
from datetime import datetime, timedelta, UTC
import os

SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret")


def generate_token(email):
    payload = {
        "email": email,
        "exp": datetime.now(UTC) + timedelta(hours=1)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")


def verify_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload["email"]
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
