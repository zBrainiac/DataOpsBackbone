#!/bin/bash

# -----------------------------------------------------------------------------
# Usage:
# ./snowflake-drop-clone-db_v2.sh \
#   --CLONE_DATABASE=DataOps \
#   --CLONE_SCHEMA=IOT_CLONE \
#   --RELEASE_NUM=42 \
#   --CONNECTION_NAME=ci_user_test
#
# ./snowflake-drop-clone-db_v2.sh --CLONE_DATABASE=DataOps --CLONE_SCHEMA=IOT_CLONE --RELEASE_NUM=42 --CONNECTION_NAME=sfseeurope-svc_cicd_user
# -----------------------------------------------------------------------------

set -e

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
    --CONNECTION_NAME=*)
      CONNECTION_NAME="${ARG#*=}"
      ;;
    *)
      echo "❌ Unknown argument: $ARG"
      echo "Usage: $0 --CLONE_DATABASE=... --CLONE_SCHEMA=... --RELEASE_NUM=... --CONNECTION_NAME=..."
      exit 1
      ;;
  esac
done

# Validate input
if [[ -z "$CLONE_DATABASE" || -z "$CLONE_SCHEMA" || -z "$RELEASE_NUM" || -z "$CONNECTION_NAME" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 --CLONE_DATABASE=... --CLONE_SCHEMA=... --RELEASE_NUM=... --CONNECTION_NAME=..."
  exit 1
fi

CLONE_SCHEMA_WITH_RELEASE="${CLONE_SCHEMA}_${RELEASE_NUM}"

# --- Execution ---
echo "Connecting to Snowflake and starting the DROP process..."
echo "Executing: DROP SCHEMA IF EXISTS $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE using connection: $CONNECTION_NAME"

set +e
snow sql -c "$CONNECTION_NAME" -q "
DROP SCHEMA IF EXISTS $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE;
"
STATUS=$?
set -e

if [ $STATUS -eq 0 ]; then
  echo "✅ Success! SCHEMA '${CLONE_DATABASE}.${CLONE_SCHEMA_WITH_RELEASE}' was dropped."
else
  echo "❌ An error occurred. Please review the output above."
  exit 1
fi
