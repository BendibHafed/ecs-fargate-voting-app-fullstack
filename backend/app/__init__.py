import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv
from flask_cors import CORS

db = SQLAlchemy()
migrate = Migrate()


def create_app(config_name=None):
    # Load environment variables
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    load_dotenv(os.path.join(base_dir, ".env"))

    # Find the frontend paths
    template_folder = os.path.join(base_dir, "frontend", "templates")
    static_folder = os.path.join(base_dir, "frontend", "static")
    app = Flask(__name__, template_folder=template_folder, static_folder=static_folder)
    app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-secret")
    if not config_name:
        config_name = os.getenv("FLASK_CONFIG", "DevelopmentConfig")

    # map common aliases to actual config classes
    aliases = {
        "dev": "DevelopmentConfig",
        "development": "DevelopmentConfig",
        "prod": "ProductionConfig",
        "production": "ProductionConfig",
        "test": "TestingConfig",
        "testing": "TestingConfig",
    }

    # Normalization
    cfg_class = aliases.get(config_name.lower())
    if not cfg_class:
        if config_name.lower().endswith("config"):
            cfg_class = config_name
        else:
            cfg_class = config_name.capitalize() + "Config"

    # Load the configuration class from backend.app.config
    app.config.from_object(f"backend.app.config.{cfg_class}")

    if cfg_class == "DevelopmentConfig":
        CORS(app, origins=["http://localhost:3000"])
    else:
        CORS(app, origins=["http://localhost:3000", "https://aws_domain.com"])

    # Init & Bind the SQLAlchemy instance to the Flask App.
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app, origins=["*"])  # in Local Dev Step
    # CORS(app, origins=["https://frontend-domain.com"])  # in Production Step

    # Register blueprints
    from backend.app.routes import bp as main_bp

    app.register_blueprint(main_bp)
    return app


__all__ = ["create_app", "db"]
