# 🤖 Naukri Job Application Automation

Automatically applies to jobs on Naukri.com based on your search preferences. Runs 24/7 on Render.com.

---

## 🚀 Deploy on Render (3 Steps)

### Step 1 — Fork/Push this repo
Make sure this repo is pushed to your GitHub account.

### Step 2 — Create a new Web Service on Render
1. Go to [render.com](https://render.com) → **New** → **Web Service**
2. Connect your GitHub account and select this repo
3. Render will auto-detect `render.yaml` → click **Deploy**

### Step 3 — Set Environment Variables
In Render Dashboard → your service → **Environment** tab, set:

| Variable | Value |
|---|---|
| `NAUKRI_USERNAME` | your_email@naukri.com |
| `NAUKRI_PASSWORD` | your_password |
| `SEARCH_KEYWORDS` | SDET, QA Automation Engineer |
| `CANDIDATE_EXPERIENCE` | 4 |
| `CANDIDATE_LOCATIONS` | Indore, Pune, Noida |
| `MAX_JOBS_TO_APPLY` | 20 |

Click **Save Changes** → Render will redeploy with your credentials. Done! ✅

---

## ⏰ Schedule
- Automation runs every **6 hours**
- A keep-alive server runs on port 8080 to prevent Render from sleeping

## 🔒 Keep-Alive (14-min ping)
To prevent the free-tier service from sleeping, set up an **external ping**:
1. Go to [cron-job.org](https://cron-job.org) (free)
2. Create a new cron job with your Render URL (e.g. `https://naukri-automation.onrender.com/`)
3. Set interval to **every 14 minutes**

---

## 📁 Project Structure
```
├── Dockerfile              # Docker build for Render
├── render.yaml             # Render deployment config
├── start.sh                # Startup: keep-alive server + scheduler
├── pom.xml                 # Maven dependencies
└── src/main/
    ├── java/               # Selenium automation code
    └── resources/
        └── config.properties  # Settings (override via env vars)
```

## ⚙️ Configuration
All settings can be changed via Render environment variables — no code change needed.
