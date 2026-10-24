#!/usr/bin/env bash
# Pre-flight for SIBOL-INT-001 operator demos (emulator-only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== SIBOL-INT-001 emulator pre-flight ==="

export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-sibol-286d0}"
export FIRESTORE_EMULATOR_HOST="${FIRESTORE_EMULATOR_HOST:-127.0.0.1:8080}"
export FIREBASE_AUTH_EMULATOR_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:9099}"

if [[ "${FIRESTORE_EMULATOR_HOST}" != *"127.0.0.1"* && "${FIRESTORE_EMULATOR_HOST}" != *"localhost"* ]]; then
  echo "ERROR: FIRESTORE_EMULATOR_HOST must point at local emulators (${FIRESTORE_EMULATOR_HOST})."
  exit 1
fi

for port in 8080 9099 5001; do
  if ! nc -z 127.0.0.1 "$port" 2>/dev/null; then
    echo "WARN: Nothing listening on 127.0.0.1:${port}. Start: ./shared/scripts/start-demo-emulators.sh"
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
npm run seed:emulator -- --dry-run --confirm-emulator-demo 2>/dev/null || {
  echo "NOTE: dry-run seed requires password env vars (see runbook)."
}

if [[ -n "${MISSING:-}" ]]; then
  exit 1
fi
echo "Pre-flight complete."
