from flask import Flask
import os
import socket
import psycopg

app = Flask(__name__)


def get_db_connection():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=5,
    )


@app.route("/")
def home():
    return {
        "application": "AWS CloudOps Platform",
        "status": "running",
        "hostname": socket.gethostname(),
        "message": "Deployed with Docker on AWS EC2"
    }


@app.route("/health")
def health():
    return {
        "status": "healthy"
    }


@app.route("/db-health")
def db_health():
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT current_database();")
                database = cursor.fetchone()[0]

        return {
            "database": database,
            "status": "connected"
        }

except Exception:
    return {
        "status": "database connection failed"
    }, 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
