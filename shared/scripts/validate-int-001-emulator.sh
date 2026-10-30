#!/usr/bin/env bash
# Pre-flight for SIBOL-INT-001 operator demos (emulator-only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== SIBOL-INT-001 emulator pre-flight ==="

# shellcheck disable=SC1091
source "$ROOT/shared/scripts/emulator-canonical.env.sh"

if [[ "${FIRESTORE_EMULATOR_HOST}" != *"127.0.0.1"* && "${FIRESTORE_EMULATOR_HOST}" != *"localhost"* ]]; then
  echo "ERROR: FIRESTORE_EMULATOR_HOST must point at local emulators (${FIRESTORE_EMULATOR_HOST})."
  exit 1
fi

for port in "${SIBOL_CANONICAL_FIRESTORE_PORT}" "${SIBOL_CANONICAL_AUTH_PORT}" "${SIBOL_CANONICAL_FUNCTIONS_PORT}"; do
  if ! nc -z 127.0.0.1 "$port" 2>/dev/null; then
    echo "WARN: Nothing listening on 127.0.0.1:${port}. Start emulators from repo root:"
    echo "  firebase emulators:start --project demo-sibol-emulator --only auth,firestore,functions"
    MISSING=1
  else
    echo "OK: port ${port} open"
  fi
done

ENV_FILE="${SIBOL_EMULATOR_ENV_FILE:-$ROOT/.env.emulator.local}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "WARN: Missing ${ENV_FILE}. Copy from .env.emulator.example before seeding."
else
  echo "OK: found ${ENV_FILE}"
fi

cd "$ROOT/shared/provisioning"
node scripts/preflight-emulator-env.mjs --check-reachable

if [[ -n "${MISSING:-}" ]]; then
  exit 1
fi
echo "Pre-flight complete."
