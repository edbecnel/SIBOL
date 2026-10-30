#!/usr/bin/env bash
# SIBOL-FIREBASE-ISOLATION-001 — fail-closed local Firebase isolation gate.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

STATIC_ONLY=false
if [[ "${1:-}" == "--static" ]]; then
  STATIC_ONLY=true
fi

if [[ "$STATIC_ONLY" == "true" ]]; then
  exec "$ROOT/shared/scripts/verify-emulator-isolation-static.sh"
fi

EXPECTED_PROJECT="demo-sibol-emulator"
AUTH_PORT=9099
FS_PORT=8195
FN_PORT=5001

fail() {
  echo "ISOLATION GATE FAILED: $*" >&2
  exit 1
}

port_open() {
  nc -z 127.0.0.1 "$1" 2>/dev/null
}

if ! port_open "$FS_PORT"; then
  fail "Firestore emulator not listening on 127.0.0.1:${FS_PORT}"
fi
if ! port_open "$AUTH_PORT"; then
  fail "Auth emulator not listening on 127.0.0.1:${AUTH_PORT}"
fi
if ! port_open "$FN_PORT"; then
  fail "Functions emulator not listening on 127.0.0.1:${FN_PORT}"
fi

PROJECT="${FIREBASE_PROJECT_ID:-${GCLOUD_PROJECT:-}}"
if [[ -z "$PROJECT" ]]; then
  fail "Set FIREBASE_PROJECT_ID=${EXPECTED_PROJECT} before Firebase-dependent tests."
fi
if [[ "$PROJECT" != "$EXPECTED_PROJECT" ]]; then
  fail "FIREBASE_PROJECT_ID must be ${EXPECTED_PROJECT} (got ${PROJECT})."
fi
if [[ "$PROJECT" == "sibol-286d0" ]]; then
  fail "Production project id must not be used for local emulator work."
fi

FS_HOST="${FIRESTORE_EMULATOR_HOST:-}"
AUTH_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-}"
[[ -n "$FS_HOST" ]] || fail "FIRESTORE_EMULATOR_HOST must be set (e.g. 127.0.0.1:${FS_PORT})."
[[ -n "$AUTH_HOST" ]] || fail "FIREBASE_AUTH_EMULATOR_HOST must be set (e.g. 127.0.0.1:${AUTH_PORT})."

echo "OK: isolation gate — project=${PROJECT} auth=${AUTH_HOST} firestore=${FS_HOST} functions=127.0.0.1:${FN_PORT}"
