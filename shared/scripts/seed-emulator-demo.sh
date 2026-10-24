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
# shellcheck disable=SC1091
source "$ROOT/shared/scripts/emulator-canonical.env.sh"
cd "$ROOT/shared/provisioning"
npm run seed:emulator -- --confirm-emulator-demo "$@"
if [[ "${SIBOL_SKIP_SEED_VERIFY:-}" != "1" ]]; then
  npm run verify:emulator || {
    echo "Seed verify failed."
    exit 1
  }
fi
