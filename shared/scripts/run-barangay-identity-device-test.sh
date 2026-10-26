#!/usr/bin/env bash
# Runs Android device integration test against the *existing* SIBOL emulator stack.
# Does not start Firebase or Android emulators.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUTH_EXPORT="${SIBOL_AUTH_EXPORT_FOR_DEVICE_TEST:-$ROOT/.firebase-qa-backups/pre-identity-backfill-20261026-145500/auth_export/accounts.json}"
DEVICE="${SIBOL_DEVICE_ID:-emulator-5554}"

if [[ ! -f "$AUTH_EXPORT" ]]; then
  echo "Missing auth export: $AUTH_EXPORT" >&2
  exit 1
fi

BARANGAY_PASSWORD="$(
  node "$ROOT/shared/provisioning/scripts/emulator-account-password-from-export.mjs" \
    "$AUTH_EXPORT" \
    "barangay.demo@sibol.local"
)"

cd "$ROOT/sibol_app"
flutter pub get
FLUTTER_TEST_ARGS=(
  -d "$DEVICE"
  --dart-define=USE_FIREBASE_EMULATORS=true
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$BARANGAY_PASSWORD"
)

flutter test integration_test/barangay_assistance_identity_device_test.dart \
  "${FLUTTER_TEST_ARGS[@]}"

flutter test integration_test/barangay_incoming_request_cards_device_test.dart \
  "${FLUTTER_TEST_ARGS[@]}"

# Offline card test reinstalls the app and clears auth; run only when explicitly requested:
# SIBOL_RUN_OFFLINE_CARD_DEVICE_TEST=1 ./shared/scripts/run-barangay-identity-device-test.sh
if [[ "${SIBOL_RUN_OFFLINE_CARD_DEVICE_TEST:-}" == "1" ]]; then
  ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
  "$ADB" -s "$DEVICE" shell cmd connectivity airplane-mode enable
  sleep 2
  flutter test integration_test/barangay_incoming_request_cards_offline_device_test.dart \
    "${FLUTTER_TEST_ARGS[@]}"
  "$ADB" -s "$DEVICE" shell cmd connectivity airplane-mode disable
fi
