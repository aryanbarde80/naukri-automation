package com.naukri.automation.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import com.naukri.automation.utils.ScreenshotUtil;
import java.util.Set;

public class JobDetailsPage extends BasePage {
    private final By jobTitle = By.xpath("//h1[contains(@class, 'title') or contains(@class, 'jd-header-title') or @class='jd-header-title']");
    private final By companyName = By.xpath("//div[contains(@class, 'company') or contains(@class, 'jd-header-comp-name')]//a[1] | //a[contains(@class, 'companyName')]");
    private final By experienceRequired = By.xpath("//div[contains(@class, 'exp')] | //span[contains(@class, 'exp')] | //span[contains(text(), 'Yrs') or contains(text(), 'years')]");
    private final By jobLocation = By.xpath("//div[contains(@class, 'loc')] | //span[contains(@class, 'location')]");
    
    // Apply states
    private final By applyButton = By.xpath("//button[text()='Apply' or text()='Apply Now' or contains(text(), 'Apply')]");
    private final By alreadyAppliedIndicator = By.xpath("//span[text()='Applied' or text()='Already Applied' or contains(text(), 'Applied')] | //button[contains(text(), 'Applied')]");
    private final By externalApplyText = By.xpath("//span[contains(text(), 'company site') or contains(text(), 'company website')] | //button[contains(text(), 'company site') or contains(text(), 'company website')]");

    // Questionnaire overlays
    private final By questionnaireContainer = By.xpath("//div[contains(@class, 'chatbot') or contains(@class, 'question') or contains(@id, 'questionnaire') or contains(@class, 'modal')]");
    private final By closeQuestionnaireButton = By.xpath("//div[contains(@class, 'close') or contains(@class, 'cross')] | //button[contains(text(), 'Close') or @class='crossIcon']");

    public JobDetailsPage(WebDriver driver) {
        super(driver);
    }

    public void openJob(String url) {
        logger.info("Opening job details page: {}", url);
        driver.get(url);
        delay(3, 5);
        checkAndHandleCaptcha();
        handlePopups();
    }

    public JobInfo getJobInfo() {
        JobInfo info = new JobInfo();
        try {
            info.setTitle(getElementTextOrFallback(jobTitle, "Unknown Title"));
            info.setCompany(getElementTextOrFallback(companyName, "Unknown Company"));
            info.setExperience(getElementTextOrFallback(experienceRequired, "Not Specified"));
            info.setLocation(getElementTextOrFallback(jobLocation, "Not Specified"));
        } catch (Exception e) {
            logger.error("Failed to parse job header metadata.", e);
        }
        return info;
    }

    private String getElementTextOrFallback(By locator, String fallback) {
        try {
            if (isElementPresent(locator)) {
                return driver.findElement(locator).getText().trim();
            }
        } catch (Exception e) {
            // Suppress exception and fall back
        }
        return fallback;
    }

    public ApplyResult attemptApply(String jobUrl) {
        ApplyResult result = new ApplyResult();
        result.setJobUrl(jobUrl);

        try {
            // 1. Check if already applied
            if (isElementVisible(alreadyAppliedIndicator)) {
                logger.info("Skipping Job: Already applied to this listing.");
                result.setStatus("Already Applied");
                result.setMessage("Already applied indicator found on page.");
                return result;
            }

            // 2. Check if apply button is present
            if (!isElementPresent(applyButton)) {
                logger.info("Skipping Job: No apply button detected.");
                result.setStatus("Failed");
                result.setMessage("Apply button not found on page.");
                return result;
            }

            WebElement btn = driver.findElement(applyButton);
            String btnText = btn.getText().toLowerCase();

            // 3. Check for external redirect labels
            if (btnText.contains("company site") || btnText.contains("company website") || isElementPresent(externalApplyText)) {
                logger.info("Skipping Job: Requires external application (not Easy Apply).");
                result.setStatus("Skipped");
                result.setMessage("Requires external application on company site.");
                return result;
            }

            String parentWindow = driver.getWindowHandle();

            logger.info("Clicking the apply button...");
            btn.click();
            delay(3, 5);

            // 4. Check if new tab/window opened (indicating external redirect)
            Set<String> allWindows = driver.getWindowHandles();
            if (allWindows.size() > 1) {
                logger.info("Skipping Job: Redirected to a new window (external ATS). Closing window...");
                for (String window : allWindows) {
                    if (!window.equals(parentWindow)) {
                        driver.switchTo().window(window);
                        driver.close();
                    }
                }
                driver.switchTo().window(parentWindow);
                result.setStatus("Skipped");
                result.setMessage("Redirected to external window.");
                return result;
            }

            // 5. Check for questionnaire/chatbot overlays
            if (isElementPresent(questionnaireContainer)) {
                logger.info("Questionnaire / Chatbot container detected. Checking complexity...");
                int inputFields = driver.findElements(By.xpath("//div[contains(@class, 'modal') or contains(@class, 'chatbot')]//input | //textarea | //select")).size();
                if (inputFields > 2) {
                    logger.info("Skipping Job: Multi-question application form (count: {}).", inputFields);
                    closeQuestionnaire();
                    result.setStatus("Skipped");
                    result.setMessage("Lengthy questionnaire (" + inputFields + " fields).");
                    return result;
                } else {
                    logger.info("Simple questionnaire detected. Skipping to avoid submitting generic or default answers.");
                    closeQuestionnaire();
                    result.setStatus("Skipped");
                    result.setMessage("Skipped questionnaire elements.");
                    return result;
                }
            }

            // 6. Verify application status
            delay(2, 4);
            if (isElementVisible(alreadyAppliedIndicator) || driver.getPageSource().contains("Applied successfully") || driver.getPageSource().contains("Success")) {
                logger.info("Application successfully submitted.");
                result.setStatus("Applied");
                result.setMessage("Application succeeded.");
            } else {
                logger.info("Job applied successfully (clicked apply, no warnings).");
                result.setStatus("Applied");
                result.setMessage("Apply clicked, verification completed.");
            }

        } catch (Exception e) {
            logger.error("Exception encountered during apply workflow.", e);
            ScreenshotUtil.captureScreenshot(driver, "apply_workflow_error");
            result.setStatus("Failed");
            result.setMessage("Error: " + e.getMessage());
        }

        return result;
    }

    private void closeQuestionnaire() {
        try {
            if (isElementPresent(closeQuestionnaireButton)) {
                click(closeQuestionnaireButton);
                delay(1, 2);
                logger.info("Questionnaire overlay dismissed.");
            }
        } catch (Exception e) {
            logger.error("Failed to dismiss questionnaire overlay.", e);
        }
    }

    public static class JobInfo {
        private String title;
        private String company;
        private String experience;
        private String location;

        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getCompany() { return company; }
        public void setCompany(String company) { this.company = company; }
        public String getExperience() { return experience; }
        public void setExperience(String experience) { this.experience = experience; }
        public String getLocation() { return location; }
        public void setLocation(String location) { this.location = location; }
    }

    public static class ApplyResult {
        private String jobUrl;
        private String status;
        private String message;

        public String getJobUrl() { return jobUrl; }
        public void setJobUrl(String jobUrl) { this.jobUrl = jobUrl; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
    }
}
