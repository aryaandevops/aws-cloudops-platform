from flask import Flask
import socket

app = Flask(__name__)


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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
