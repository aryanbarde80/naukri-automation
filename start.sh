#!/bin/bash
# ============================================================
#  start.sh - Startup script for Render deployment
#  1. Starts a tiny HTTP server (keeps Render web service alive)
#  2. Runs Naukri automation on a schedule
# ============================================================

echo "🚀 Starting Naukri Automation Service..."

# Apply env vars to config.properties if provided (Render env vars override)
if [ -n "$NAUKRI_USERNAME" ] && [ -n "$NAUKRI_PASSWORD" ]; then
    echo "📝 Applying credentials from environment variables..."
    sed -i "s/naukri.username=.*/naukri.username=${NAUKRI_USERNAME}/" src/main/resources/config.properties
    sed -i "s/naukri.password=.*/naukri.password=${NAUKRI_PASSWORD}/" src/main/resources/config.properties
fi

if [ -n "$SEARCH_KEYWORDS" ]; then
    sed -i "s/search.keywords=.*/search.keywords=${SEARCH_KEYWORDS}/" src/main/resources/config.properties
fi

if [ -n "$CANDIDATE_EXPERIENCE" ]; then
    sed -i "s/candidate.experience=.*/candidate.experience=${CANDIDATE_EXPERIENCE}/" src/main/resources/config.properties
fi

if [ -n "$CANDIDATE_LOCATIONS" ]; then
    sed -i "s/candidate.locations=.*/candidate.locations=${CANDIDATE_LOCATIONS}/" src/main/resources/config.properties
fi

if [ -n "$MAX_JOBS_TO_APPLY" ]; then
    sed -i "s/max.jobs.to.apply=.*/max.jobs.to.apply=${MAX_JOBS_TO_APPLY}/" src/main/resources/config.properties
fi

# ---- Keep-alive HTTP server (Python) ----
# Render requires a web server to keep the service running
python3 -c "
import http.server, threading, time, subprocess, logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s')

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Naukri Automation is running!')
    def log_message(self, format, *args):
        pass  # suppress access logs

def run_server():
    server = http.server.HTTPServer(('0.0.0.0', 8080), Handler)
    logging.info('Keep-alive server started on port 8080')
    server.serve_forever()

def run_automation():
    logging.info('Starting first automation run...')
    try:
        result = subprocess.run(
            ['mvn', 'exec:java', '-Dexec.mainClass=com.naukri.automation.runner.TestRunner', '-q'],
            capture_output=False
        )
        if result.returncode == 0:
            logging.info('Automation run completed successfully.')
        else:
            logging.error('Automation run exited with code: ' + str(result.returncode))
    except Exception as e:
        logging.error('Automation error: ' + str(e))

# Start keep-alive server in background
t = threading.Thread(target=run_server, daemon=True)
t.start()

# Schedule: Run automation every 6 hours (21600 seconds)
INTERVAL_SECONDS = 6 * 60 * 60

while True:
    run_automation()
    logging.info(f'Next run in {INTERVAL_SECONDS // 3600} hours...')
    time.sleep(INTERVAL_SECONDS)
"
