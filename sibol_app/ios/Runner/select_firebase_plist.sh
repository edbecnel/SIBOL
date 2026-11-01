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
  echo "Firebase plist for Release: $(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "${DEST}")"
else
  # Debug/Profile: omit GoogleService-Info.plist so FlutterFire does not call
  # FirebaseApp.configure() at plugin registration (firebase_core 5.x ignores
  # firebase_core_auto_init_enabled on iOS). Dart [EmulatorFirebaseOptions] init only.
  rm -f "${DEST}"
  echo "Firebase plist omitted for ${CONFIGURATION} (Dart emulator init; template GoogleService-Info-Debug.plist is not bundled)"
fi
