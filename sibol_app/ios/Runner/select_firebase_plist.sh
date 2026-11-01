#!/usr/bin/env bash
# Select Firebase plist for Debug/Profile vs Release (SIBOL-FIREBASE-ISOLATION-001).
set -euo pipefail

SRC="${SRCROOT}/Runner"
# Install into the finished .app bundle (TARGET_BUILD_DIR path alone is not always packaged).
DEST="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/GoogleService-Info.plist"
mkdir -p "$(dirname "${DEST}")"

if [[ "${CONFIGURATION}" == "Release" ]]; then
  if [[ ! -f "${SRC}/GoogleService-Info.plist" ]]; then
    echo "error: Release builds require ${SRC}/GoogleService-Info.plist (production credentials; gitignored on emulator-only machines)." >&2
    exit 1
  fi
  cp "${SRC}/GoogleService-Info.plist" "${DEST}"
  echo "Firebase plist for Release: $(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "${DEST}")"
else
  DEBUG_PLIST="${SRC}/GoogleService-Info-Debug.plist"
  if [[ ! -f "${DEBUG_PLIST}" ]]; then
    echo "error: Debug/Profile builds require ${DEBUG_PLIST}" >&2
    exit 1
  fi
  cp "${DEBUG_PLIST}" "${DEST}"
  PROJECT_ID="$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "${DEST}")"
  if [[ "${PROJECT_ID}" == "sibol-286d0" ]]; then
    echo "error: Debug Firebase plist must not reference production project" >&2
    exit 1
  fi
  if [[ "${PROJECT_ID}" != "demo-sibol-emulator" ]]; then
    echo "error: Debug Firebase plist PROJECT_ID must be demo-sibol-emulator (got ${PROJECT_ID})" >&2
    exit 1
  fi
  echo "Firebase plist for ${CONFIGURATION}: PROJECT_ID=${PROJECT_ID}"
fi
