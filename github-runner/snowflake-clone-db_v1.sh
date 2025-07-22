#!/bin/bash

# -----------------------------------------------------------------------------
# Usage:
# ./snowflake-clone-db_v1.sh --SOURCE_DATABASE=MD_TEST --SOURCE_SCHEMA=IOT_REF_20250711 --CLONE_DATABASE=MD_TEST --CLONE_SCHEMA=IOT_CLONE --RELEASE_NUM=42
# -----------------------------------------------------------------------------

# --- Default values ---
CONNECTION_NAME="sfseeurope-demo_ci_user"

# Parse arguments
for ARG in "$@"; do
  case $ARG in
    --SOURCE_DATABASE=*)
      SOURCE_DATABASE="${ARG#*=}"
      ;;
    --SOURCE_SCHEMA=*)
      SOURCE_SCHEMA="${ARG#*=}"
      ;;
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

# Validate inputs
if [[ -z "$SOURCE_DATABASE" || -z "$SOURCE_SCHEMA" || -z "$CLONE_DATABASE" || -z "$CLONE_SCHEMA" || -z "$RELEASE_NUM" ]]; then
  echo "❌ Missing required arguments."
  exit 1
fi

CLONE_SCHEMA_WITH_RELEASE="${CLONE_SCHEMA}_${RELEASE_NUM}"

# --- Execution ---
echo "🔗 Connecting to Snowflake and starting the clone process..."
echo "📋 Cloning $SOURCE_DATABASE.$SOURCE_SCHEMA → $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE"


snowsql -c $CONNECTION_NAME -q "
  CREATE OR REPLACE SCHEMA $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE CLONE $SOURCE_DATABASE.$SOURCE_SCHEMA;
"

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Success! SCHEMA '${SOURCE_DATABASE}.${SOURCE_SCHEMA}' was cloned to '${CLONE_DATABASE}.${CLONE_SCHEMA_WITH_RELEASE}'."
else
  echo "❌ An error occurred. Please review the output from SnowSQL above."
  exit 1
fi