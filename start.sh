#!/bin/bash
# ============================================================
#  start.sh — Naukri Automation Startup Script
#  - Beautiful status page on port (keep-alive)
#  - Self-pinging every 14 minutes (no external tool needed)
#  - Automation runs every 6 hours
# ============================================================

echo "🚀 Starting Naukri Automation Service..."

# ---- Apply Render environment variables to config ----
apply_env_to_config() {
    local config="src/main/resources/config.properties"

    [ -n "$NAUKRI_USERNAME" ] && sed -i "s|naukri.username=.*|naukri.username=${NAUKRI_USERNAME}|" "$config"
    [ -n "$NAUKRI_PASSWORD" ] && sed -i "s|naukri.password=.*|naukri.password=${NAUKRI_PASSWORD}|" "$config"
    [ -n "$SEARCH_KEYWORDS" ] && sed -i "s|search.keywords=.*|search.keywords=${SEARCH_KEYWORDS}|" "$config"
    [ -n "$CANDIDATE_EXPERIENCE" ] && sed -i "s|candidate.experience=.*|candidate.experience=${CANDIDATE_EXPERIENCE}|" "$config"
    [ -n "$CANDIDATE_LOCATIONS" ] && sed -i "s|candidate.locations=.*|candidate.locations=${CANDIDATE_LOCATIONS}|" "$config"
    [ -n "$MAX_JOBS_TO_APPLY" ] && sed -i "s|max.jobs.to.apply=.*|max.jobs.to.apply=${MAX_JOBS_TO_APPLY}|" "$config"

    echo "✅ Config updated from environment variables."
}

apply_env_to_config

# ---- Python orchestrator ----
python3 - << 'PYEOF'
import http.server
import threading
import time
import subprocess
import logging
import urllib.request
import os
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger("naukri-svc")

PORT = int(os.environ.get("PORT", 8080))
RENDER_URL = os.environ.get("RENDER_EXTERNAL_URL", f"http://localhost:{PORT}")

# ── Shared state ──────────────────────────────────────────────
state = {
    "started_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC"),
    "runs_completed": 0,
    "last_run": "Not yet run",
    "next_run": "Starting soon...",
    "status": "Initializing",
}

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Naukri Automation</title>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;700;800&family=DM+Mono:wght@300;400&display=swap" rel="stylesheet"/>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg: #04050a;
    --surface: #0c0e17;
    --border: rgba(255,255,255,0.07);
    --green: #00ff9d;
    --green-dim: rgba(0,255,157,0.12);
    --green-glow: rgba(0,255,157,0.35);
    --text: #e8eaf0;
    --muted: #5a5f7a;
    --accent: #7b61ff;
  }

  html, body {
    min-height: 100vh;
    background: var(--bg);
    color: var(--text);
    font-family: 'DM Mono', monospace;
    overflow-x: hidden;
  }

  /* Animated grid background */
  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background-image:
      linear-gradient(rgba(0,255,157,0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,255,157,0.03) 1px, transparent 1px);
    background-size: 48px 48px;
    pointer-events: none;
    z-index: 0;
  }

  /* Glowing orb */
  body::after {
    content: '';
    position: fixed;
    top: -200px;
    left: 50%;
    transform: translateX(-50%);
    width: 700px;
    height: 700px;
    background: radial-gradient(circle, rgba(0,255,157,0.07) 0%, transparent 70%);
    pointer-events: none;
    z-index: 0;
    animation: pulse 6s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 0.6; transform: translateX(-50%) scale(1); }
    50% { opacity: 1; transform: translateX(-50%) scale(1.1); }
  }

  .wrap {
    position: relative;
    z-index: 1;
    max-width: 780px;
    margin: 0 auto;
    padding: 80px 24px 60px;
  }

  /* Header */
  .badge {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    border: 1px solid var(--green-glow);
    background: var(--green-dim);
    color: var(--green);
    font-size: 11px;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    padding: 6px 14px;
    border-radius: 100px;
    margin-bottom: 32px;
  }

  .dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--green);
    box-shadow: 0 0 8px var(--green);
    animation: blink 1.4s ease-in-out infinite;
  }

  @keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }

  h1 {
    font-family: 'Syne', sans-serif;
    font-size: clamp(38px, 7vw, 64px);
    font-weight: 800;
    line-height: 1.05;
    letter-spacing: -0.03em;
    margin-bottom: 16px;
    background: linear-gradient(135deg, #ffffff 0%, #a0a8c8 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  h1 span {
    background: linear-gradient(135deg, var(--green) 0%, #00c9ff 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .subtitle {
    color: var(--muted);
    font-size: 13px;
    letter-spacing: 0.04em;
    margin-bottom: 64px;
    line-height: 1.7;
  }

  /* Stats grid */
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
  }

  .card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 28px 24px;
    position: relative;
    overflow: hidden;
    transition: border-color 0.3s, transform 0.3s;
  }

  .card:hover {
    border-color: rgba(0,255,157,0.2);
    transform: translateY(-2px);
  }

  .card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 1px;
    background: linear-gradient(90deg, transparent, var(--green-glow), transparent);
    opacity: 0;
    transition: opacity 0.3s;
  }

  .card:hover::before { opacity: 1; }

  .card-label {
    font-size: 10px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 12px;
  }

  .card-value {
    font-family: 'Syne', sans-serif;
    font-size: 26px;
    font-weight: 700;
    color: var(--text);
    word-break: break-word;
  }

  .card-value.green { color: var(--green); }

  .card-value.small {
    font-family: 'DM Mono', monospace;
    font-size: 13px;
    font-weight: 400;
    color: #8892b0;
    margin-top: 4px;
  }

  /* Full-width card */
  .card-wide {
    grid-column: 1 / -1;
  }

  /* Timeline bar */
  .timeline {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 28px 24px;
    margin-bottom: 16px;
  }

  .timeline-label {
    font-size: 10px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--muted);
    margin-bottom: 20px;
  }

  .progress-track {
    height: 4px;
    background: rgba(255,255,255,0.05);
    border-radius: 100px;
    overflow: hidden;
    margin-bottom: 10px;
  }

  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, var(--green), #00c9ff);
    border-radius: 100px;
    width: {PROGRESS}%;
    box-shadow: 0 0 12px var(--green-glow);
    animation: shimmer 2s linear infinite;
    background-size: 200% 100%;
  }

  @keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }

  .progress-labels {
    display: flex;
    justify-content: space-between;
    font-size: 11px;
    color: var(--muted);
  }

  /* Footer */
  .footer {
    margin-top: 56px;
    padding-top: 24px;
    border-top: 1px solid var(--border);
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    font-size: 11px;
    color: var(--muted);
    letter-spacing: 0.05em;
  }

  .footer a {
    color: var(--green);
    text-decoration: none;
    opacity: 0.7;
    transition: opacity 0.2s;
  }

  .footer a:hover { opacity: 1; }

  @keyframes fadeUp {
    from { opacity: 0; transform: translateY(20px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  .wrap > * {
    animation: fadeUp 0.6s ease both;
  }

  .wrap > *:nth-child(1) { animation-delay: 0.05s; }
  .wrap > *:nth-child(2) { animation-delay: 0.12s; }
  .wrap > *:nth-child(3) { animation-delay: 0.18s; }
  .wrap > *:nth-child(4) { animation-delay: 0.24s; }
  .wrap > *:nth-child(5) { animation-delay: 0.30s; }
  .wrap > *:nth-child(6) { animation-delay: 0.36s; }
  .wrap > *:nth-child(7) { animation-delay: 0.42s; }
</style>
</head>
<body>
<div class="wrap">

  <div class="badge"><span class="dot"></span> System Operational</div>

  <h1>Naukri<br/><span>Auto Apply</span></h1>

  <p class="subtitle">
    Autonomous job application engine — running 24/7 on Render.<br/>
    Applies to 30+ tech roles across all major cities.
  </p>

  <div class="grid">
    <div class="card">
      <div class="card-label">Current Status</div>
      <div class="card-value green">{STATUS}</div>
    </div>
    <div class="card">
      <div class="card-label">Runs Completed</div>
      <div class="card-value">{RUNS}</div>
    </div>
    <div class="card">
      <div class="card-label">Last Run</div>
      <div class="card-value small">{LAST_RUN}</div>
    </div>
    <div class="card">
      <div class="card-label">Next Run</div>
      <div class="card-value small">{NEXT_RUN}</div>
    </div>
    <div class="card card-wide">
      <div class="card-label">Online Since</div>
      <div class="card-value small">{STARTED}</div>
    </div>
  </div>

  <div class="timeline">
    <div class="timeline-label">Next run progress</div>
    <div class="progress-track">
      <div class="progress-fill"></div>
    </div>
    <div class="progress-labels">
      <span>Last run</span>
      <span>Next run in 6 hrs</span>
    </div>
  </div>

  <div class="footer">
    <span>naukri-automation &mdash; automated via Selenium</span>
    <a href="https://github.com/aryanbarde80/naukri-automation" target="_blank">github →</a>
  </div>

</div>
</body>
</html>"""

# ── Keep-alive HTTP Server ────────────────────────────────────
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        progress = min(int((time.time() % (6*3600)) / (6*3600) * 100), 100)
        html = HTML_PAGE\
            .replace("{STATUS}", state["status"])\
            .replace("{RUNS}", str(state["runs_completed"]))\
            .replace("{LAST_RUN}", state["last_run"])\
            .replace("{NEXT_RUN}", state["next_run"])\
            .replace("{STARTED}", state["started_at"])\
            .replace("{PROGRESS}", str(progress))
        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass

def run_server():
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    log.info(f"Status page live on port {PORT}")
    server.serve_forever()

# ── Self-Ping every 14 minutes ────────────────────────────────
def self_ping():
    while True:
        time.sleep(14 * 60)
        try:
            urllib.request.urlopen(RENDER_URL, timeout=10)
            log.info(f"Self-ping OK → {RENDER_URL}")
        except Exception as e:
            log.warning(f"Self-ping failed (non-critical): {e}")

# ── Run Automation ────────────────────────────────────────────
def run_automation():
    state["status"] = "Running"
    log.info("=" * 60)
    log.info("Starting Naukri automation run...")
    log.info("=" * 60)
    try:
        result = subprocess.run(
            ["mvn", "exec:java",
             "-Dexec.mainClass=com.naukri.automation.runner.TestRunner",
             "-q"],
            capture_output=False
        )
        now = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
        state["runs_completed"] += 1
        state["last_run"] = now
        if result.returncode == 0:
            log.info("✅ Automation run completed successfully.")
            state["status"] = "Idle"
        else:
            log.error(f"❌ Automation exited with code: {result.returncode}")
            state["status"] = "Error"
    except Exception as e:
        log.error(f"💥 Automation exception: {e}")
        state["status"] = "Error"

# ── Scheduler: runs automation every 6 hours ─────────────────
def scheduler():
    INTERVAL = 6 * 60 * 60
    while True:
        run_automation()
        next_time = datetime.utcnow()
        from datetime import timedelta
        next_time = (datetime.utcnow() + timedelta(seconds=INTERVAL)).strftime("%Y-%m-%d %H:%M UTC")
        state["next_run"] = next_time
        log.info("⏰ Next automation run in 6 hours...")
        time.sleep(INTERVAL)

# ── Start all threads ─────────────────────────────────────────
threads = [
    threading.Thread(target=run_server,  daemon=True,  name="http-server"),
    threading.Thread(target=self_ping,   daemon=True,  name="self-pinger"),
    threading.Thread(target=scheduler,   daemon=False, name="scheduler"),
]

for t in threads:
    t.start()
    log.info(f"Thread started: {t.name}")

for t in threads:
    if not t.daemon:
        t.join()
PYEOF
