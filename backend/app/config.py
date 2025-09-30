import os


class Config:
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "dev-secret")
    SESSION_COOKIE_HTTPONLY = True
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevelopmentConfig(Config):
    DEBUG = True
    # Always use a local SQLite DB unless explicitly
    # overridden with DEV_DATABASE_URL
    SQLALCHEMY_DATABASE_URI = os.getenv("DEV_DATABASE_URL", "sqlite:///dev.db")


class TestingConfig(Config):
    TESTING = True
    # Always in-memory DB — completely isolated
    SQLALCHEMY_DATABASE_URI = os.getenv("TEST_DATABASE_URL", "sqlite:///:memory:")


class ProductionConfig(Config):
    DEBUG = False
    # Require DATABASE_URL in production
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")

    def __init__(self):
        if not self.SQLALCHEMY_DATABASE_URI:
            raise RuntimeError(
                "DATABASE_URL must be set\
                               in production environment!"
            )
