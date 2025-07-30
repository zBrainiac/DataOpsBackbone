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

echo "ℹ️ FAKE_RUN is set to: $FAKE_RUN"

# --- Validation ---
if [[ -z "$CLONE_SCHEMA" || -z "$CLONE_DATABASE" || -z "$RELEASE_NUM" || -z "$CONNECTION_NAME" || -z "$TEST_FILE" ]]; then
  echo "❌ Missing required arguments."
  exit 1
fi

if [[ ! -f "$TEST_FILE" ]]; then
  echo "❌ Test file not found: $TEST_FILE"
  exit 1
fi

CLONE_SCHEMA_WITH_RELEASE="${CLONE_SCHEMA}_${RELEASE_NUM}"
UTC_TIMESTAMP=$(date -u +"%Y-%m-%dT%H%M%SZ")
TESTSUITE_NAME="${GITHUB_OWNER:-UnknownOwner}_${GITHUB_REPO:-UnknownRepo}_SQLValidation"
echo "TESTSUITE_NAME: $TESTSUITE_NAME"

# --- Runtime detection ---
if [[ -f /.dockerenv ]] || grep -qE '/docker/|/lxc/' /proc/1/cgroup 2>/dev/null; then
  echo "🛠 Running inside Docker container"
  REPORT_DIR="/home/docker/sql-report-vol"
  RUNTIME="container"
  JUNIT_REPORT_DIR="/home/docker/sql-unit-reports"
elif [[ "$(uname)" == "Darwin" ]]; then
 echo "🍏 Running on macOS"
  RUNTIME="macos"
  REPORT_DIR="$(pwd)/sql-report-vol"
  JUNIT_REPORT_DIR="$(pwd)/sql-unit-reports"
else
  echo "🔧 Unknown system, defaulting to current dir"
  RUNTIME="unknown"
  REPORT_DIR="$(pwd)/sql-report-vol"
  JUNIT_REPORT_DIR="$(pwd)/sql-unit-reports"
fi

JUNIT_REPORT_DIR="$(cd "$JUNIT_REPORT_DIR" && pwd)"
REPORT_SUBDIR="$JUNIT_REPORT_DIR/$UTC_TIMESTAMP"
mkdir -p "$REPORT_SUBDIR"
JUNIT_REPORT_FILE="$REPORT_SUBDIR/TEST_${UTC_TIMESTAMP}.xml"

echo "REPORT_DIR: $REPORT_DIR"
echo "JUNIT_REPORT_DIR: $JUNIT_REPORT_DIR"
echo "JUNIT_REPORT_FILE: $JUNIT_REPORT_FILE"

# --- Initialize test stats ---
TOTAL_TESTS=0
FAILED_TESTS=0
SKIP_COUNT=0
TOTAL_TIME=0

# --- Start writing JUnit XML ---
{
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > "$JUNIT_REPORT_FILE"
  echo "<testsuite name=\"${TESTSUITE_NAME}\" tests=\"0\" failures=\"0\" skipped=\"0\" time=\"0.000\">"
} > "$JUNIT_REPORT_FILE"

# --- Test function ---
run_test() {
  local TEST_NAME="$1"
  local SQL_QUERY="$2"
  local EXPECTED="$3"
  local OUTPUT RESULT
  local START_TIME=$(date +%s)

  if [[ "$FAKE_RUN" == true ]]; then
    RESULT="$EXPECTED"   # simulate perfect match
    EXIT_CODE=0
  else
    SQL_QUERY_PROCESSED=$(echo "$SQL_QUERY" | sed "s/{{DATABASE}}/$CLONE_DATABASE/g" | sed "s/{{SCHEMA}}/$CLONE_SCHEMA_WITH_RELEASE/g")
    # use snow cli to execute command
    OUTPUT=$(snow sql -q "$SQL_QUERY_PROCESSED" -c "$CONNECTION_NAME" --format=json)
    RESULT=$(echo "$OUTPUT" | jq -r '.[0].RESULT')
    EXIT_CODE=$?
  fi

  local END_TIME=$(date +%s)
  local DURATION=$(awk "BEGIN { d = $END_TIME - $START_TIME; if (d < 0.0001) d = 0.001; printf \"%.3f\", d }") || DURATION="0.001"
  TOTAL_TIME=$(awk -v total="$TOTAL_TIME" -v add="$DURATION" 'BEGIN { printf "%.3f", total + add }')

  ((TOTAL_TESTS++))

  if [[ "$EXIT_CODE" -ne 0 ]]; then
    ((FAILED_TESTS++))
    {
      echo "  <testcase name=\"$TEST_NAME\" classname=\"SQLValidation\" time=\"$DURATION\">"
      echo "    <failure message=\"snow CLI failed\">$OUTPUT</failure>"
      echo "  </testcase>"
    } >> "$JUNIT_REPORT_FILE"
    return
  fi

  # Trim both actual and expected
  RESULT_TRIMMED="$(echo "$RESULT" | xargs)"
  EXPECTED_TRIMMED="$(echo "$EXPECTED" | xargs)"

  if [[ "$RESULT_TRIMMED" != "$EXPECTED_TRIMMED" ]]; then
  ((FAILED_TESTS++))
    {
      echo "  <testcase name=\"$TEST_NAME\" classname=\"SQLValidation\" time=\"$DURATION\">"
      echo "    <failure message=\"Expected '$EXPECTED_TRIMMED', got '$RESULT_TRIMMED'\">"
      echo "SQL: $SQL_QUERY"
      echo "Expected (raw): $EXPECTED"
      echo "Actual (raw): $RESULT"
      echo "Expected (trimmed): $EXPECTED_TRIMMED"
      echo "Actual (trimmed): $RESULT_TRIMMED"
      echo "    </failure>"
      echo "  </testcase>"
    } >> "$JUNIT_REPORT_FILE"

  else
    echo "  <testcase name=\"$TEST_NAME\" classname=\"SQLValidation\" time=\"$DURATION\"/>" >> "$JUNIT_REPORT_FILE"
  fi
}

# --- Fake test logic ---
if [[ "$FAKE_RUN" == true ]]; then
  MOD=$(($(date -u +%M) % 2))
  if [[ "$MOD" -eq 0 ]]; then
    run_test "🧪 Fake Failing Test" "SELECT 'unexpected'" "expected"
  else
    run_test "🧪 Fake Passing Test" "SELECT 'expected'" "expected"
  fi
fi

# --- Run actual tests from file ---
while IFS='|' read -r description sql expected; do
  if [[ -z "$description" || "$description" =~ ^# ]]; then
    ((SKIP_COUNT++))
    trimmed_desc="$(echo "${description:-Unnamed Skipped Test}" | xargs)"
    echo "  <testcase name=\"$trimmed_desc\" classname=\"SQLValidation\" time=\"0\"><skipped message=\"Commented or empty\"/></testcase>" >> "$JUNIT_REPORT_FILE"
    continue
  fi
  echo "Processing: desc='$description', sql='$sql', expected='$expected'"
  run_test "$description" "$sql" "$expected"
done < "$TEST_FILE"

# --- Close XML ---
echo "</testsuite>" >> "$JUNIT_REPORT_FILE"

# --- Patch suite summary ---
echo "JUNIT_REPORT_FILE: $JUNIT_REPORT_FILE"

#if [[ -f "$JUNIT_REPORT_FILE" ]]; then
#  sed -i '' \
#    -e "s/time=\"0.000\"/time=\"$(awk -v t="$TOTAL_TIME" 'BEGIN {printf "%.3f", t}')\"/" \
#    "$JUNIT_REPORT_FILE"
#else
#  echo "❌ JUNIT_REPORT_FILE not set or file does not exist"
#fi

TOTAL_TIME_FMT=$(printf "%.3f" "$TOTAL_TIME")

if [[ "$RUNTIME" == "macos" ]]; then

  sed -i '' \
      -e "s/time=\"0.000\"/time=\"$(awk -v t="$TOTAL_TIME" 'BEGIN {printf "%.3f", t}')\"/" \
      "$JUNIT_REPORT_FILE"

  sed -i '' \
    -e "s/tests=\"0\"/tests=\"$TOTAL_TESTS\"/" \
    -e "s/failures=\"0\"/failures=\"$FAILED_TESTS\"/" \
    -e "s/skipped=\"0\"/skipped=\"$SKIP_COUNT\"/" \
    -e "s/time=\"0.000\"/time=\"$TOTAL_TIME_FMT\"/" \
    "$JUNIT_REPORT_FILE"
else

  sed -i  \
      -e "s/time=\"0.000\"/time=\"$(awk -v t="$TOTAL_TIME" 'BEGIN {printf "%.3f", t}')\"/" \
      "$JUNIT_REPORT_FILE"

  sed -i \
    -e "s/tests=\"0\"/tests=\"$TOTAL_TESTS\"/" \
    -e "s/failures=\"0\"/failures=\"$FAILED_TESTS\"/" \
    -e "s/skipped=\"0\"/skipped=\"$SKIP_COUNT\"/" \
    -e "s/time=\"0.000\"/time=\"$TOTAL_TIME_FMT\"/" \
    "$JUNIT_REPORT_FILE"
fi

# --- Final summary ---
echo -e "\n📊 Summary: $TOTAL_TESTS total, $FAILED_TESTS failed, $SKIP_COUNT skipped."
if [[ "$FAILED_TESTS" -eq 0 ]]; then
  echo "✅ All tests passed."
else
  echo "❌ Some tests failed. See report at $JUNIT_REPORT_FILE"
fi

# --- Generate Unit History Report with  unitth.jar if available ---
mkdir -p "$REPORT_DIR"

if command -v java &>/dev/null && [[ -f unitth.jar ]]; then
  echo "🚀 Running unitth.jar ..."
 # java -Dunitth.report.dir="$REPORT_DIR" -jar unitth.jar "$JUNIT_REPORT_DIR"/*
  java \
    -Dunitth.report.dir="$REPORT_DIR" \
    -Dunitth.html.report.path="$REPORT_DIR" \
    -jar unitth.jar "$JUNIT_REPORT_DIR"/*

fi

# --- Exit with correct status ---
[[ "$FAILED_TESTS" -eq 0 ]] && exit 0 || exit 1
