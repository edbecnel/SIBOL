#!/usr/bin/env bash
# Select Firebase plist for Debug/Profile vs Release (SIBOL-FIREBASE-ISOLATION-001).
set -euo pipefail

SRC="${SRCROOT}/Runner"
DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

if [[ "${CONFIGURATION}" == "Release" ]]; then
  if [[ ! -f "${SRC}/GoogleService-Info.plist" ]]; then
    echo "error: Release builds require ${SRC}/GoogleService-Info.plist (production credentials; gitignored on emulator-only machines)." >&2
    exit 1
  fi
  cp "${SRC}/GoogleService-Info.plist" "${DEST}"
else
  cp "${SRC}/GoogleService-Info-Debug.plist" "${DEST}"
fi

echo "Firebase plist for ${CONFIGURATION}: $(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "${DEST}")"
