# docker build --platform=linux/amd64 -t local-github-runner .
# docker build --platform=linux/arm64 -t local-github-runner .

FROM myoung34/github-runner:latest

RUN apt-get update && apt-get install -y \
    unzip curl openjdk-17-jre python3 python3-pip python3-dev build-essential git && \
    \
    # Install Sonar Scanner
    curl -L -o sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip && \
    unzip sonar-scanner.zip -d /usr/local && \
    mv /usr/local/sonar-scanner-* /usr/local/sonar-scanner && \
    chmod +x /usr/local/sonar-scanner/bin/sonar-scanner && \
    ln -s /usr/local/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm sonar-scanner.zip && \
    \
    # Install Snowflake CLI and Python packages
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir \
      "urllib3<2.0.0,>=1.21.1" \
      "snowflake-connector-python>=3.14.0,<4.0.0" \
      "snowflake-snowpark-python==1.30.0" \
      "snowflake-cli-labs"

# Add sonar-scanner to PATH
ENV PATH="/usr/local/sonar-scanner/bin:/usr/local/bin:${PATH}"

# Copy helper scripts
COPY *.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
