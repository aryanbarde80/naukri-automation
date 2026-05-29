package com.naukri.automation.utils;

import com.naukri.automation.config.ConfigManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class ScreenshotUtil {
    private static final Logger logger = LogManager.getLogger(ScreenshotUtil.class);
    private static String screenshotDir;

    static {
        screenshotDir = ConfigManager.getProperty("screenshot.directory", "screenshots");
        try {
            Files.createDirectories(Paths.get(screenshotDir));
        } catch (IOException e) {
            logger.error("Failed to create screenshot directory: {}", screenshotDir, e);
        }
    }

    public static String captureScreenshot(WebDriver driver, String screenshotName) {
        if (driver == null) {
            logger.error("Driver is null; unable to capture screenshot.");
            return null;
        }

        try {
            TakesScreenshot ts = (TakesScreenshot) driver;
            File source = ts.getScreenshotAs(OutputType.FILE);
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String destinationPath = screenshotDir + File.separator + screenshotName + "_" + timestamp + ".png";
            File destinationFile = new File(destinationPath);
            Files.copy(source.toPath(), destinationFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            logger.info("Screenshot successfully captured: {}", destinationFile.getAbsolutePath());
            return destinationFile.getAbsolutePath();
        } catch (Exception e) {
            logger.error("Failed to capture screenshot.", e);
            return null;
        }
    }
}
