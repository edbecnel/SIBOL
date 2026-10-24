#!/usr/bin/env bash
# Run automated regression suites relevant to SIBOL-INT-001 (local only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== shared/functions (unit + Firestore integration) ==="
cd shared/functions && npm test

echo "=== shared/firestore-rules-test ==="
cd "$ROOT/shared/firestore-rules-test" && npm test

echo "=== shared/migration ==="
cd "$ROOT/shared/migration" && npm test

echo "=== shared/provisioning ==="
cd "$ROOT/shared/provisioning" && npm test

echo "=== shared/integration (prototype smoke) ==="
cd "$ROOT/shared/integration" && npm test

echo "=== sibol_app flutter test ==="
cd "$ROOT/sibol_app" && flutter test

echo "=== sibol_app flutter analyze ==="
cd "$ROOT/sibol_app" && flutter analyze

echo "INT-001 automated verification complete."
