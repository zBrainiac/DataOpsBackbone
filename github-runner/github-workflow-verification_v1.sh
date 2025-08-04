#!/bin/bash

# github-workflow-verification_v1.sh
# shasum -a 256 update-local-repo.yml
# Validates the SHA256 hash of the update-local-repo.yml GitHub Actions workflow file
# f668ceb2a84cf9657cb6ad7472bc294876a044e8b8a30cbbfb328fa5ad7fed9c  update-local-repo.yml

# --- Runtime detection ---
if [[ -f /.dockerenv ]] || grep -qE '/docker/|/lxc/' /proc/1/cgroup 2>/dev/null; then
  echo "🛠 Running inside Docker container"
  WORKFLOW_FILE="/home/docker/actions-runner/_work/$PROJECT_KEY/$PROJECT_KEY/.github/workflows/update-local-repo.yml"
elif [[ "$(uname)" == "Darwin" ]]; then
 echo "🍏 Running on macOS"
  WORKFLOW_FILE="$USER/workspace/mother-of-all-Projects/.github/workflows/.github/workflows/update-local-repo.yml"
else
  echo "🔧 Unknown system, defaulting to current dir"
  WORKFLOW_FILE="$USER/workspace/mother-of-all-Projects/.github/workflows/.github/workflows/update-local-repo.yml"
fi


# === CONFIGURATION ===
EXPECTED_HASH="f668ceb2a84cf9657cb6ad7472bc294876a044e8b8a30cbbfb328fa5ad7fed9c"

# === VALIDATION ===

if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "❌ ERROR: Workflow file not found: $WORKFLOW_FILE"
  exit 1
fi

ACTUAL_HASH=$(sha256sum "$WORKFLOW_FILE" | awk '{print $1}')

echo "🔍 Verifying workflow integrity..."
echo "→ Expected SHA256: $EXPECTED_HASH"
echo "→ Actual   SHA256: $ACTUAL_HASH"

if [[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]]; then
  echo "✅ Workflow verification successful: integrity confirmed."
  exit 0
else
  echo "❌ Workflow verification failed: hash mismatch."
  exit 1
fi
