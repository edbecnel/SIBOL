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
flutter test integration_test/barangay_assistance_identity_device_test.dart \
  -d "$DEVICE" \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true \
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$BARANGAY_PASSWORD"
