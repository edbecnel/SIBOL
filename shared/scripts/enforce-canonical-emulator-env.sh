#!/usr/bin/env bash
# Fail-closed: canonical local emulator project id only (never production sibol-286d0).
set -euo pipefail

_ENFORCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_CANONICAL_JSON="${_ENFORCE_ROOT}/shared/emulator/canonical_ports.json"

if [[ ! -f "${_CANONICAL_JSON}" ]]; then
  echo "ERROR: missing ${_CANONICAL_JSON}" >&2
  exit 1
fi

read -r CANONICAL_PROJECT PRODUCTION_FORBIDDEN <<<"$(node -e "
const c = require('${_CANONICAL_JSON}');
process.stdout.write(c.projectId + ' sibol-286d0');
")"

fail() {
  echo "EMULATOR PROJECT ENFORCEMENT FAILED: $*" >&2
  exit 1
}

if [[ "${FIREBASE_PROJECT_ID:-}" == "${PRODUCTION_FORBIDDEN}" ]]; then
  fail "FIREBASE_PROJECT_ID must not be production ${PRODUCTION_FORBIDDEN}. Use ${CANONICAL_PROJECT} for local emulators."
fi

if [[ "${GCLOUD_PROJECT:-}" == "${PRODUCTION_FORBIDDEN}" ]]; then
  fail "GCLOUD_PROJECT must not be production ${PRODUCTION_FORBIDDEN} when using emulator hosts."
fi

if [[ -n "${FIREBASE_PROJECT_ID:-}" && "${FIREBASE_PROJECT_ID}" != "${CANONICAL_PROJECT}" ]]; then
  fail "FIREBASE_PROJECT_ID must be ${CANONICAL_PROJECT} (got ${FIREBASE_PROJECT_ID}). Unset conflicting shell overrides or fix .env.emulator.local."
fi

export FIREBASE_PROJECT_ID="${CANONICAL_PROJECT}"
export GCLOUD_PROJECT="${CANONICAL_PROJECT}"
