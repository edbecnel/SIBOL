#!/usr/bin/env bash
# Start Auth, Firestore, and Functions emulators for SIBOL-INT-001 demonstrations.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/shared/functions"
npm run build
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/shared/scripts/emulator-canonical.env.sh"
firebase emulators:start \
  --project "${FIREBASE_PROJECT_ID}" \
  --only auth,firestore,functions \
  "${@}"
