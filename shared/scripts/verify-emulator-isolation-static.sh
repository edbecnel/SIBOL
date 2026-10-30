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
node --test test/emulator_ports.test.mjs test/emulator_guard.test.mjs
echo "OK: provisioning emulator unit tests passed"

echo "=== Static verification complete (runtime emulator checks still pending) ==="
