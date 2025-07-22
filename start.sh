#!/bin/bash
set -e

# Step 1: Build the GitHub runner image
echo "🚧 Building GitHub runner image..."
docker build --platform=linux/arm64 -t local-github-runner ./github-runner

# Step 2: Start all services using docker compose
echo "🚀 Starting all services with docker compose..."
docker compose up --build
