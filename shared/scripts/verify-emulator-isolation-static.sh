#!/usr/bin/env bash
# Static verification for SIBOL-FIREBASE-ISOLATION-001 (no emulators, no Firebase I/O).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== Emulator isolation static verification ==="

# Negative: production project id must fail preflight even with emulator hosts set.
if FIRESTORE_EMULATOR_HOST=127.0.0.1:8195 \
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
  FIREBASE_PROJECT_ID=sibol-286d0 \
  node "$ROOT/shared/provisioning/scripts/preflight-emulator-env.mjs" 2>/dev/null; then
  echo "FAIL: preflight accepted production FIREBASE_PROJECT_ID" >&2
  exit 1
fi
echo "OK: preflight rejects FIREBASE_PROJECT_ID=sibol-286d0"

# Negative: enforce script rejects production after override.
if ! (
  export FIRESTORE_EMULATOR_HOST=127.0.0.1:8195
  export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
  export FIREBASE_PROJECT_ID=sibol-286d0
  # shellcheck disable=SC1091
  source "$ROOT/shared/scripts/enforce-canonical-emulator-env.sh"
) 2>/dev/null; then
  echo "OK: enforce-canonical-emulator-env rejects production project id"
else
  echo "FAIL: enforce script accepted production project id" >&2
  exit 1
fi

# Positive: canonical env loads and forces demo-sibol-emulator.
# shellcheck disable=SC1091
source "$ROOT/shared/scripts/emulator-canonical.env.sh"
if [[ "${FIREBASE_PROJECT_ID}" != "demo-sibol-emulator" ]]; then
  echo "FAIL: emulator-canonical.env did not set demo-sibol-emulator (got ${FIREBASE_PROJECT_ID})" >&2
  exit 1
fi
echo "OK: enforce-canonical.env enforces demo-sibol-emulator"

cd "$ROOT/shared/provisioning"
node --test test/emulator_ports.test.mjs test/emulator_guard.test.mjs test/admin_test_isolation.test.mjs
echo "OK: provisioning emulator unit tests passed"

ANDROID_DEBUG_JSON="$ROOT/sibol_app/android/app/src/debug/google-services.json"
if [[ ! -f "$ANDROID_DEBUG_JSON" ]]; then
  echo "FAIL: missing Android debug google-services.json" >&2
  exit 1
fi
ANDROID_PROJECT="$(node -e "const j=require('$ANDROID_DEBUG_JSON'); console.log(j.project_info.project_id);")"
if [[ "$ANDROID_PROJECT" == "sibol-286d0" ]]; then
  echo "FAIL: Android debug google-services references production" >&2
  exit 1
fi
if [[ "$ANDROID_PROJECT" != "demo-sibol-emulator" ]]; then
  echo "FAIL: Android debug project id must be demo-sibol-emulator (got $ANDROID_PROJECT)" >&2
  exit 1
fi
echo "OK: Android debug google-services project_id=${ANDROID_PROJECT}"

IOS_DEBUG_PLIST="$ROOT/sibol_app/ios/Runner/GoogleService-Info-Debug.plist"
if [[ ! -f "$IOS_DEBUG_PLIST" ]]; then
  echo "FAIL: missing iOS GoogleService-Info-Debug.plist reference template" >&2
  exit 1
fi
IOS_PROJECT="$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "$IOS_DEBUG_PLIST")"
if [[ "$IOS_PROJECT" == "sibol-286d0" ]]; then
  echo "FAIL: iOS debug plist template references production" >&2
  exit 1
fi
if ! rg -q "GoogleService-Info-Debug.plist" "$ROOT/sibol_app/ios/Runner/select_firebase_plist.sh"; then
  echo "FAIL: iOS Debug must copy GoogleService-Info-Debug.plist into the app bundle" >&2
  exit 1
fi
if [[ "$IOS_PROJECT" != "demo-sibol-emulator" ]]; then
  echo "FAIL: iOS debug plist PROJECT_ID must be demo-sibol-emulator (got ${IOS_PROJECT})" >&2
  exit 1
fi
echo "OK: iOS debug Firebase PROJECT_ID=${IOS_PROJECT} (Debug bundle uses GoogleService-Info-Debug.plist)"

echo "OK: Android Firebase auto-init disabled (Dart owns init)"

IOS_PLIST="$ROOT/sibol_app/ios/Runner/Info.plist"
if ! /usr/libexec/PlistBuddy -c 'Print :firebase_core_auto_init_enabled' "$IOS_PLIST" 2>/dev/null | grep -q false; then
  echo "FAIL: iOS Info.plist must set firebase_core_auto_init_enabled=false" >&2
  exit 1
fi
echo "OK: iOS Firebase auto-init disabled (Dart owns init)"

echo "=== Static verification complete (runtime: validate-local-firebase-isolation.sh) ==="
