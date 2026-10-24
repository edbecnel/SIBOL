#!/usr/bin/env bash
# Start Auth, Firestore, and Functions emulators for SIBOL-INT-001 demonstrations.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/shared/functions"
npm run build
cd "$ROOT"
export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-sibol-286d0}"
firebase emulators:start \
  --config "$ROOT/firebase.emulator-demo.json" \
  --only auth,firestore,functions \
  "${@}"
