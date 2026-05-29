package com.naukri.automation.pages;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.*;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import com.naukri.automation.config.ConfigManager;

import java.time.Duration;
import java.util.List;
import java.util.Random;

public class BasePage {
    protected WebDriver driver;
    protected WebDriverWait wait;
    protected Logger logger;
    private final Random random = new Random();

    public BasePage(WebDriver driver) {
        this.driver = driver;
        this.logger = LogManager.getLogger(this.getClass());
        int timeoutSeconds = ConfigManager.getIntProperty("wait.explicit.seconds", 15);
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
    }

    protected void click(By locator) {
        waitForElementClickable(locator);
        driver.findElement(locator).click();
    }

    protected void type(By locator, String text) {
        waitForElementVisible(locator);
        WebElement element = driver.findElement(locator);
        element.clear();
        element.sendKeys(text);
    }

    protected void waitForElementVisible(By locator) {
        wait.until(ExpectedConditions.visibilityOfElementLocated(locator));
    }

    protected void waitForElementClickable(By locator) {
        wait.until(ExpectedConditions.elementToBeClickable(locator));
    }

    protected boolean isElementPresent(By locator) {
        try {
            driver.findElement(locator);
            return true;
        } catch (NoSuchElementException e) {
            return false;
        }
    }

    protected boolean isElementVisible(By locator) {
        try {
            return driver.findElement(locator).isDisplayed();
        } catch (Exception e) {
            return false;
        }
    }

    public void delay(int minSeconds, int maxSeconds) {
        int delay = minSeconds * 1000 + random.nextInt((maxSeconds - minSeconds + 1) * 1000);
        try {
            Thread.sleep(delay);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public void delay() {
        int min = ConfigManager.getIntProperty("delay.min.seconds", 5);
        int max = ConfigManager.getIntProperty("delay.max.seconds", 15);
        delay(min, max);
    }

    public void checkAndHandleCaptcha() {
        By captchaLocator1 = By.xpath("//*[contains(text(), 'Verify you are human') or contains(text(), 'Please solve the CAPTCHA') or contains(text(), 'unusual traffic')]");
        By captchaLocator2 = By.id("challenge-stage");
        By captchaLocator3 = By.className("g-recaptcha");
        By captchaLocator4 = By.xpath("//iframe[contains(@src, 'recaptcha') or contains(@src, 'arkoselabs') or contains(@src, 'hcaptcha')]");

        boolean captchaDetected = isElementVisible(captchaLocator1) || 
                                  isElementVisible(captchaLocator2) || 
                                  isElementVisible(captchaLocator3) ||
                                  isElementVisible(captchaLocator4);

        if (captchaDetected) {
            logger.warn("==========================================================================");
            logger.warn("⚠️ CAPTCHA DETECTED! ⚠️");
            logger.warn("The automation is paused. Please complete the CAPTCHA manually in the browser.");
            logger.warn("The script will resume automatically once you solve it.");
            logger.warn("==========================================================================");

            int checkIntervalMs = 3000;
            while (true) {
                try {
                    Thread.sleep(checkIntervalMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }

                boolean stillExists = isElementVisible(captchaLocator1) || 
                                      isElementVisible(captchaLocator2) || 
                                      isElementVisible(captchaLocator3) ||
                                      isElementVisible(captchaLocator4);
                
                if (!stillExists) {
                    logger.info("Captcha resolved. Resuming execution...");
                    break;
                }
                logger.info("Waiting for manual CAPTCHA completion...");
            }
        }
    }
    
    public void handlePopups() {
        String[] popupXpaths = {
            "//button[text()='GOT IT']",
            "//span[contains(@class, 'crossIcon')]",
            "//div[contains(@class, 'crossIcon')]",
            "//div[text()='No thanks']",
            "//span[text()='Later']",
            "//span[contains(@class, 'close')]"
        };

        for (String xpath : popupXpaths) {
            try {
                List<WebElement> elements = driver.findElements(By.xpath(xpath));
                for (WebElement element : elements) {
                    if (element.isDisplayed()) {
                        element.click();
                        logger.info("Dismissed a popup using XPath: {}", xpath);
                    }
                }
            } catch (Exception e) {
                // Ignore if popups are not present or cannot be clicked
            }
        }
    }
}
