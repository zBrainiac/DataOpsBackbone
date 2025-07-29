#!/bin/bash

# -----------------------------------------------------------------------------
# Snowflake SQL Validation using `snow` CLI
# -----------------------------------------------------------------------------
# Usage:
# ./sql_validation_v2.sh \
#   --CLONE_SCHEMA=IOT_CLONE \
#   --CLONE_DATABASE=MD_TEST \
#   --RELEASE_NUM=42 \
#   --CONNECTION_NAME=sfseeurope-demo_ci_user
#
# cd /usr/local/bin && ./sql_validation_v4.sh --CLONE_SCHEMA=IOT_CLONE --CLONE_DATABASE=MD_TEST --RELEASE_NUM=42 --CONNECTION_NAME=sfseeurope-demo_ci_user --TEST_FILE=tests.sqltest --JUNIT_REPORT_DIR=/tmp/sql-unit-report
# ./sql_validation_v4.sh --CLONE_SCHEMA=IOT_CLONE --CLONE_DATABASE=MD_TEST --RELEASE_NUM=42 --CONNECTION_NAME=sfseeurope-demo_ci_user --TEST_FILE=tests.sqltest --FAKE_RUN=false
# -----------------------------------------------------------------------------

FAKE_RUN=false  # Default value

set +e

# --- Argument parsing ---
for ARG in "$@"; do
  case $ARG in
    --CLONE_SCHEMA=*) CLONE_SCHEMA="${ARG#*=}" ;;
    --CLONE_DATABASE=*) CLONE_DATABASE="${ARG#*=}" ;;
    --RELEASE_NUM=*) RELEASE_NUM="${ARG#*=}" ;;
    --CONNECTION_NAME=*) CONNECTION_NAME="${ARG#*=}" ;;
    --TEST_FILE=*) TEST_FILE="${ARG#*=}" ;;
    --JUNIT_REPORT_DIR=*) JUNIT_REPORT_DIR="${ARG#*=}" ;;
    --FAKE_RUN=*) FAKE_RUN="${ARG#*=}" ;;
    *) echo "❌ Unknown argument: $ARG"; exit 1 ;;
  esac
done

# --- Validation ---
if [[ -z "$CLONE_SCHEMA" || -z "$CLONE_DATABASE" || -z "$RELEASE_NUM" || -z "$CONNECTION_NAME" || -z "$TEST_FILE" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 --CLONE_SCHEMA=... --CLONE_DATABASE=... --RELEASE_NUM=... --CONNECTION_NAME=... --TEST_FILE=..."
  exit 1
fi

if [[ ! -f "$TEST_FILE" ]]; then
  echo "❌ Test file not found: $TEST_FILE"
  exit 1
fi

echo "ℹ️ FAKE_RUN is set to: $FAKE_RUN"

UTC_TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%SZ")

# Detect Docker vs macOS and set JUNIT_REPORT_DIR accordingly
if [[ -f /.dockerenv ]] || grep -qE '/docker/|/lxc/' /proc/1/cgroup 2>/dev/null; then
  echo "🛠 Running inside Docker container"
  REPORT_DIR="/home/docker/sql-report-vol"
  JUNIT_REPORT_DIR="/home/docker/sql-unit-reports"
  COPY_TARGET="/usr/share/nginx/html/"
  RUNTIME="container"
elif [[ "$(uname)" == "Darwin" ]]; then
  echo "🍏 Running on macOS"
  REPORT_DIR="$(pwd)/unit-report"
  JUNIT_REPORT_DIR="$(pwd)/sql-unit-reports"
  COPY_TARGET="/tmp/nginx/html"
  RUNTIME="macos"
else
  echo "🔧 Unknown system, defaulting to current dir"
  REPORT_DIR="$(pwd)/unit-report"
  JUNIT_REPORT_DIR="$(pwd)/sql-unit-reports"
  COPY_TARGET="/tmpnginx/html"
  RUNTIME="unknown"
fi

JUNIT_REPORT_DIR="${JUNIT_REPORT_DIR:-./sql-unit-reports}"
JUNIT_REPORT_DIR="$(cd "$JUNIT_REPORT_DIR" && pwd)"

REPORT_SUBDIR="$JUNIT_REPORT_DIR/$UTC_TIMESTAMP"
mkdir -p "$REPORT_SUBDIR"
JUNIT_REPORT_FILE="$REPORT_SUBDIR/TEST_sqlunit.xml"

SUITE_NAME="${GITHUB_OWNER:-UnknownOwner}/${GITHUB_REPO:-UnknownRepo} SQL Validation"


echo "REPORT_DIR: $REPORT_DIR"
echo "JUNIT_REPORT_DIR: $JUNIT_REPORT_DIR"
echo "JUNIT_REPORT_FILE: $JUNIT_REPORT_FILE"
echo "COPY_TARGET: $COPY_TARGET"
echo "RUNTIME: $RUNTIME"

TEST_CASES=()
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_COUNT=0
TOTAL_TIME=0  # Gesamtzeit aller Tests

# --- Run test ---
run_test() {
  local description="$1"
  local raw_query="$2"
  local expected="$3"

  local query="${raw_query//\{\{SCHEMA\}\}/$CLONE_SCHEMA_WITH_RELEASE}"
  query="${query//\{\{DATABASE\}\}/$CLONE_DATABASE}"

  local start_time=$(date +%s)

  echo -e "\n🔎 $description"
  echo "📄 Query: $query"

  local output
  local exit_code
  if [[ "$FAKE_RUN" == true ]]; then
    output='[{"RESULT":"'"$expected"'"}]'
    exit_code=0
  else
    output=$(snow sql -c "$CONNECTION_NAME" -q "$query" --format json 2>&1)
    exit_code=$?
  fi

  local end_time=$(date +%s)
  local duration=$(awk "BEGIN { d = $end_time - $start_time; if (d < 0.001) d = 0.001; printf \"%.3f\", d }")

  # Gesamtzeit aufsummieren
  TOTAL_TIME=$(awk "BEGIN {print $TOTAL_TIME + $duration}")

  echo "🪵 Output: $output"
  echo "💥 Exit code: $exit_code"

  ((TOTAL_COUNT++))

  if [[ $exit_code -ne 0 ]]; then
    ((FAIL_COUNT++))
    TEST_CASES+=("<testcase name=\"$description\" classname=\"SQLValidation\" time=\"$duration\">
  <failure message=\"snow CLI failed\">$(echo "$output" | sed 's/"/'\''/g')</failure>
</testcase>")
    return
  fi

  local result
  result=$(echo "$output" | jq -r '.[0].RESULT // empty')

  if [[ -z "$result" ]]; then
    ((FAIL_COUNT++))
    TEST_CASES+=("<testcase name=\"$description\" classname=\"SQLValidation\" time=\"$duration\">
  <failure message=\"No result\">Empty result from query</failure>
</testcase>")
    return
  fi

  if [[ "$result" != "$expected" ]]; then
    ((FAIL_COUNT++))
    TEST_CASES+=("<testcase name=\"$description\" classname=\"SQLValidation\" time=\"$duration\">
  <failure message=\"Expected $expected, got $result\"/>
</testcase>")
  else
    TEST_CASES+=("<testcase name=\"$description\" classname=\"SQLValidation\" time=\"$duration\"/>")
  fi
}

# --- Inject a fake, periodically failing test case ---
#if [[ "$FAKE_RUN" == xxx ]]; then
#  # Fail every 3rd UTC minute
#  MOD=$(($(date -u +%M) % 2))
#    echo "🧪 Adding failing fake test case (modulo 3 = 0)"
#  if [[ "$MOD" -eq 0 ]]; then
#    run_test "🧪 Fake Failing Test" "SELECT 'unexpected'" "expected"
#  else
#    echo "🧪 Adding passing fake test case (modulo 3 ≠ 0)"
#    run_test "🧪 Fake Passing Test" "SELECT 'expected'" "expected"
#  fi
#fi


# --- Load and run tests ---
while IFS='|' read -r description sql expected; do
  if [[ -z "$description" || "$description" =~ ^# ]]; then
    ((SKIP_COUNT++))
    trimmed_desc="$(echo "${description:-Unnamed Skipped Test}" | xargs)"
    TEST_CASES+=("<testcase name=\"$trimmed_desc\" classname=\"SQLValidation\" time=\"0\"><skipped message=\"Commented or empty\"/></testcase>")
    continue
  fi

  run_test "$description" "$sql" "$expected"
done < "$TEST_FILE"

# --- Generate JUnit XML ---
echo -e "\n📝 Writing JUnit report to $JUNIT_REPORT_FILE"
{
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  TOTAL_TIME_FORMATTED=$(awk "BEGIN {printf \"%.3f\", $TOTAL_TIME}")
  echo "<testsuite name=\"Snowflake SQL Validation\" tests=\"$TOTAL_COUNT\" failures=\"$FAIL_COUNT\" errors=\"0\" skipped=\"$SKIP_COUNT\" time=\"$TOTAL_TIME_FORMATTED\" timestamp=\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\">"
  for case in "${TEST_CASES[@]}"; do
    echo "$case"
  done
  echo "</testsuite>"
} > "$JUNIT_REPORT_FILE"

# --- Final status ---
echo -e "\n📊 Test summary: $TOTAL_COUNT tests run, $FAIL_COUNT failed."
if [[ $FAIL_COUNT -eq 0 ]]; then
  echo "✅ All tests passed."
else
  echo "❌ Some tests failed. See $JUNIT_REPORT_FILE for details."
fi

# --- Run unitth.jar on all report subfolders ---
echo -e "\n🚀 Running unitth.jar on all reports in $JUNIT_REPORT_DIR ..."
echo "📁 Using report dir: $REPORT_DIR"
mkdir -p "$REPORT_DIR"
java -Dunitth.report.dir="$REPORT_DIR" -jar unitth.jar "$JUNIT_REPORT_DIR"/*

# Exit with original test status code
if [[ $FAIL_COUNT -eq 0 ]]; then
  exit 0
else
  exit 1
fi
