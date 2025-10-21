Simple Flask one-page app

Run locally

Windows (PowerShell)

```powershell
cd apps
# create virtual env
py -m venv .venv
# activate
.\.venv\Scripts\Activate.ps1
# (if activation is blocked) run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
# upgrade pip and install
py -m pip install --upgrade pip
py -m pip install -r requirements.txt
# run the app
py app.py
```

Linux / macOS (bash)

```bash
cd apps
# create virtual env
python3 -m venv .venv
# activate
source .venv/bin/activate
# upgrade pip and install
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
# run the app
python app.py
```

Then open http://localhost:8080 in your browser. The page shows the current time in Belgrade and the app version from `version.txt`.

Notes
- The commands use `py` on Windows and `python3`/`python` on Linux/macOS — adjust if your environment differs.
- If port 8080 is blocked on your system, change the port in `app.py` or run with the Flask CLI:
	- PowerShell: `$env:FLASK_APP='app.py'; py -m flask run --host=0.0.0.0 --port=8080`
	- Bash: `FLASK_APP=app.py python -m flask run --host=0.0.0.0 --port=8080`
