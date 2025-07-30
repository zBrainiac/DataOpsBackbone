#!/bin/bash
set -e

# Step 0: Clean up (optional)
# docker compose down -v --remove-orphans

# Detect architecture
ARCH=$(uname -m)
echo "🔍 Detected architecture: $ARCH"

case "$ARCH" in
  x86_64)
    PLATFORM="linux/amd64"
    TARGETARCH="amd64"
    ;;
  arm64|aarch64)
    PLATFORM="linux/arm64"
    TARGETARCH="arm64"
    ;;
  *)
    echo "❌ Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "🚧 Building GitHub runner image for $PLATFORM..."
docker build \
  --platform=$PLATFORM \
  --build-arg TARGETARCH=$TARGETARCH \
  -t brainiac/local-github-runner \
  -f github-runner/Dockerfile \
  github-runner

echo "🚧 Building SonarQube image for $PLATFORM..."
docker build \
  --platform=$PLATFORM \
  --build-arg TARGETARCH=$TARGETARCH \
  -t brainiac/sonarqube \
  ./sonarqube

echo "🚀 Starting all services with docker compose..."
docker compose --env-file .env up