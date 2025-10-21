from flask import Flask, render_template_string
from datetime import datetime
import pytz

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


@app.route("/")
def index():
    tz = pytz.timezone("Europe/Belgrade")
    now = datetime.now(tz)
    timestr = now.strftime("%Y-%m-%d %H:%M:%S %Z")
    version = read_version()
    return render_template_string(TEMPLATE, time=timestr, version=version)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
