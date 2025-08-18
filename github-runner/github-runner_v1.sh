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
