#!/bin/bash

# -----------------------------------------------------------------------------
# DataOps Pipeline Master Script
# This script sets export variables and executes the DataOps pipeline scripts in sequence
# -----------------------------------------------------------------------------
# Usage:
# ./dataops-pipeline.sh
# 
# You can override variables by setting them as environment variables before running:
# export SOURCE_DATABASE=MY_DB && ./dataops-pipeline.sh
# -----------------------------------------------------------------------------

set -e

# --- Export Variables Configuration ---
# Source database and schema configuration
export SOURCE_DATABASE="${SOURCE_DATABASE:-DataOps}"
export SOURCE_SCHEMA="${SOURCE_SCHEMA:-IOT_DOMAIN_v001}"

# Clone database and schema configuration  
export CLONE_DATABASE="${CLONE_DATABASE:-DataOps}"
export CLONE_SCHEMA="${CLONE_SCHEMA:-IOT_CLONE}"

# Release and project configuration
export RELEASE_NUM="${RELEASE_NUM:-v001}"
export PROJECT_KEY="${PROJECT_KEY:-mother-of-all-Projects}"

# Snowflake connection configuration
export CONNECTION_NAME="${CONNECTION_NAME:-sfseeurope-svc_cicd}"

# Additional configuration for dependency extraction - will be set after runtime detection

# Additional configuration for SQL validation
export TEST_FILE="${TEST_FILE:-./github-runner/tests.sqltest}"
export FAKE_RUN="${FAKE_RUN:-false}"

# Workspace configuration




# --- Runtime detection ---
if [[ -f /.dockerenv ]] || grep -qE '/docker/|/lxc/' /proc/1/cgroup 2>/dev/null; then
  echo "Running inside Docker container"
  export BASE_WORKSPACE="${BASE_WORKSPACE:-/home/docker/actions-runner/_work}"
  export OUTPUT_DIR="${OUTPUT_DIR:-/home/docker/actions-runner/_work/${PROJECT_KEY}/${PROJECT_KEY}}"
elif [[ "$(uname)" == "Darwin" ]]; then
 echo "Running on macOS"
   export BASE_WORKSPACE="${BASE_WORKSPACE:-/Users/mdaeppen/workspace}"
   export OUTPUT_DIR="${OUTPUT_DIR:-${BASE_WORKSPACE}/${PROJECT_KEY}}"
else
  echo "Unknown system, defaulting to current dir"
  export BASE_WORKSPACE="$(pwd)"
  export OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)}"
fi


echo "  Starting DataOps Pipeline"
echo "=================================================="
echo "   Configuration:"
echo "   SOURCE_DATABASE: $SOURCE_DATABASE"
echo "   SOURCE_SCHEMA: $SOURCE_SCHEMA"
echo "   CLONE_DATABASE: $CLONE_DATABASE" 
echo "   CLONE_SCHEMA: $CLONE_SCHEMA"
echo "   RELEASE_NUM: $RELEASE_NUM"
echo "   PROJECT_KEY: $PROJECT_KEY"
echo "   CONNECTION_NAME: $CONNECTION_NAME"
echo "   OUTPUT_DIR: $OUTPUT_DIR"
echo "   TEST_FILE: $TEST_FILE"
echo "   BASE_WORKSPACE: $BASE_WORKSPACE"
echo "=================================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Step 1: Extract Dependencies ---
echo "Step 1: Extracting Snowflake schema dependencies..."
if [[ -f "$SCRIPT_DIR/snowflake-extract-dependencies_v1.sh" ]]; then
    "$SCRIPT_DIR/snowflake-extract-dependencies_v1.sh" \
        --SOURCE_DATABASE="$SOURCE_DATABASE" \
        --SOURCE_SCHEMA="$SOURCE_SCHEMA" \
        --OUTPUT_DIR="$OUTPUT_DIR" \
        --CONNECTION_NAME="$CONNECTION_NAME"
    echo "✅ Dependencies extraction completed"
else
    echo "❌ Error: snowflake-extract-dependencies_v1.sh not found"
    exit 1
fi
echo ""

# --- Step 2: Clone Database ---
echo "Step 2: Cloning database schema..."
if [[ -f "$SCRIPT_DIR/snowflake-clone-db_v2.sh" ]]; then
    "$SCRIPT_DIR/snowflake-clone-db_v2.sh" \
        --SOURCE_DATABASE="$SOURCE_DATABASE" \
        --SOURCE_SCHEMA="$SOURCE_SCHEMA" \
        --CLONE_DATABASE="$CLONE_DATABASE" \
        --CLONE_SCHEMA="$CLONE_SCHEMA" \
        --RELEASE_NUM="$RELEASE_NUM" \
        --CONNECTION_NAME="$CONNECTION_NAME"
    echo "✅ Database cloning completed"
else
    echo "❌ Error: snowflake-clone-db_v2.sh not found"
    exit 1
fi
echo ""

# --- Step 3: Deploy Structure ---
echo "Step 3: Deploying database structure..."
if [[ -f "$SCRIPT_DIR/snowflake-deploy-structure_v2.sh" ]]; then
    "$SCRIPT_DIR/snowflake-deploy-structure_v2.sh" \
        --PROJECT_KEY="$PROJECT_KEY" \
        --CLONE_DATABASE="$CLONE_DATABASE" \
        --CLONE_SCHEMA="$CLONE_SCHEMA" \
        --RELEASE_NUM="$RELEASE_NUM" \
        --CONNECTION_NAME="$CONNECTION_NAME" \
        --BASE_WORKSPACE="$BASE_WORKSPACE"
    echo "✅ Structure deployment completed"
else
    echo "❌ Error: snowflake-deploy-structure_v2.sh not found"
    exit 1
fi
echo ""

# --- Step 4: SQL Validation ---
echo "Step 4: Running SQL validation tests..."
if [[ -f "$SCRIPT_DIR/sql_validation_v4.sh" ]]; then
    "$SCRIPT_DIR/sql_validation_v4.sh" \
        --CLONE_SCHEMA="$CLONE_SCHEMA" \
        --CLONE_DATABASE="$CLONE_DATABASE" \
        --RELEASE_NUM="$RELEASE_NUM" \
        --CONNECTION_NAME="$CONNECTION_NAME" \
        --TEST_FILE="$TEST_FILE" \
        --FAKE_RUN="$FAKE_RUN"
    echo "✅ SQL validation completed"
else
    echo "❌ Error: sql_validation_v4.sh not found"
    exit 1
fi
echo ""

# --- Step 5: Drop Clone Schema ---
echo "Step 5: Dropping clone schema..."
# if [[ -f "$SCRIPT_DIR/snowflake-drop-clone-db_v2.sh" ]]; then
#     "$SCRIPT_DIR/snowflake-drop-clone-db_v2.sh" \
#         --CLONE_DATABASE="$CLONE_DATABASE" \
#         --CLONE_SCHEMA="$CLONE_SCHEMA" \
#         --RELEASE_NUM="$RELEASE_NUM" \
#         --CONNECTION_NAME="$CONNECTION_NAME"
#     echo "✅ Clone schema cleanup completed"
# else
#     echo "❌ Error: snowflake-drop-clone-db_v2.sh not found"
#     exit 1
# fi
echo ""

echo "DataOps Pipeline completed successfully!"
echo "=================================================="
echo "📊 Summary:"
echo "   ✅ Dependencies extracted"
echo "   ✅ Database cloned"
echo "   ✅ Structure deployed"
echo "   ✅ SQL validation executed"
echo "   ✅ Clone schema cleaned up"
echo "=================================================="
