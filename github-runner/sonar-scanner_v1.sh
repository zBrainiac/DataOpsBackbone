#!/bin/bash
set -e

SONAR_TOKEN="${SONAR_TOKEN:?Missing SONAR_TOKEN}"
PROJECT_KEY="${PROJECT_KEY:?Missing PROJECT_KEY}"
SONAR_HOST="${SONAR_HOST:-http://localhost:9000}"

# Define sonar-scanner binary path inside the container
SONAR_SCANNER="/usr/local/sonar-scanner/bin/sonar-scanner"

# Check if the project already exists
echo "Checking if project '$PROJECT_KEY' exists in SonarQube..."
RESPONSE=$(curl -s -u "$SONAR_TOKEN:" "$SONAR_HOST/api/projects/search")

if echo "$RESPONSE" | jq -e '.components? // [] | any(.key == "'"$PROJECT_KEY"'")' > /dev/null; then
  echo "✅ Project '$PROJECT_KEY' already exists."
else
  echo "➕ Project '$PROJECT_KEY' not found. Creating it..."
  CREATE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -u "$SONAR_TOKEN:" -X POST "$SONAR_HOST/api/projects/create" \
    -d "name=$PROJECT_KEY" \
    -d "project=$PROJECT_KEY")

  if [ "$CREATE_RESPONSE" -eq 200 ]; then
    echo "✅ Successfully created project '$PROJECT_KEY'."
  elif [ "$CREATE_RESPONSE" -eq 400 ]; then
    echo "⚠️ Project '$PROJECT_KEY' likely already exists. Continuing..."
  else
    echo "❌ Failed to create project. HTTP code: $CREATE_RESPONSE"
    exit 1
  fi
fi

# Run sonar-scanner
echo "🚀 Running sonar-scanner..."
"$SONAR_SCANNER" \
  -Dsonar.projectKey="$PROJECT_KEY" \
  -Dsonar.projectBaseDir="/tmp/runner/work/$PROJECT_KEY/$PROJECT_KEY" \
  -Dsonar.host.url="$SONAR_HOST" \
  -Dsonar.scm.disabled=true \
  -Dsonar.language=sql \
  -Dsonar.sql.dialect=snowflake \
  -Dsonar.exclusions=".git/**" \
  -Dsonar.sourceEncoding="UTF-8" \
  -Dsonar.token="$SONAR_TOKEN"