package com.naukri.automation.config;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class ConfigManager {
    private static final Logger logger = LogManager.getLogger(ConfigManager.class);
    private static final Properties properties = new Properties();

    static {
        try (InputStream input = ConfigManager.class.getClassLoader().getResourceAsStream("config.properties")) {
            if (input == null) {
                logger.error("Unable to find config.properties");
                throw new RuntimeException("config.properties not found in classpath");
            }
            properties.load(input);
            logger.info("Configuration properties loaded successfully");
        } catch (IOException ex) {
            logger.error("Exception occurred while loading properties file", ex);
            throw new RuntimeException("Could not load config.properties", ex);
        }
    }

    public static String getProperty(String key) {
        return properties.getProperty(key);
    }

    public static String getProperty(String key, String defaultValue) {
        return properties.getProperty(key, defaultValue);
    }

    public static int getIntProperty(String key, int defaultValue) {
        String val = properties.getProperty(key);
        if (val == null || val.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(val.trim());
        } catch (NumberFormatException e) {
            logger.warn("Invalid integer property for key '{}': '{}'. Using default: {}", key, val, defaultValue);
            return defaultValue;
        }
    }

    public static boolean getBooleanProperty(String key, boolean defaultValue) {
        String val = properties.getProperty(key);
        if (val == null || val.trim().isEmpty()) {
            return defaultValue;
        }
        return Boolean.parseBoolean(val.trim());
    }
}
