#!/bin/bash
# ============================================================
#  start.sh — Naukri Automation Startup Script
#  - Keep-alive HTTP server on port 8080
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

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger("naukri-svc")

PORT = int(os.environ.get("PORT", 8080))
RENDER_URL = os.environ.get("RENDER_EXTERNAL_URL", f"http://localhost:{PORT}")

# ── Keep-alive HTTP Server ────────────────────────────────────
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"Naukri Automation is alive and running!")
    def log_message(self, *args):
        pass  # silence request logs

def run_server():
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    log.info(f"Keep-alive server started on port {PORT}")
    server.serve_forever()

# ── Self-Ping every 14 minutes (prevents Render free-tier sleep) ──
def self_ping():
    while True:
        time.sleep(14 * 60)  # 14 minutes
        try:
            urllib.request.urlopen(RENDER_URL, timeout=10)
            log.info(f"Self-ping OK → {RENDER_URL}")
        except Exception as e:
            log.warning(f"Self-ping failed (non-critical): {e}")

# ── Run Automation ────────────────────────────────────────────
def run_automation():
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
        if result.returncode == 0:
            log.info("✅ Automation run completed successfully.")
        else:
            log.error(f"❌ Automation exited with code: {result.returncode}")
    except Exception as e:
        log.error(f"💥 Automation exception: {e}")

# ── Scheduler: runs automation every 6 hours ─────────────────
def scheduler():
    INTERVAL = 6 * 60 * 60  # 6 hours in seconds
    while True:
        run_automation()
        log.info(f"⏰ Next automation run in 6 hours...")
        time.sleep(INTERVAL)

# ── Start all threads ─────────────────────────────────────────
threads = [
    threading.Thread(target=run_server,   daemon=True, name="http-server"),
    threading.Thread(target=self_ping,    daemon=True, name="self-pinger"),
    threading.Thread(target=scheduler,    daemon=False, name="scheduler"),
]

for t in threads:
    t.start()
    log.info(f"Thread started: {t.name}")

# Keep main thread alive
for t in threads:
    if not t.daemon:
        t.join()
PYEOF
