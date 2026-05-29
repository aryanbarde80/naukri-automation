package com.naukri.automation.utils;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.naukri.automation.config.ConfigManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

public class DatabaseUtil {
    private static final Logger logger = LogManager.getLogger(DatabaseUtil.class);
    private static final ObjectMapper mapper = new ObjectMapper().registerModule(new JavaTimeModule());
    private static Map<String, AppliedJobInfo> db = new HashMap<>();
    private static File dbFile;

    static {
        String dbPath = ConfigManager.getProperty("database.filepath", "applied_jobs.json");
        dbFile = new File(dbPath);
        loadDatabase();
    }

    private static synchronized void loadDatabase() {
        if (!dbFile.exists()) {
            logger.info("Local database file not found. Initializing a new one at: {}", dbFile.getAbsolutePath());
            saveDatabase();
            return;
        }

        try {
            db = mapper.readValue(dbFile, new TypeReference<Map<String, AppliedJobInfo>>() {});
            logger.info("Loaded {} applied jobs from local database.", db.size());
        } catch (IOException e) {
            logger.error("Failed to load local database. Starting with an empty database.", e);
            db = new HashMap<>();
        }
    }

    private static synchronized void saveDatabase() {
        try {
            mapper.writerWithDefaultPrettyPrinter().writeValue(dbFile, db);
            logger.debug("Local database saved successfully.");
        } catch (IOException e) {
            logger.error("Failed to save local database to file: {}", dbFile.getAbsolutePath(), e);
        }
    }

    public static synchronized boolean hasApplied(String jobUrl) {
        String key = cleanUrl(jobUrl);
        return db.containsKey(key);
    }

    public static synchronized void addAppliedJob(String jobUrl, String title, String company, String location, String status) {
        String key = cleanUrl(jobUrl);
        AppliedJobInfo info = new AppliedJobInfo();
        info.setUrl(jobUrl);
        info.setTitle(title);
        info.setCompany(company);
        info.setLocation(location);
        info.setStatus(status);
        info.setApplyTime(LocalDateTime.now().toString());

        db.put(key, info);
        saveDatabase();
        logger.info("Job successfully logged: '{}' at '{}'", title, company);
    }

    private static String cleanUrl(String url) {
        if (url == null) return "";
        // Strip query parameters to normalize and make matching robust
        int queryPos = url.indexOf('?');
        if (queryPos != -1) {
            url = url.substring(0, queryPos);
        }
        return url.trim().toLowerCase();
    }

    public static class AppliedJobInfo {
        private String url;
        private String title;
        private String company;
        private String location;
        private String status;
        private String applyTime;

        // Getters and Setters
        public String getUrl() { return url; }
        public void setUrl(String url) { this.url = url; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getCompany() { return company; }
        public void setCompany(String company) { this.company = company; }
        public String getLocation() { return location; }
        public void setLocation(String location) { this.location = location; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getApplyTime() { return applyTime; }
        public void setApplyTime(String applyTime) { this.applyTime = applyTime; }
    }
}
