#!/bin/bash

# -----------------------------------------------------------------------------
# Usage:
# ./snowflake-drop-clone-db_v1.sh --CLONE_DATABASE=MD_TEST --CLONE_SCHEMA=IOT_CLONE --RELEASE_NUM=42
# -----------------------------------------------------------------------------

# --- Default values ---
CONNECTION_NAME="sfseeurope-demo_ci_user"
# Parse named parameters
for ARG in "$@"; do
  case $ARG in
    --CLONE_DATABASE=*)
      CLONE_DATABASE="${ARG#*=}"
      ;;
    --CLONE_SCHEMA=*)
      CLONE_SCHEMA="${ARG#*=}"
      ;;
    --RELEASE_NUM=*)
      RELEASE_NUM="${ARG#*=}"
      ;;
    *)
      echo "❌ Unknown argument: $ARG"
      exit 1
      ;;
  esac
done

# Validate input
if [[ -z "$CLONE_DATABASE" || -z "$CLONE_SCHEMA" || -z "$RELEASE_NUM" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 --CLONE_DATABASE=... --CLONE_SCHEMA=... --RELEASE_NUM=..."
  exit 1
fi

CLONE_SCHEMA_WITH_RELEASE="${CLONE_SCHEMA}_${RELEASE_NUM}"

# --- Execution ---
echo "🔗 Connecting to Snowflake and starting the DROP process..."
echo "📋 drop schema $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE"


snowsql -c $CONNECTION_NAME -q "
  DROP SCHEMA IF EXISTS $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE;
"

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Success! DROP SCHEMA '${CLONE_DATABASE}.${CLONE_SCHEMA_WITH_RELEASE}'."
else
  echo "❌ An error occurred. Please review the output from SnowSQL above."
  exit 1
fi