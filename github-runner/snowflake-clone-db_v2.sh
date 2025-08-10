#!/bin/bash

# -----------------------------------------------------------------------------
# Usage:
# ./snowflake-clone-db_v2.sh \
#   --SOURCE_DATABASE=MD_TEST \
#   --SOURCE_SCHEMA=IOT_REF_20250711 \
#   --CLONE_DATABASE=MD_TEST \
#   --CLONE_SCHEMA=IOT_CLONE \
#   --RELEASE_NUM=42 \
#   --CONNECTION_NAME=ci_user_test
#
# ./snowflake-clone-db_v2.sh --SOURCE_DATABASE=DataOps --SOURCE_SCHEMA=IOT_RAW_v001 --CLONE_DATABASE=DataOps --CLONE_SCHEMA=IOT_CLONE --RELEASE_NUM=82 --CONNECTION_NAME=sfseeurope-svc_cicd
# -----------------------------------------------------------------------------

set -e

# --- Default values ---

# Parse arguments
for ARG in "$@"; do
  case $ARG in
    --SOURCE_DATABASE=*) SOURCE_DATABASE="${ARG#*=}" ;;
    --SOURCE_SCHEMA=*) SOURCE_SCHEMA="${ARG#*=}" ;;
    --CLONE_DATABASE=*) CLONE_DATABASE="${ARG#*=}" ;;
    --CLONE_SCHEMA=*) CLONE_SCHEMA="${ARG#*=}" ;;
    --RELEASE_NUM=*) RELEASE_NUM="${ARG#*=}" ;;
    --CONNECTION_NAME=*) CONNECTION_NAME="${ARG#*=}" ;;
    *)
      echo "❌ Unknown argument: $ARG"
      exit 1
      ;;
  esac
done

# Validate inputs
if [[ -z "$SOURCE_DATABASE" || -z "$SOURCE_SCHEMA" || -z "$CLONE_DATABASE" || -z "$CLONE_SCHEMA" || -z "$RELEASE_NUM" || -z "$CONNECTION_NAME" ]]; then
  echo "❌ Missing required arguments."
  echo "Required: --SOURCE_DATABASE --SOURCE_SCHEMA --CLONE_DATABASE --CLONE_SCHEMA --RELEASE_NUM --CONNECTION_NAME"
  exit 1
fi

CLONE_SCHEMA_WITH_RELEASE="${CLONE_SCHEMA}_${RELEASE_NUM}"


# --- Execution ---
echo "🔗 Connecting to Snowflake and starting the clone process..."
echo "📋 Cloning $SOURCE_DATABASE.$SOURCE_SCHEMA → $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE using connection: $CONNECTION_NAME"

set +e
snow sql -c "$CONNECTION_NAME" -q "
CREATE OR REPLACE SCHEMA $CLONE_DATABASE.$CLONE_SCHEMA_WITH_RELEASE CLONE $SOURCE_DATABASE.$SOURCE_SCHEMA;
"
STATUS=$?
set -e

if [ $STATUS -eq 0 ]; then
  echo "✅ Success! SCHEMA '${SOURCE_DATABASE}.${SOURCE_SCHEMA}' was cloned to '${CLONE_DATABASE}.${CLONE_SCHEMA_WITH_RELEASE}'."
else
  echo "❌ An error occurred. Please review the output above."
  exit 1
fi
