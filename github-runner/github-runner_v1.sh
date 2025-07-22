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


# Debug: Show first lines of decoded SNOW_CONFIG_B64 without extra prefix to avoid decode errors
echo "🔍 Preview of decoded SNOW_CONFIG_B64:"
echo "$SNOW_CONFIG_B64" | base64 --decode | head

echo "🔐 Decoding Snowflake config..."
echo "$SNOW_CONFIG_B64" | base64 --decode | head > "$SNOW_DIR/config.toml"
chmod 600 "$SNOW_DIR/config.toml"

echo "🔐 Decoding Snowflake private key..."
echo "$SNOW_KEY_B64" | base64 --decode > "$SNOW_DIR/snowflake_private_key.pem"
chmod 600 "$SNOW_DIR/snowflake_private_key.pem"

# --- Override private_key_file path in config.toml ---
PRIVATE_KEY_PATH="$SNOW_DIR/snowflake_private_key.pem"
if grep -q '^private_key_file\s*=' "$SNOW_DIR/config.toml"; then
  sed -i.bak "s|^private_key_file\s*=.*|private_key_file = \"$PRIVATE_KEY_PATH\"|" "$SNOW_DIR/config.toml"
else
  echo "private_key_file = \"$PRIVATE_KEY_PATH\"" >> "$SNOW_DIR/config.toml"
fi