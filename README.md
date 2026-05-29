# Naukri.com Job Search and Auto-Apply Tool

A robust, production-ready Selenium-Java-Maven automation framework designed to securely search and automatically apply for relevant jobs on Naukri.com based on custom profiles (SDET / QA Automation Engineer), locations, experience levels, and salary ranges.

## Table of Contents
1. [Project Deliverables](#project-deliverables)
2. [Folder Structure](#folder-structure)
3. [Setup & Installation](#setup--installation)
4. [Execution Guide](#execution-guide)
5. [Technical Architecture](#technical-architecture)
6. [Best Practices for Account Protection](#best-practices-for-account-protection)

---

## Project Deliverables
- **Maven Automation Framework**: Custom built using Selenium 4, Log4j 2, and WebDriverManager.
- **Page Object Model (POM) Design**: Modular architecture separating UI locators from execution logic.
- **Dynamic Configuration Manager**: Exposes search controls, experience levels, notice periods, and locations via properties.
- **Execution Logger**: Rolling log output utilizing Log4j 2.
- **Reporting Engine**: CSV compiler recording application statuses, positions, locations, and timestamps.
- **JSON Transaction Database**: Maintains historical records of applied jobs to avoid duplicate efforts.
- **Anti-Bot & Verification Shielding**: Custom browser attributes (disabling automation flags, user-agents, random human sleep intervals) and manual CAPTCHA pauses.

---

## Folder Structure

```
Naukri automation/
│
├── pom.xml                      # Maven build file containing project dependencies
├── README.md                    # This Setup, Execution, and Documentation guide
├── .gitignore                   # Excludes target/, configurations, and local logs from Git
│
└── src/
    └── main/
        ├── java/
        │   └── com/
        │       └── naukri/
        │           └── automation/
        │               ├── config/
        │               │   └── ConfigManager.java     # Property-file loader utility
        │               │
        │               ├── pages/
        │               │   ├── BasePage.java          # Selenium wrappers, delays, and Captchas
        │               │   ├── LoginPage.java         # Login POM class
        │               │   ├── SearchPage.java        # Search, filters, and pagination POM
        │               │   └── JobDetailsPage.java    # Job parsing & application submission POM
        │               │
        │               ├── utils/
        │               │   ├── DriverFactory.java     # WebDriver instantiation & options manager
        │               │   ├── DatabaseUtil.java      # JSON local file tracker database
        │               │   ├── ReportUtil.java        # CSV log reporting compiler
        │               │   └── ScreenshotUtil.java    # Captured images storage on error
        │               │
        │               └── runner/
        │                   └── TestRunner.java        # Main orchestration executor class
        │
        └── resources/
            ├── config.properties   # Main configuration profile and credentials
            └── log4j2.xml          # Log4j configuration defining Console and Rolling Log files
```

---

## Setup & Installation

### Prerequisites
1. **Java Development Kit (JDK)**: Ensure JDK 17 or higher is installed and configured in your environment (`JAVA_HOME` path).
2. **Apache Maven**: Ensure Maven is installed and added to your system path.
3. **Google Chrome**: Ensure you have Google Chrome browser installed (Chromedriver will be managed automatically by WebDriverManager).

### Step-by-Step Configuration
1. Open the project in your favorite IDE (IntelliJ IDEA, Eclipse, or VS Code).
2. Navigate to `src/main/resources/config.properties`.
3. Configure your Naukri account credentials:
   ```properties
   naukri.username=your_actual_email@example.com
   naukri.password=your_actual_password
   ```
4. Adjust filters based on your profile:
   - `candidate.experience=4`
   - `candidate.locations=Indore, Pune, Noida`
   - `candidate.expected.ctc=12`
   - `candidate.notice.period=3 mths`
5. Save the file.

---

## Execution Guide

### Running via Command Line
Open a terminal in the root directory of the project and execute:
```bash
mvn clean compile exec:java
```

### Running via IDE
Open `src/main/java/com/naukri/automation/runner/TestRunner.java` and click the **Run** button on the `main` method.

### How it Works during Runtime
1. **Driver Start**: Launches Chrome browser.
2. **Login Verification**: Navigates to Naukri, fills credentials, clicks Login.
3. **CAPTCHA Check**: If Naukri triggers a CAPTCHA, the execution pauses. Solve it manually in the browser and the tool will resume automatically.
4. **Keywords Loop**: For each keyword (e.g. SDET, QA Automation Engineer):
   - Searches Naukri listings.
   - Applies locations (Indore, Pune, Noida) and freshness filters (Last 7 Days).
   - Scrapes job cards across pages.
5. **Auto-Apply Decisions**:
   - Opens each job in the browser.
   - Checks if it's already in `applied_jobs.json`. If yes, it skips.
   - Inspects the apply button. If it's an external redirect (e.g., "Apply on company website"), it skips.
   - Checks for chatbot/questionnaire popups. If present, it skips to prevent sending incorrect details.
   - Clicks "Apply".
   - Logs result to `reports/job_applications_report_<timestamp>.csv` and appends URL to `applied_jobs.json`.
6. **Politeness Pause**: Pauses 5–15 seconds dynamically after every job to maintain a human-like cadence.

---

## Best Practices for Account Protection

Web portals like Naukri implement security firewalls to block scrapers and automated bots. Follow these rules to protect your account:
1. **Run in Headed Mode**: Keep `browser.headless=false` in properties. Headless browsers are easily detected by Cloudflare.
2. **Use Realistic Application Limits**: Limit applications to 15-20 jobs per day. Applying to hundreds of jobs in minutes is flaggable as non-human activity.
3. **Maintain Random Delays**: Ensure `delay.min.seconds` and `delay.max.seconds` are set to at least 5 and 15 seconds respectively.
4. **Solve CAPTCHAs Immediately**: If a CAPTCHA triggers, do not close the browser. Solve it manually so Naukri's system marks the session as human-verified.
5. **Keep Profile Completed**: Make sure your Naukri resume and details are fully updated so the "Easy Apply" runs smoothly.
