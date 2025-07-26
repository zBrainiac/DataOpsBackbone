# ARM64
# docker build --platform=linux/arm64 -t local-github-runner:arm64 .

# AMD64
# docker build --platform=linux/amd64 -t local-github-runner:amd64 .

FROM python:3.10.18-slim

# --- Build args ---
ARG RUNNER_VERSION="2.326.0"
ARG TARGETARCH
ARG DEBIAN_FRONTEND=noninteractive

# --- Install dependencies ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip zip curl openjdk-17-jre python3 python3-pip python3-dev \
    build-essential git jq ca-certificates libffi-dev libssl-dev file \
    dumb-init && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Install Sonar Scanner ---
RUN curl -L -o sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006.zip && \
    unzip sonar-scanner.zip -d /usr/local && \
    mv /usr/local/sonar-scanner-* /usr/local/sonar-scanner && \
    chmod +x /usr/local/sonar-scanner/bin/sonar-scanner && \
    ln -s /usr/local/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm sonar-scanner.zip

# --- Create docker user ---
RUN useradd -m docker

# --- Download & install GitHub Actions runner based on TARGETARCH ---
RUN mkdir -p /home/docker/actions-runner && \
    curl -LO https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${TARGETARCH}-${RUNNER_VERSION}.tar.gz && \
    tar -xzf actions-runner-linux-${TARGETARCH}-${RUNNER_VERSION}.tar.gz -C /home/docker/actions-runner && \
    rm actions-runner-linux-${TARGETARCH}-${RUNNER_VERSION}.tar.gz && \
    /home/docker/actions-runner/bin/installdependencies.sh && \
    chown -R docker /home/docker/actions-runner

# --- Install Snowflake CLI (SnowCLI) ---
RUN pip install --no-cache-dir snowflake-cli-labs

# --- Environment and entrypoint setup ---
ENV PATH="/usr/local/sonar-scanner/bin:/usr/local/bin:${PATH}"

COPY *.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER docker
WORKDIR /home/docker/actions-runner
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/entrypoint.sh"]
