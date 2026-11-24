import json, os, socket, ssl, time, urllib.request
from html import escape
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.getenv("STATUS_PORT", "8081"))
INTERVAL_H = int(os.getenv("BACKUP_INTERVAL_HOURS", "24"))
LAST_BACKUP = "/backups/last_backup.json"
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
    req = urllib.request.Request(
        "http://backend:8000/api/health/",
        headers={"Host": "127.0.0.1"},   # permitido no ALLOWED_HOSTS
    )
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
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
    rows = "".join(
        f'<tr><td>{escape(k)}</td>'
        f'<td><span class="pill {"ok" if v["ok"] else "bad"}">'
        f'{"● Operacional" if v["ok"] else "● Falha"}</span>'
        f'<small class="detail">{escape(v["detail"])}</small></td>'
        f'<td><code>{escape(v["conn"])}</code></td></tr>'
        for k, v in data.items()
    )
    banner = "Todos os sistemas operacionais" if allok else "Há serviços com problemas"
    cls = "ok" if allok else "bad"
    return f"""<!doctype html><html lang="pt"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="15">
<title>Health check status page system — GeoGuess Angola</title>
<style>
:root{{
  --color-black:#080808;
  --color-dark-red:#250609;
  --color-crimson:#650D19;
  --color-white:#FFFFFF;
  --color-gold:#FFC629;
  color-scheme:dark;
}}
*{{box-sizing:border-box}}
body{{
  margin:0;min-height:100vh;
  font-family:system-ui,sans-serif;color:var(--color-white);
  background:linear-gradient(135deg,var(--color-black) 0%,var(--color-dark-red) 55%,var(--color-black) 100%);
}}
main{{max-width:760px;margin:0 auto;padding:2rem 1rem}}
h1{{font-size:1.4rem;margin:0 0 1rem;color:var(--color-gold)}}
.banner{{padding:.9rem 1.1rem;border-radius:10px;font-weight:600;margin:1rem 0 1.5rem}}
.banner.ok{{background:var(--color-crimson);color:var(--color-white)}}
.banner.bad{{background:var(--color-gold);color:var(--color-black)}}
.table-wrap{{overflow-x:auto;border:1px solid rgba(255,198,41,.25);border-radius:10px;background:rgba(255,255,255,.04)}}
table{{width:100%;border-collapse:collapse}}
th,td{{padding:.7rem .9rem;text-align:left;vertical-align:top}}
thead th{{color:var(--color-gold);font-size:.78rem;text-transform:uppercase;letter-spacing:.06em;border-bottom:1px solid var(--color-gold)}}
tbody td{{border-bottom:1px solid rgba(255,255,255,.1)}}
tbody tr:last-child td{{border-bottom:0}}
.pill{{display:inline-block;padding:.15rem .6rem;border-radius:999px;font-size:.85rem;font-weight:600;white-space:nowrap}}
.pill.ok{{color:var(--color-gold);border:1px solid var(--color-gold)}}
.pill.bad{{color:var(--color-white);background:var(--color-crimson);border:1px solid var(--color-white)}}
.detail{{display:block;margin-top:.25rem;opacity:.65;font-size:.78rem}}
code{{color:var(--color-gold);font-size:.85rem}}
footer{{margin-top:1rem;opacity:.6;font-size:.8rem}}
</style></head><body><main>
<h1>GeoGuess Angola — Estado</h1>
<div class="banner {cls}">{banner}</div>
<div class="table-wrap"><table>
<thead><tr><th scope="col">Serviço</th><th scope="col">Estado</th><th scope="col">Tipo de conexão</th></tr></thead>
<tbody>{rows}</tbody>
</table></div>
<footer>Atualiza a cada 15 s · {time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())}</footer>
</main></body></html>""".encode()

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