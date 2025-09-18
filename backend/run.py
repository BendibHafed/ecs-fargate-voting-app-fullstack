import os
from backend.app import create_app

# Read the Env. var. called FLASK_CONFIG
config_name = os.getenv("FLASK_CONFIG")

app = create_app(config_name)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=True)