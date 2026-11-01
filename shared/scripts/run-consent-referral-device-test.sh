#!/usr/bin/env bash
# Runs CONSENT-REFERRAL-001 Android device integration tests against canonical emulators.
# Does not start Firebase or the Android emulator. Does not log passwords.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUTH_EXPORT="${SIBOL_AUTH_EXPORT_FOR_DEVICE_TEST:-$ROOT/.firebase-qa-backups/pre-identity-backfill-20261026-145500/auth_export/accounts.json}"
DEVICE="${SIBOL_DEVICE_ID:-emulator-5554}"
ADB="${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
NODE="$ROOT/shared/provisioning/scripts/emulator-account-password-from-export.mjs"

if [[ ! -f "$AUTH_EXPORT" ]]; then
  echo "Missing auth export: $AUTH_EXPORT" >&2
  exit 1
fi

ENV_LOCAL="$ROOT/.env.emulator.local"
if [[ -f "$ENV_LOCAL" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_LOCAL"
  set +a
fi
if [[ ! -x "$ADB" && ! -f "$ADB" ]]; then
  ADB="$(command -v adb || true)"
fi
if [[ -z "$ADB" || ! -f "$ADB" ]]; then
  echo "adb not found; set ANDROID_HOME or install Android SDK platform-tools." >&2
  exit 1
fi

read_password() {
  node "$NODE" "$AUTH_EXPORT" "$1"
}

resolve_demo_password() {
  local env_primary=$1
  local env_fallback=$2
  local email=$3
  if [[ -n "${!env_primary:-}" ]]; then
    printf '%s' "${!env_primary}"
    return
  fi
  if [[ -n "${!env_fallback:-}" ]]; then
    printf '%s' "${!env_fallback}"
    return
  fi
  read_password "$email"
}

TEEN_PASSWORD="$(resolve_demo_password SIBOL_EMULATOR_PASSWORD_TEEN SIBOL_DEMO_PASSWORD_TEEN teen.demo@sibol.local)"
BARANGAY_PASSWORD="$(resolve_demo_password SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF SIBOL_DEMO_PASSWORD_BARANGAY barangay.demo@sibol.local)"
MOPH_PASSWORD="$(resolve_demo_password SIBOL_EMULATOR_PASSWORD_MOPH_STAFF SIBOL_DEMO_PASSWORD_MOPH moph.demo@sibol.local)"

cd "$ROOT/sibol_app"
flutter pub get

COMMON_ARGS=(
  -d "$DEVICE"
  --dart-define=USE_FIREBASE_EMULATORS=true
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
  --dart-define=SIBOL_DEVICE_TEST_TEEN_PASSWORD="$TEEN_PASSWORD"
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$BARANGAY_PASSWORD"
  --dart-define=SIBOL_DEVICE_TEST_MOPH_PASSWORD="$MOPH_PASSWORD"
)

"$ADB" -s "$DEVICE" reverse tcp:8195 tcp:8195 >/dev/null 2>&1 || true
"$ADB" -s "$DEVICE" reverse tcp:9099 tcp:9099 >/dev/null 2>&1 || true
"$ADB" -s "$DEVICE" reverse tcp:5001 tcp:5001 >/dev/null 2>&1 || true

echo "=== emulator_role_auth_device_test ==="
flutter test integration_test/emulator_role_auth_device_test.dart "${COMMON_ARGS[@]}"

echo "=== consent_referral_emulator_device_test (gate off) ==="
flutter test integration_test/consent_referral_emulator_device_test.dart "${COMMON_ARGS[@]}"

if [[ "${SIBOL_RUN_CONSENT_LEGAL_GATE_DEVICE_TEST:-}" == "1" ]]; then
  echo "=== consent_referral legal gate ON (requires Functions SIBOL_DISCLOSURE_LEGAL_GATE=true) ==="
  flutter test integration_test/consent_referral_legal_gate_device_test.dart \
    "${COMMON_ARGS[@]}" \
    --dart-define=SIBOL_DISCLOSURE_LEGAL_GATE=true
fi

if [[ "${SIBOL_RUN_CONSENT_OFFLINE_DEVICE_TEST:-}" == "1" ]]; then
  echo "=== consent referral offline queue (airplane mode) ==="
  "$ADB" -s "$DEVICE" shell cmd connectivity airplane-mode enable
  sleep 2
  flutter test integration_test/consent_referral_offline_device_test.dart "${COMMON_ARGS[@]}"
  "$ADB" -s "$DEVICE" shell cmd connectivity airplane-mode disable
fi

echo "Device acceptance script completed."
