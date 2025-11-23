#!/bin/sh

# Firebase設定ファイルを環境に応じて切り替えるスクリプト

FLAVOR=$1

if [ -z "$FLAVOR" ]; then
  echo "Error: Flavor not specified"
  exit 1
fi

RUNNER_DIR="${SRCROOT}/Runner"
SOURCE_FILE=""

if [ "$FLAVOR" == "dev" ]; then
  SOURCE_FILE="${RUNNER_DIR}/GoogleService-Info-Dev.plist"
elif [ "$FLAVOR" == "prod" ]; then
  SOURCE_FILE="${RUNNER_DIR}/GoogleService-Info-Prod.plist"
else
  echo "Error: Unknown flavor: $FLAVOR"
  exit 1
fi

TARGET_FILE="${RUNNER_DIR}/GoogleService-Info.plist"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: Source file not found: $SOURCE_FILE"
  exit 1
fi

cp "$SOURCE_FILE" "$TARGET_FILE"
echo "Copied $SOURCE_FILE to $TARGET_FILE"
