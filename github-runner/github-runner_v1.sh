#!/bin/bash

# -----------------------------------------------------------------------------
# Usage:
# -----------------------------------------------------------------------------

set -e

# --- Prepare Snowflake config and key files ---
SNOW_DIR="$HOME/.snowflake"
mkdir -p "$SNOW_DIR"


# Validate presence of base64 secrets env vars
if [[ -z "$SNOW_CONFIG_B64" || -z "$SNOW_KEY_B64" ]]; then
  echo "❌ Missing required environment variables SNOW_CONFIG_B64 and/or SNOW_KEY_B64."
  exit 1
fi

echo "SNOW_CONFIG_B64: $SNOW_CONFIG_B64"

# Debug: Show first lines of decoded SNOW_CONFIG_B64 without extra prefix to avoid decode errors
echo "Preview of decoded SNOW_CONFIG_B64:"
echo "$SNOW_CONFIG_B64" | base64 --decode | head

echo "Decoding Snowflake config..."
echo "$SNOW_CONFIG_B64" | base64 --decode > "$SNOW_DIR/config.toml"
chmod 600 "$SNOW_DIR/config.toml"

# TODO
#echo "🔐 Decoding Snowflake private key..."
#echo "$SNOW_KEY_B64" | base64 --decode > "$SNOW_DIR/snowflake_private_key.pem"
#chmod 600 "$SNOW_DIR/snowflake_private_key.pem"

#
## temp
## --- Export Variables Configuration ---
## Source database and schema configuration
#export database="DataOps"
#echo "SOURCE_DATABASE: $SOURCE_DATABASE"
#
#export schema="IOT_DOMAIN_v001"
#echo "SOURCE_SCHEMA: $SOURCE_SCHEMA"
#
## Clone database and schema configuration
#export CLONE_DATABASE="DataOps"
#echo "CLONE_DATABASE: $CLONE_DATABASE"
#
#export CLONE_SCHEMA="IOT_CLONE"
#echo "CLONE_SCHEMA: $CLONE_SCHEMA"
#
#
## Release and project configuration
#export RELEASE_NUM="-v001"
#echo "RELEASE_NUM: $RELEASE_NUM"
#
#export PROJECT_KEY="mother-of-all-Projects"
#echo "PROJECT_KEY: $PROJECT_KEY"
#
#
# Snowflake connection configuration
# Fix for workflow bug where CONNECTION_NAME gets set to SNOW_CONFIG_B64
#if [[ ${#CONNECTION_NAME} -gt 100 ]]; then
#  echo "⚠️  WARNING: CONNECTION_NAME appears to be base64 encoded (length: ${#CONNECTION_NAME})"
#  echo "⚠️  Overriding with correct connection name"
#  export CONNECTION_NAME="sfseeurope-svc_cicd"
#fi
#echo "CONNECTION_NAME: $CONNECTION_NAME"
