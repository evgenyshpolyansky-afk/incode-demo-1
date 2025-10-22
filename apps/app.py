from flask import Flask, render_template_string, jsonify, Response
from datetime import datetime
import pytz
import os
import socket

app = Flask(__name__)

VERSION_FILE = "version.txt"

TEMPLATE = """
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Incode Demo - Time</title>
    <style>
      body { font-family: Arial, sans-serif; padding: 2rem; }
      .card { padding: 1rem; border: 1px solid #eee; border-radius: 6px; max-width: 480px }
      .muted { color: #666; font-size: 0.9rem }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Current time in Beograd</h1>
      <p><strong>{{ time }}</strong></p>
      <p class="muted">App version: {{ version }}</p>
    </div>
  </body>
</html>
"""


def read_version():
    try:
        with open(VERSION_FILE, "r", encoding="utf-8") as f:
            return f.read().strip()
    except Exception:
        return "unknown"


@app.route("/liveness")
def liveness():
  """Liveness — frontend-only page."""
  tz = pytz.timezone("Europe/Belgrade")
  now = datetime.now(tz)
  timestr = now.strftime("%Y-%m-%d %H:%M:%S %Z")
  version = read_version()
  return render_template_string(TEMPLATE, time=timestr, version=version)


def check_tcp_connect(host: str, port: int, timeout: float = 2.0) -> bool:
  try:
    with socket.create_connection((host, port), timeout=timeout):
      return True
  except Exception:
    return False


@app.route("/readiness")
def readiness():
  """Readiness endpoint — checks DB endpoint reachability.

  Expects the following environment variables:
    - DB_ENDPOINT (host or host:port)
    - DB_USERNAME (unused for plain TCP check)
    - DB_PASSWORD (unused for plain TCP check)
  """
  db_endpoint = os.getenv("DB_ENDPOINT", "")
  if not db_endpoint:
    return Response("DB_ENDPOINT not set", status=503)

  # allow DB_ENDPOINT to contain :port
  if ":" in db_endpoint:
    host, port_str = db_endpoint.rsplit(":", 1)
    try:
      port = int(port_str)
    except ValueError:
      port = 3306
  else:
    host = db_endpoint
    port = 3306

  ok = check_tcp_connect(host, port)
  if not ok:
    return Response(f"DB not reachable: {db_endpoint}", status=503)

  return jsonify({"status": "ready", "db_endpoint": db_endpoint})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
