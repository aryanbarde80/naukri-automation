# 🤖 Naukri Job Application Automation

Automatically applies to jobs on Naukri.com 24/7. Runs on Render.com for free.

---

## 🚀 Deploy in 3 Steps

### Step 1 — Create a Web Service on Render
1. Go to [render.com](https://render.com) → **New** → **Web Service**
2. Connect your GitHub account → select `aryanbarde80/naukri-automation`
3. Render will auto-detect `render.yaml` → click **Deploy**

### Step 2 — Set 2 Environment Variables
Render Dashboard → your service → **Environment** tab:

| Variable | Value |
|---|---|
| `NAUKRI_USERNAME` | Your Naukri login email |
| `NAUKRI_PASSWORD` | Your Naukri password |

Click **Save Changes** → service will redeploy automatically. Done ✅

### Step 3 — Nothing Else
Everything else is pre-configured. The server pings itself every 14 minutes to stay alive. No external tools needed.

---

## ⚙️ Default Configuration

| Setting | Value |
|---|---|
| **Jobs per run** | Unlimited |
| **Automation schedule** | Every 6 hours |
| **Keep-alive ping** | Every 14 minutes (built-in) |
| **Browser mode** | Headless |
| **Locations** | Indore, Pune, Noida, Bangalore, Hyderabad, Mumbai, Remote |
| **Experience** | 4 years |

---

## 💼 Covered Job Roles (30+)

| Category | Keywords |
|---|---|
| **SDE / Engineering** | SDE, SDE-1, SDE-2, Software Engineer, Backend Engineer, Full Stack Developer, Frontend Developer |
| **AI / ML** | AI Engineer, ML Engineer, AIML Engineer, Machine Learning Engineer, Data Scientist, Data Engineer, MLOps Engineer, LLM Engineer, GenAI Engineer, NLP Engineer, Computer Vision Engineer, Deep Learning Engineer |
| **QA / Testing** | SDET, QA Automation Engineer |
| **DevOps / Cloud** | DevOps Engineer, Site Reliability Engineer, Platform Engineer, Cloud Engineer |
| **Stack Specific** | Java Developer, Python Developer, Node.js Developer, React Developer, Spring Boot Developer, Microservices Engineer |

---

## 🔧 Optional Customization

Add these environment variables in Render Dashboard → Environment tab to override defaults:

| Variable | Example |
|---|---|
| `SEARCH_KEYWORDS` | `SDE, ML Engineer, Backend Developer` |
| `CANDIDATE_EXPERIENCE` | `3` |
| `CANDIDATE_LOCATIONS` | `Bangalore, Remote` |
| `MAX_JOBS_TO_APPLY` | `999999` |

---

## 📁 Project Structure

```
├── Dockerfile                         # Chrome + Java 17 Docker image
├── render.yaml                        # Render deployment config
├── start.sh                           # Keep-alive server + scheduler + self-ping
├── pom.xml                            # Maven dependencies
└── src/main/
    ├── java/com/naukri/automation/
    │   ├── config/ConfigManager.java   # Reads config.properties
    │   ├── pages/
    │   │   ├── LoginPage.java          # Naukri login
    │   │   ├── SearchPage.java         # Job search + filters
    │   │   ├── JobDetailsPage.java     # Apply logic
    │   │   └── BasePage.java           # Selenium base utilities
    │   ├── runner/TestRunner.java      # Main entry point
    │   └── utils/
    │       ├── DriverFactory.java      # Chrome setup (headless)
    │       ├── DatabaseUtil.java       # Tracks applied jobs (prevents re-apply)
    │       ├── ReportUtil.java         # CSV report of applied jobs
    │       └── ScreenshotUtil.java     # Screenshots on failure
    └── resources/
        └── config.properties           # All settings (overridden by env vars)
```

---

## ❓ FAQ

**Will my resume be attached?**
Yes. The automation uses the resume already uploaded to your Naukri profile. No extra setup needed.

**Will it apply to the same job twice?**
No. `DatabaseUtil` tracks every applied job locally. Duplicates are skipped automatically.

**Will the free-tier server sleep?**
No. A built-in self-ping runs every 14 minutes to keep the server awake.

**How many jobs will it apply to?**
Unlimited. Every run processes as many matching jobs as it finds.
