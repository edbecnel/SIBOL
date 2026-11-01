#!/usr/bin/env bash
# Mandatory preflight before Firebase-connected SIBOL tests (fail-closed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

EXPECTED="demo-sibol-emulator"
PRODUCTION="sibol-286d0"

fail() {
  echo "ISOLATION PREFLIGHT FAILED: $*" >&2
  exit 1
}

if [[ "${1:-}" == "--static" ]]; then
  exec "$ROOT/shared/scripts/verify-emulator-isolation-static.sh"
fi

PROJECT="${FIREBASE_PROJECT_ID:-${GCLOUD_PROJECT:-}}"
[[ -n "$PROJECT" ]] || fail "Set FIREBASE_PROJECT_ID=${EXPECTED}."
[[ "$PROJECT" == "$EXPECTED" ]] || fail "FIREBASE_PROJECT_ID must be ${EXPECTED} (got ${PROJECT})."
[[ "$PROJECT" != "$PRODUCTION" ]] || fail "Production project id forbidden for tests."

[[ -n "${FIRESTORE_EMULATOR_HOST:-}" ]] || fail "FIRESTORE_EMULATOR_HOST must be set."
[[ -n "${FIREBASE_AUTH_EMULATOR_HOST:-}" ]] || fail "FIREBASE_AUTH_EMULATOR_HOST must be set."

case "${FIRESTORE_EMULATOR_HOST}" in
  127.0.0.1:*|localhost:*|[[]::1[]]:*) ;;
  *) fail "FIRESTORE_EMULATOR_HOST must be local (${FIRESTORE_EMULATOR_HOST})." ;;
esac

echo "OK: Firebase test preflight project=${PROJECT} firestore=${FIRESTORE_EMULATOR_HOST} auth=${FIREBASE_AUTH_EMULATOR_HOST}"
