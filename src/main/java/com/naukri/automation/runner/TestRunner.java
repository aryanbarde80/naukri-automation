package com.naukri.automation.runner;

import com.naukri.automation.config.ConfigManager;
import com.naukri.automation.pages.JobDetailsPage;
import com.naukri.automation.pages.LoginPage;
import com.naukri.automation.pages.SearchPage;
import com.naukri.automation.utils.DatabaseUtil;
import com.naukri.automation.utils.DriverFactory;
import com.naukri.automation.utils.ReportUtil;
import com.naukri.automation.utils.ScreenshotUtil;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.WebDriver;

import java.util.LinkedHashSet;
import java.util.Set;

public class TestRunner {
    private static final Logger logger = LogManager.getLogger(TestRunner.class);

    public static void main(String[] args) {
        logger.info("Starting Naukri Job Application Automation Engine...");

        String username = ConfigManager.getProperty("naukri.username");
        String password = ConfigManager.getProperty("naukri.password");

        if (username == null || username.trim().isEmpty() || username.contains("your_email") || 
            password == null || password.trim().isEmpty() || password.contains("your_password")) {
            logger.error("=======================================================================================");
            logger.error("❌ CONFIGURATION ERROR: INVALID CREDENTIALS ❌");
            logger.error("Please configure your actual Naukri username and password inside the properties file:");
            logger.error("src/main/resources/config.properties");
            logger.error("=======================================================================================");
            System.exit(1);
        }

        String keywordsStr = ConfigManager.getProperty("search.keywords", "SDET, QA Automation Engineer");
        int experience = ConfigManager.getIntProperty("candidate.experience", 4);
        String locations = ConfigManager.getProperty("candidate.locations", "Indore, Pune, Noida");
        int maxApplies = ConfigManager.getIntProperty("max.jobs.to.apply", 20);

        WebDriver driver = null;
        int appliedCount = 0;

        try {
            driver = DriverFactory.getDriver();

            // 1. Authenticate Candidate
            LoginPage loginPage = new LoginPage(driver);
            loginPage.navigateToLandingPage();
            boolean isLoggedIn = loginPage.login(username, password);

            if (!isLoggedIn) {
                logger.error("Login verification failed. Capturing failure screenshot and shutting down.");
                ScreenshotUtil.captureScreenshot(driver, "auth_failure");
                return;
            }
            logger.info("Authentication verified successfully. Navigating to job search.");

            // 2. Fetch and Collect Job Listings case by case
            String[] keywords = keywordsStr.split(",");
            SearchPage searchPage = new SearchPage(driver);
            JobDetailsPage jobDetailsPage = new JobDetailsPage(driver);

            // Use Set to prevent duplicates across keyword results
            Set<String> jobsToProcess = new LinkedHashSet<>();

            for (String kw : keywords) {
                String keyword = kw.trim();
                logger.info("==========================================================");
                logger.info("Scanning listings for keyword: '{}'", keyword);
                logger.info("==========================================================");

                searchPage.searchJobs(keyword, experience, locations);
                
                // Get URLs from First Page
                Set<String> pageUrls = new LinkedHashSet<>(searchPage.getJobUrls());
                jobsToProcess.addAll(pageUrls);

                // Check page 2 for more listings
                int pagesLimit = 2; 
                int pageCount = 1;
                while (pageCount < pagesLimit && !pageUrls.isEmpty()) {
                    if (searchPage.navigateToNextPage()) {
                        pageUrls = new LinkedHashSet<>(searchPage.getJobUrls());
                        jobsToProcess.addAll(pageUrls);
                        pageCount++;
                    } else {
                        break;
                    }
                }
            }

            logger.info("Scan complete. Collected {} unique job URLs for analysis.", jobsToProcess.size());

            // 3. Process each job URL individually
            for (String jobUrl : jobsToProcess) {
                if (appliedCount >= maxApplies) {
                    logger.info("Maximum run limit reached ({} applies). Halting runner.", maxApplies);
                    break;
                }

                logger.info("Analyzing URL: {}", jobUrl);

                // Local Duplicate prevention
                if (DatabaseUtil.hasApplied(jobUrl)) {
                    logger.info("Skipping URL: Already applied in previous sessions.");
                    continue;
                }

                try {
                    jobDetailsPage.openJob(jobUrl);
                    JobDetailsPage.JobInfo jobInfo = jobDetailsPage.getJobInfo();
                    
                    logger.info("Processing Metadata - Title: '{}' | Company: '{}' | Exp: '{}' | Loc: '{}'", 
                            jobInfo.getTitle(), jobInfo.getCompany(), jobInfo.getExperience(), jobInfo.getLocation());

                    // Execute Apply sequence
                    JobDetailsPage.ApplyResult result = jobDetailsPage.attemptApply(jobUrl);

                    // Log results to CSV Report
                    ReportUtil.writeRecord(
                            jobInfo.getTitle(),
                            jobInfo.getCompany(),
                            jobInfo.getLocation(),
                            jobInfo.getExperience(),
                            result.getStatus()
                    );

                    // Add to local database to avoid re-applying in future runs
                    DatabaseUtil.addAppliedJob(
                            jobUrl,
                            jobInfo.getTitle(),
                            jobInfo.getCompany(),
                            jobInfo.getLocation(),
                            result.getStatus()
                    );

                    if ("Applied".equalsIgnoreCase(result.getStatus())) {
                        appliedCount++;
                        logger.info("Apply counter: {} / {}", appliedCount, maxApplies);
                    }

                    // Dynamic human-like pause
                    jobDetailsPage.delay();

                } catch (Exception e) {
                    logger.error("Failed to process job listing at URL: {}", jobUrl, e);
                }
            }

            logger.info("==========================================================");
            logger.info("Automation process completed successfully.");
            logger.info("Total jobs applied in this run: {}", appliedCount);
            logger.info("==========================================================");

        } catch (Exception e) {
            logger.fatal("Fatal execution exception inside runner main process.", e);
        } finally {
            logger.info("Releasing Webdriver resource...");
            DriverFactory.quitDriver();
        }
    }
}
