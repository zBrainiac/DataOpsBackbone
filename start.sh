#!/bin/bash
set -e

# Step 0: Clean up
# echo "🚧 Clean up..."
# docker compose down -v --remove-orphans

# Step 1: Build the GitHub runner image
echo "🚧 Building GitHub runner image..."
docker build --platform=linux/arm64 -t local-github-runner -f github-runner/Dockerfile_arm64 github-runner

# Step 2: Build the SonarQube image (from current directory)
echo "🚧 Building SonarQube image..."
docker build --platform=linux/arm64 -t sonarqube ./sonarqube

# Step 3: Start all services
echo "🚀 Starting all services with docker compose..."
docker compose --env-file .env up
