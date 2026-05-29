package com.naukri.automation.utils;

import com.naukri.automation.config.ConfigManager;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class ReportUtil {
    private static final Logger logger = LogManager.getLogger(ReportUtil.class);
    private static String reportFilePath;

    static {
        String reportDir = ConfigManager.getProperty("report.directory", "reports");
        try {
            Files.createDirectories(Paths.get(reportDir));
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            reportFilePath = reportDir + File.separator + "job_applications_report_" + timestamp + ".csv";
            initReportFile();
        } catch (IOException e) {
            logger.error("Failed to initialize report utility: directory creation failed.", e);
        }
    }

    private static synchronized void initReportFile() {
        File file = new File(reportFilePath);
        if (!file.exists()) {
            try (FileWriter writer = new FileWriter(file);
                 CSVPrinter csvPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT.builder()
                         .setHeader("Job Title", "Company Name", "Location", "Experience Required", "Application Status", "Apply Time")
                         .build())) {
                csvPrinter.flush();
                logger.info("CSV Report file initialized at: {}", file.getAbsolutePath());
            } catch (IOException e) {
                logger.error("Failed to write CSV headers to file.", e);
            }
        }
    }

    public static synchronized void writeRecord(String title, String company, String location, String experience, String status) {
        if (reportFilePath == null) {
            logger.error("CSV Report file path is not initialized; skipped logging this job record.");
            return;
        }

        String applyTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        try (FileWriter writer = new FileWriter(reportFilePath, true);
             CSVPrinter csvPrinter = new CSVPrinter(writer, CSVFormat.DEFAULT)) {
            csvPrinter.printRecord(
                    cleanValue(title),
                    cleanValue(company),
                    cleanValue(location),
                    cleanValue(experience),
                    cleanValue(status),
                    applyTime
            );
            csvPrinter.flush();
            logger.info("Logged application to CSV: '{}' at '{}' -> Status: {}", title, company, status);
        } catch (IOException e) {
            logger.error("Failed to append job application record to CSV file.", e);
        }
    }

    private static String cleanValue(String val) {
        if (val == null) return "N/A";
        return val.trim().replaceAll("\\s+", " ");
    }
}
