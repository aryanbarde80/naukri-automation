# 🤖 Naukri Job Application Automation

Automatically applies to jobs on Naukri.com 24/7. Runs on Render.com for free.

---

## 🚀 Deploy in 3 Steps

### Step 1 — Go to Render
1. [render.com](https://render.com) → **New** → **Web Service**
2. Connect GitHub → select `aryanbarde80/naukri-automation`
3. `render.yaml` auto-detect hoga → **Deploy** click karo

### Step 2 — Set 2 Environment Variables
Render Dashboard → your service → **Environment** tab:

| Variable | Value |
|---|---|
| `NAUKRI_USERNAME` | tera naukri email |
| `NAUKRI_PASSWORD` | tera naukri password |

**Save Changes** → auto redeploy. Done ✅

### Step 3 — Kuch nahi
Baaki sab already set hai. Server khud ping karta hai har 14 min mein. Koi extra tool nahi chahiye.

---

## ⚙️ Kya Kya Set Hai By Default

| Setting | Value |
|---|---|
| **Jobs per run** | Unlimited |
| **Automation schedule** | Har 6 ghante |
| **Keep-alive ping** | Har 14 min (built-in) |
| **Browser mode** | Headless (server pe chalega) |
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

## 🔧 Customize Karna Ho Toh

Render Dashboard → Environment tab mein ye optional vars add kar sakte ho:

| Variable | Example |
|---|---|
| `SEARCH_KEYWORDS` | `SDE, ML Engineer, Backend Developer` |
| `CANDIDATE_EXPERIENCE` | `3` |
| `CANDIDATE_LOCATIONS` | `Bangalore, Remote` |
| `MAX_JOBS_TO_APPLY` | `999999` |

---

## 📁 Project Structure

```
├── Dockerfile                        # Chrome + Java 17 Docker image
├── render.yaml                       # Render auto-deployment config
├── start.sh                          # Keep-alive server + scheduler + self-ping
├── pom.xml                           # Maven dependencies
└── src/main/
    ├── java/com/naukri/automation/
    │   ├── config/ConfigManager.java  # Reads config.properties
    │   ├── pages/
    │   │   ├── LoginPage.java         # Naukri login
    │   │   ├── SearchPage.java        # Job search + filters
    │   │   ├── JobDetailsPage.java    # Apply logic
    │   │   └── BasePage.java          # Selenium base utilities
    │   ├── runner/TestRunner.java     # Main entry point
    │   └── utils/
    │       ├── DriverFactory.java     # Chrome setup (headless)
    │       ├── DatabaseUtil.java      # Tracks applied jobs (no re-apply)
    │       ├── ReportUtil.java        # CSV report of applied jobs
    │       └── ScreenshotUtil.java    # Screenshots on failure
    └── resources/
        └── config.properties          # All settings (overridden by env vars)
```

---

## ❓ FAQ

**Resume upload hoga kya?**
Naukri pe tumhara resume already profile pe uploaded hai. Automation wahi use karta hai — alag se kuch nahi karna.

**Duplicate apply nahi hoga?**
Nahi. `DatabaseUtil` applied jobs track karta hai locally. Same job dobara apply nahi hoga.

**Free plan pe server so jayega?**
Nahi. Built-in self-ping har 14 min mein server ko jagaye rakhta hai.

**Kitni jobs apply hogi?**
Unlimited — jitni milein. Ek run mein sab cover hota hai.
