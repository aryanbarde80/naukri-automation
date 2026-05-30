#!/bin/bash
# ============================================================
#  start.sh - Naukri Automation Startup Script
#  - Premium status page on root URL
#  - Self-pinging every 14 minutes (built-in, no external tool)
#  - Automation runs every 6 hours
# ============================================================

echo "Starting Naukri Automation Service..."

apply_env_to_config() {
    local config="src/main/resources/config.properties"
    [ -n "$NAUKRI_USERNAME" ]        && sed -i "s|naukri.username=.*|naukri.username=${NAUKRI_USERNAME}|" "$config"
    [ -n "$NAUKRI_PASSWORD" ]        && sed -i "s|naukri.password=.*|naukri.password=${NAUKRI_PASSWORD}|" "$config"
    [ -n "$SEARCH_KEYWORDS" ]        && sed -i "s|search.keywords=.*|search.keywords=${SEARCH_KEYWORDS}|" "$config"
    [ -n "$CANDIDATE_EXPERIENCE" ]   && sed -i "s|candidate.experience=.*|candidate.experience=${CANDIDATE_EXPERIENCE}|" "$config"
    [ -n "$CANDIDATE_LOCATIONS" ]    && sed -i "s|candidate.locations=.*|candidate.locations=${CANDIDATE_LOCATIONS}|" "$config"
    [ -n "$MAX_JOBS_TO_APPLY" ]      && sed -i "s|max.jobs.to.apply=.*|max.jobs.to.apply=${MAX_JOBS_TO_APPLY}|" "$config"
    echo "Config updated from environment variables."
}

apply_env_to_config

python3 - << 'PYEOF'
import http.server, threading, time, subprocess, logging, urllib.request, os
from datetime import datetime, timezone, timedelta

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
log = logging.getLogger("naukri-svc")

PORT = int(os.environ.get("PORT", 8080))
RENDER_URL = os.environ.get("RENDER_EXTERNAL_URL", f"http://localhost:{PORT}")
CYCLE_SECONDS = 6 * 3600

state = {
    "started_at": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
    "runs_completed": 0,
    "last_run": "Not yet run",
    "next_run": "Starting soon...",
    "status": "Running",
}

HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Naukri Auto Apply</title>
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300;400;500;600;700&family=JetBrains+Mono:wght@300;400;500&display=swap" rel="stylesheet"/>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css"/>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--green:#4dffaa;--green-dim:rgba(77,255,170,0.08);--green-glow:rgba(77,255,170,0.2);--bg:#060608;--surface:rgba(255,255,255,0.025);--border:rgba(255,255,255,0.05);--text:rgba(255,255,255,0.85);--muted:rgba(255,255,255,0.25)}
html,body{min-height:100vh;background:var(--bg);color:var(--text);font-family:'Space Grotesk',sans-serif;overflow-x:hidden}
body::before{content:'';position:fixed;inset:0;background-image:url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.04'/%3E%3C/svg%3E");opacity:.4;pointer-events:none;z-index:0}
.orb1{position:fixed;top:-300px;left:-200px;width:900px;height:900px;background:conic-gradient(from 180deg at 50% 50%,#0d1f3c 0deg,#0a2e1a 90deg,#1a0d2e 180deg,#0d1f3c 360deg);border-radius:50%;opacity:.5;animation:drift1 20s ease-in-out infinite alternate;pointer-events:none;z-index:0}
.orb2{position:fixed;bottom:-200px;right:-150px;width:600px;height:600px;background:radial-gradient(circle,rgba(20,60,30,.4) 0%,transparent 70%);animation:drift2 15s ease-in-out infinite alternate;pointer-events:none;z-index:0}
@keyframes drift1{0%{transform:translate(0,0) rotate(0deg)}100%{transform:translate(80px,60px) rotate(30deg)}}
@keyframes drift2{0%{transform:translate(0,0)}100%{transform:translate(-60px,-40px)}}
.wrap{position:relative;z-index:1;max-width:720px;margin:0 auto;padding:56px 24px 72px}
.eyebrow{display:flex;align-items:center;gap:12px;margin-bottom:44px}
.pill{display:inline-flex;align-items:center;gap:7px;background:var(--green-dim);border:1px solid var(--green-glow);border-radius:100px;padding:5px 14px;font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--green);letter-spacing:.05em}
.pulse{width:6px;height:6px;border-radius:50%;background:var(--green);animation:blink 1.6s ease-in-out infinite}
@keyframes blink{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.3;transform:scale(.7)}}
.divider{flex:1;height:1px;background:linear-gradient(90deg,var(--border),transparent)}
.clock{font-family:'JetBrains Mono',monospace;font-size:11px;color:rgba(255,255,255,.18)}
.hero{margin-bottom:56px}
.tag{font-family:'JetBrains Mono',monospace;font-size:11px;color:var(--muted);letter-spacing:.12em;margin-bottom:16px}
h1{font-size:clamp(48px,9vw,72px);font-weight:700;line-height:.92;letter-spacing:-.04em;color:#fff;margin-bottom:20px}
.accent{display:block;background:linear-gradient(90deg,#4dffaa,#00cfff,#a78bfa,#4dffaa);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;background-size:300%;animation:hue 8s linear infinite}
@keyframes hue{0%{background-position:0%}100%{background-position:300%}}
.desc{font-size:15px;color:rgba(255,255,255,.35);line-height:1.65;font-weight:300;max-width:500px}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:1px;background:var(--border);border-radius:16px;overflow:hidden;border:1px solid var(--border);margin-bottom:16px}
.stat{background:var(--surface);padding:28px 24px;transition:background .2s}
.stat:hover{background:rgba(255,255,255,.04)}
.stat-label{font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--muted);letter-spacing:.12em;text-transform:uppercase;margin-bottom:12px}
.stat-val{font-size:34px;font-weight:600;color:#fff;line-height:1}
.stat-val.green{color:var(--green);font-size:18px;letter-spacing:-.01em}
.bars{display:flex;align-items:flex-end;gap:4px;height:24px;margin-top:10px}
.bar{width:4px;border-radius:2px;background:var(--green);opacity:.7}
.bar:nth-child(1){height:16px;animation:wave 1.2s .0s ease-in-out infinite}
.bar:nth-child(2){height:10px;animation:wave 1.2s .1s ease-in-out infinite}
.bar:nth-child(3){height:20px;animation:wave 1.2s .2s ease-in-out infinite}
.bar:nth-child(4){height:12px;animation:wave 1.2s .3s ease-in-out infinite}
.bar:nth-child(5){height:18px;animation:wave 1.2s .4s ease-in-out infinite}
.bar:nth-child(6){height:8px;animation:wave 1.2s .5s ease-in-out infinite}
.bar:nth-child(7){height:22px;animation:wave 1.2s .6s ease-in-out infinite}
.bar:nth-child(8){height:14px;animation:wave 1.2s .7s ease-in-out infinite}
@keyframes wave{0%,100%{transform:scaleY(1);opacity:.7}50%{transform:scaleY(.35);opacity:.25}}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:16px}
.card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:26px 24px;transition:border-color .25s}
.card:hover{border-color:rgba(255,255,255,.1)}
.card-label{font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--muted);letter-spacing:.12em;text-transform:uppercase;margin-bottom:12px}
.card-val{font-family:'JetBrains Mono',monospace;font-size:13px;color:rgba(255,255,255,.5);line-height:1.6}
.prog-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:26px 24px;margin-bottom:16px}
.prog-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:18px}
.prog-title{font-family:'JetBrains Mono',monospace;font-size:10px;color:var(--muted);letter-spacing:.12em;text-transform:uppercase}
.prog-pct{font-family:'JetBrains Mono',monospace;font-size:12px;color:var(--green)}
.track{height:3px;background:rgba(255,255,255,.06);border-radius:100px;overflow:hidden;margin-bottom:12px}
.fill{height:100%;border-radius:100px;background:linear-gradient(90deg,#4dffaa,#00cfff);transition:width 1s ease}
.ticks{display:flex;justify-content:space-between;font-family:'JetBrains Mono',monospace;font-size:10px;color:rgba(255,255,255,.15)}
.roles-card{background:var(--surface);border:1px solid var(--border);border-radius:16px;padding:26px 24px;margin-bottom:16px}
.tags{display:flex;flex-wrap:wrap;gap:8px;margin-top:16px}
.tag-chip{background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.07);border-radius:6px;padding:5px 11px;font-size:11px;color:rgba(255,255,255,.4);font-family:'JetBrains Mono',monospace;cursor:default;transition:all .2s}
.tag-chip:hover{background:rgba(77,255,170,.07);border-color:rgba(77,255,170,.2);color:var(--green)}
footer{display:flex;justify-content:space-between;align-items:center;padding-top:24px;border-top:1px solid var(--border)}
.foot-l{font-family:'JetBrains Mono',monospace;font-size:11px;color:rgba(255,255,255,.15)}
.foot-r{display:flex;align-items:center;gap:6px;font-family:'JetBrains Mono',monospace;font-size:11px;color:rgba(77,255,170,.5);text-decoration:none;transition:color .2s}
.foot-r:hover{color:var(--green)}
</style>
</head>
<body>
<div class="orb1"></div>
<div class="orb2"></div>
<div class="wrap">

  <div class="eyebrow">
    <div class="pill"><span class="pulse"></span>all systems operational</div>
    <div class="divider"></div>
    <div class="clock" id="clk">--:--:-- UTC</div>
  </div>

  <div class="hero">
    <div class="tag">// AUTONOMOUS JOB ENGINE v1.0</div>
    <h1>Naukri<span class="accent">Auto Apply</span></h1>
    <p class="desc">Selenium-powered automation running 24/7 on Render — applying to 30+ tech roles across India's top cities, every 6 hours, without interruption.</p>
  </div>

  <div class="stats">
    <div class="stat">
      <div class="stat-label">Status</div>
      <div class="stat-val green">__STATUS__</div>
      <div class="bars">
        <div class="bar"></div><div class="bar"></div><div class="bar"></div><div class="bar"></div>
        <div class="bar"></div><div class="bar"></div><div class="bar"></div><div class="bar"></div>
      </div>
    </div>
    <div class="stat">
      <div class="stat-label">Runs completed</div>
      <div class="stat-val">__RUNS__</div>
    </div>
    <div class="stat">
      <div class="stat-label">Roles tracked</div>
      <div class="stat-val">30<span style="font-size:18px;color:rgba(255,255,255,.3)">+</span></div>
    </div>
  </div>

  <div class="row2">
    <div class="card">
      <div class="card-label">Last run</div>
      <div class="card-val">__LAST_RUN__</div>
    </div>
    <div class="card">
      <div class="card-label">Next run</div>
      <div class="card-val">__NEXT_RUN__</div>
    </div>
  </div>

  <div class="card" style="margin-bottom:16px">
    <div class="card-label">Online since</div>
    <div class="card-val">__STARTED__</div>
  </div>

  <div class="prog-card">
    <div class="prog-header">
      <span class="prog-title">6-hour cycle progress</span>
      <span class="prog-pct">__PCT__%</span>
    </div>
    <div class="track"><div class="fill" style="width:__PCT__%"></div></div>
    <div class="ticks"><span>last run</span><span>+2h</span><span>+4h</span><span>next run</span></div>
  </div>

  <div class="roles-card">
    <div class="card-label">Covered roles</div>
    <div class="tags">
      <span class="tag-chip">SDE</span><span class="tag-chip">SDE-1</span><span class="tag-chip">SDE-2</span>
      <span class="tag-chip">Software Engineer</span><span class="tag-chip">Backend Engineer</span>
      <span class="tag-chip">Full Stack Developer</span><span class="tag-chip">Frontend Developer</span>
      <span class="tag-chip">AI Engineer</span><span class="tag-chip">ML Engineer</span>
      <span class="tag-chip">AIML Engineer</span><span class="tag-chip">Machine Learning</span>
      <span class="tag-chip">Data Scientist</span><span class="tag-chip">Data Engineer</span>
      <span class="tag-chip">MLOps Engineer</span><span class="tag-chip">LLM Engineer</span>
      <span class="tag-chip">GenAI Engineer</span><span class="tag-chip">NLP Engineer</span>
      <span class="tag-chip">Computer Vision</span><span class="tag-chip">Deep Learning</span>
      <span class="tag-chip">SDET</span><span class="tag-chip">QA Automation</span>
      <span class="tag-chip">DevOps Engineer</span><span class="tag-chip">SRE</span>
      <span class="tag-chip">Cloud Engineer</span><span class="tag-chip">Java Developer</span>
      <span class="tag-chip">Python Developer</span><span class="tag-chip">Node.js Developer</span>
      <span class="tag-chip">React Developer</span><span class="tag-chip">Spring Boot</span>
      <span class="tag-chip">Microservices</span>
    </div>
  </div>

  <footer>
    <div class="foot-l">naukri-automation &middot; selenium &middot; render</div>
    <a class="foot-r" href="https://github.com/aryanbarde80/naukri-automation" target="_blank">
      <i class="ti ti-brand-github" style="font-size:14px"></i> github
    </a>
  </footer>

</div>
<script>
function pad(n){return String(n).padStart(2,'0')}
function tick(){
  const now=new Date();
  document.getElementById('clk').textContent=pad(now.getUTCHours())+':'+pad(now.getUTCMinutes())+':'+pad(now.getUTCSeconds())+' UTC';
}
tick(); setInterval(tick,1000);
</script>
</body>
</html>"""

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        elapsed = (datetime.now(timezone.utc) - datetime.now(timezone.utc).replace(hour=0,minute=0,second=0,microsecond=0)).seconds
        pct = min(int((elapsed % CYCLE_SECONDS) / CYCLE_SECONDS * 100), 100)
        html = HTML\
            .replace("__STATUS__", state["status"])\
            .replace("__RUNS__", str(state["runs_completed"]))\
            .replace("__LAST_RUN__", state["last_run"])\
            .replace("__NEXT_RUN__", state["next_run"])\
            .replace("__STARTED__", state["started_at"])\
            .replace("__PCT__", str(pct))
        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, *args): pass

def run_server():
    server = http.server.HTTPServer(("0.0.0.0", PORT), Handler)
    log.info(f"Status page live on port {PORT}")
    server.serve_forever()

def self_ping():
    while True:
        time.sleep(14 * 60)
        try:
            urllib.request.urlopen(RENDER_URL, timeout=10)
            log.info(f"Self-ping OK -> {RENDER_URL}")
        except Exception as e:
            log.warning(f"Self-ping failed (non-critical): {e}")

def run_automation():
    state["status"] = "Running"
    log.info("=" * 60)
    log.info("Starting Naukri automation run...")
    log.info("=" * 60)
    try:
        result = subprocess.run(
            ["mvn", "exec:java", "-Dexec.mainClass=com.naukri.automation.runner.TestRunner", "-q"],
            capture_output=False
        )
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        state["runs_completed"] += 1
        state["last_run"] = now
        state["status"] = "Idle" if result.returncode == 0 else "Error"
        next_dt = datetime.now(timezone.utc) + timedelta(seconds=CYCLE_SECONDS)
        state["next_run"] = next_dt.strftime("%Y-%m-%d %H:%M UTC")
        log.info(f"Run completed. Status: {state['status']}")
    except Exception as e:
        log.error(f"Automation error: {e}")
        state["status"] = "Error"

def scheduler():
    while True:
        run_automation()
        log.info(f"Next run in 6 hours...")
        time.sleep(CYCLE_SECONDS)

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
