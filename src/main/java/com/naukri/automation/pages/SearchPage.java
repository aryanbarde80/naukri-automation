package com.naukri.automation.pages;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import java.util.ArrayList;
import java.util.List;

public class SearchPage extends BasePage {
    private final By jobTitleLinks = By.xpath("//a[contains(@class, 'title') and contains(@href, 'job-listings')]");
    private final By nextPageButton = By.xpath("//a[span[text()='Next']] | //a[contains(@class, 'styles_btn') and span[text()='Next']] | //a[contains(@class, 'page') and text()='Next']");
    private final By freshnessFilterHeader = By.xpath("//span[contains(text(), 'Freshness') or contains(text(), 'Posted by')]");
    
    public SearchPage(WebDriver driver) {
        super(driver);
    }

    public void searchJobs(String keyword, int experience, String locations) {
        String formattedKeyword = keyword.toLowerCase().trim().replaceAll("\\s+", "-");
        String searchUrl = "https://www.naukri.com/" + formattedKeyword + "-jobs?experience=" + experience;
        
        logger.info("Navigating to search URL: {}", searchUrl);
        driver.get(searchUrl);
        delay(3, 5);
        checkAndHandleCaptcha();
        handlePopups();

        // Apply locations on the UI
        applyLocationFilters(locations);
        
        // Apply freshness filter (posted within last 7 days)
        applyFreshnessFilter();
    }

    private void applyLocationFilters(String locationsStr) {
        if (locationsStr == null || locationsStr.trim().isEmpty()) {
            return;
        }

        String[] locations = locationsStr.split(",");
        for (String loc : locations) {
            String location = loc.trim();
            logger.info("Applying location filter for: {}", location);
            try {
                // Check if location checkbox is already visible on the sidebar (match case-insensitively)
                By locCheckbox = By.xpath("//span[contains(@class, 'label') and translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='" + location.toLowerCase() + "']");
                if (isElementVisible(locCheckbox)) {
                    click(locCheckbox);
                    delay(2, 4);
                    logger.info("Selected location checkbox: {}", location);
                } else {
                    // Try to search for location inside the filter search box
                    By searchBox = By.xpath("//input[contains(@placeholder, 'Search location') or contains(@placeholder, 'Search Location') or contains(@placeholder, 'location')]");
                    if (isElementVisible(searchBox)) {
                        type(searchBox, location);
                        delay(1, 2);
                        // Click the matched option from autocomplete list
                        By firstResult = By.xpath("//div[contains(@class, 'dropdown')]//span[contains(text(), '" + location + "')] | //span[contains(@class, 'label') and contains(text(), '" + location + "')]");
                        click(firstResult);
                        delay(2, 4);
                        logger.info("Typed and selected location: {}", location);
                    } else {
                        logger.warn("Location filter checkbox/searchbox not visible for: {}", location);
                    }
                }
            } catch (Exception e) {
                logger.error("Failed to apply location filter for: {}", location, e);
            }
        }
    }

    private void applyFreshnessFilter() {
        logger.info("Applying freshness filter (Last 7 Days)...");
        try {
            By freshness7Days = By.xpath("//span[text()='Last 7 Days'] | //label[contains(., 'Last 7 Days')] | //span[contains(text(), '7 Days')] | //span[contains(text(), 'Last 15 Days')]"); // Fallback to 15 if 7 not visible
            if (isElementVisible(freshness7Days)) {
                click(freshness7Days);
                delay(3, 5);
                logger.info("Freshness filter applied.");
            } else {
                if (isElementVisible(freshnessFilterHeader)) {
                    click(freshnessFilterHeader);
                    delay(1, 2);
                    if (isElementVisible(freshness7Days)) {
                        click(freshness7Days);
                        delay(3, 5);
                        logger.info("Freshness filter applied after expanding header.");
                        return;
                    }
                }
                logger.warn("Freshness filter option not visible.");
            }
        } catch (Exception e) {
            logger.error("Failed to apply freshness filter.", e);
        }
    }

    public List<String> getJobUrls() {
        List<String> urls = new ArrayList<>();
        try {
            waitForElementVisible(jobTitleLinks);
            List<WebElement> elements = driver.findElements(jobTitleLinks);
            for (WebElement element : elements) {
                String href = element.getAttribute("href");
                if (href != null && !href.isEmpty()) {
                    urls.add(href);
                }
            }
            logger.info("Found {} job listings on the page.", urls.size());
        } catch (Exception e) {
            logger.error("Failed to retrieve job URLs from the current page.", e);
        }
        return urls;
    }

    public boolean navigateToNextPage() {
        try {
            if (isElementVisible(nextPageButton)) {
                logger.info("Navigating to the next page...");
                click(nextPageButton);
                delay(3, 5);
                checkAndHandleCaptcha();
                handlePopups();
                return true;
            } else {
                logger.info("No next page link/button is visible.");
                return false;
            }
        } catch (Exception e) {
            logger.error("Exception occurred when trying to page forward.", e);
            return false;
        }
    }
}
