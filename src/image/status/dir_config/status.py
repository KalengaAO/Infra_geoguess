import json, os ,socket ,ssl ,time, urllib.request
from html import escape
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from string import Template

PORT = int(os.getenv("STATUS_PORT", "8081"))
INTERVAL_H = int(os.getenv("BACKUP_INTERVAL_HOURS", "24"))
LAST_BACKUP = "/backups/last_backup.json"

# Lido uma vez no arranque: se faltar, o serviço falha logo e à vista
TEMPLATE = Template(
    (Path(__file__).parent / "status.html").read_text(encoding="utf-8")
)

CONN = {
    "Nginx (HTTPS)": "HTTPS",
    "Backend (Django)": "HTTP · /api/health/",
    "Frontend (Vite)": "HTTP",
    "PostgreSQL": "TCP · 5432",
    "Redis": "TCP · PING/PONG",
    "Adminer": "HTTP",
    "Backups": "Ficheiro · last_backup.json",
}


def tcp(host, port):
    try:
        with socket.create_connection((host, port), timeout=2):
            return True, "porta aberta"
    except OSError as e:
        return False, str(e)


def http(url, verify=True):
    ctx = None if verify else ssl._create_unverified_context()
    try:
        with urllib.request.urlopen(url, timeout=3, context=ctx) as r:
            return r.status < 400, f"HTTP {r.status}"
    except Exception as e:
        return False, str(e)[:120]


def redis():
    try:
        with socket.create_connection(("redis", 6379), timeout=2) as s:
            s.sendall(b"PING\r\n")
            return s.recv(16).startswith(b"+PONG"), "PONG"
    except OSError as e:
        return False, str(e)


def backend():
    try:
        with urllib.request.urlopen("http://backend:8000/api/health/", timeout=3) as r:
            return r.status == 200, json.loads(r.read()).get("status", "ok")
    except Exception as e:
        return False, str(e)[:120]


def backup():
    try:
        with open(LAST_BACKUP) as f:
            d = json.load(f)
        age_h = (time.time() - d["epoch"]) / 3600
        ok = d["status"] == "ok" and age_h < INTERVAL_H * 2
        return ok, f'{d["status"]}, há {age_h:.1f} h, {d.get("file", "-")}'
    except Exception:
        return False, "sem backups registados"


def collect():
    checks = {
        "Nginx (HTTPS)": http("https://nginx/nginx-health", verify=False),
        "Backend (Django)": backend(),
        "Frontend (Vite)": http("http://frontend:5173/"),
        "PostgreSQL": tcp("postgres", 5432),
        "Redis": redis(),
        "Adminer": http("http://adminer:8080/"),
        "Backups": backup(),
    }
    return {
        k: {"ok": ok, "detail": d, "conn": CONN[k]}
        for k, (ok, d) in checks.items()
    }


def render(data):
    allok = all(v["ok"] for v in data.values())
    rows = "\n".join(
        f'        <tr><td>{escape(k)}</td>'
        f'<td><span class="pill {"ok" if v["ok"] else "bad"}">'
        f'{"● Operacional" if v["ok"] else "● Falha"}</span>'
        f'<small class="detail">{escape(v["detail"])}</small></td>'
        f'<td><code>{escape(v["conn"])}</code></td></tr>'
        for k, v in data.items()
    )
    return TEMPLATE.substitute(
        banner_class="ok" if allok else "bad",
        banner="Todos os sistemas operacionais" if allok else "Há serviços com problemas",
        rows=rows,
        updated=time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    ).encode("utf-8")


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            return self._send(200, b"ok", "text/plain")
        data = collect()
        if self.path == "/json":
            code = 200 if all(v["ok"] for v in data.values()) else 503
            return self._send(code, json.dumps(data).encode(), "application/json")
        self._send(200, render(data), "text/html; charset=utf-8")

    def _send(self, code, body, ctype):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()