import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv

db = SQLAlchemy()
migrate = Migrate()


def create_app(config_name=None):
    # Load environment variables
    cur_dir = os.path.dirname(__file__)
    relative_path = os.path.join(cur_dir, "..", "..")
    base_dir = os.path.abspath(relative_path)

    return None
