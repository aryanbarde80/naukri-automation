package com.naukri.automation.utils;

import io.github.bonigarcia.wdm.WebDriverManager;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import com.naukri.automation.config.ConfigManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.Duration;
import java.util.Collections;

public class DriverFactory {
    private static final Logger logger = LogManager.getLogger(DriverFactory.class);
    private static final ThreadLocal<WebDriver> driver = new ThreadLocal<>();

    public static WebDriver getDriver() {
        if (driver.get() == null) {
            initDriver();
        }
        return driver.get();
    }

    private static synchronized void initDriver() {
        if (driver.get() != null) {
            return;
        }
        logger.info("Setting up Chromedriver via WebDriverManager...");
        try {
            WebDriverManager.chromedriver().setup();
        } catch (Exception e) {
            logger.warn("WebDriverManager setup failed. Falling back on built-in Selenium Manager.", e);
        }

        ChromeOptions options = new ChromeOptions();

        // Anti-bot detection switches
        options.addArguments("--disable-blink-features=AutomationControlled");
        options.addArguments("--start-maximized");
        options.addArguments("--disable-infobars");
        options.addArguments("--disable-notifications");
        options.addArguments("--disable-popup-blocking");
        options.setExperimentalOption("excludeSwitches", Collections.singletonList("enable-automation"));
        options.setExperimentalOption("useAutomationExtension", false);

        // Optional Headless mode
        boolean headless = ConfigManager.getBooleanProperty("browser.headless", false);
        if (headless) {
            logger.info("Configuring Chrome to run in HEADLESS mode");
            options.addArguments("--headless=new");
            options.addArguments("--window-size=1920,1080");
            options.addArguments("--disable-gpu");
            options.addArguments("--no-sandbox");
            options.addArguments("--disable-dev-shm-usage");
        } else {
            logger.info("Configuring Chrome to run in HEADED mode");
        }

        // Add a common User Agent to bypass basic web scrapers screening
        options.addArguments("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36");

        WebDriver webDriver = new ChromeDriver(options);

        // Configure Page Load and Script Timeouts
        webDriver.manage().timeouts().pageLoadTimeout(Duration.ofSeconds(60));
        webDriver.manage().timeouts().scriptTimeout(Duration.ofSeconds(30));

        driver.set(webDriver);
        logger.info("WebDriver instance configured and stored in ThreadLocal.");
    }

    public static void quitDriver() {
        if (driver.get() != null) {
            try {
                driver.get().quit();
                logger.info("WebDriver instance successfully closed.");
            } catch (Exception e) {
                logger.error("Failed to quit WebDriver instance.", e);
            } finally {
                driver.remove();
            }
        }
    }
}
