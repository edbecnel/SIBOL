#!/usr/bin/env bash
# Load optional local env and seed emulator demonstration data.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="${SIBOL_EMULATOR_ENV_FILE:-$ROOT/.env.emulator.local}"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi
export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-sibol-286d0}"
export FIRESTORE_EMULATOR_HOST="${FIRESTORE_EMULATOR_HOST:-127.0.0.1:8080}"
export FIREBASE_AUTH_EMULATOR_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:9099}"
cd "$ROOT/shared/provisioning"
npm run seed:emulator -- --confirm-emulator-demo "$@"
if [[ "${SIBOL_SKIP_SEED_VERIFY:-}" != "1" ]]; then
  npm run verify:emulator || {
    echo "Seed verify failed."
    exit 1
  }
fi
