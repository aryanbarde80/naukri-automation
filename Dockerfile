# ============================================================
#  Naukri Automation - Docker Image
#  Java 17 + Chrome + ChromeDriver (headless)
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17-focal

# Install Chrome and required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    unzip \
    --no-install-recommends && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src ./src

# Pre-download Maven dependencies (speeds up runtime)
RUN mvn dependency:resolve -q

# Build the project
RUN mvn compile -q

# Expose port for the keep-alive web server
EXPOSE 8080

# Start script (runs the keep-alive server + schedules automation)
COPY start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
