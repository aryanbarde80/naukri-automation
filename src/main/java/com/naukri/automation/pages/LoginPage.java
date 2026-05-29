package com.naukri.automation.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;

public class LoginPage extends BasePage {
    private final By loginButtonLanding = By.id("login_Layer");
    private final By emailInput = By.xpath("//input[contains(@placeholder, 'Email ID') or contains(@placeholder, 'Username')]");
    private final By passwordInput = By.xpath("//input[contains(@placeholder, 'password') or @type='password']");
    private final By submitButton = By.xpath("//button[@type='submit' or text()='Login']");
    private final By dashboardElement = By.xpath("//div[contains(@class, 'nProfile') or contains(@class, 'dashboard') or @class='gnb-header']");

    public LoginPage(WebDriver driver) {
        super(driver);
    }

    public void navigateToLandingPage() {
        logger.info("Navigating to Naukri.com landing page...");
        driver.get("https://www.naukri.com/");
        checkAndHandleCaptcha();
        handlePopups();
    }

    public boolean login(String username, String password) {
        try {
            logger.info("Clicking the login button on landing page...");
            click(loginButtonLanding);
            delay(2, 4);

            logger.info("Entering credentials...");
            type(emailInput, username);
            type(passwordInput, password);
            delay(1, 2);

            logger.info("Clicking the submit button...");
            click(submitButton);
            delay(3, 5);

            checkAndHandleCaptcha();
            handlePopups();

            boolean loggedIn = isElementPresent(dashboardElement) || 
                               driver.getCurrentUrl().contains("homepage") || 
                               driver.getCurrentUrl().contains("dashboard");
            if (loggedIn) {
                logger.info("Login check passed. Current URL: {}", driver.getCurrentUrl());
                return true;
            } else {
                logger.warn("Could not verify login via dashboard elements. Current URL is: {}", driver.getCurrentUrl());
                // Fallback check: if there is a profile image/logout option
                if (isElementPresent(By.xpath("//div[contains(@class, 'm-img')]")) || isElementPresent(By.xpath("//a[text()='Logout']"))) {
                    logger.info("Login confirmed via fallback elements.");
                    return true;
                }
                return false;
            }
        } catch (Exception e) {
            logger.error("Exception occurred during login sequence.", e);
            checkAndHandleCaptcha();
            return false;
        }
    }
}
