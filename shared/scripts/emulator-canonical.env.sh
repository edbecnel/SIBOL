# Canonical emulator endpoints for SIBOL local development (matches firebase.json).
# Source from other scripts: source "$(dirname "$0")/emulator-canonical.env.sh"
set -euo pipefail
_EMULATOR_CANONICAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_CANONICAL_JSON="${_EMULATOR_CANONICAL_ROOT}/shared/emulator/canonical_ports.json"
if [[ ! -f "${_CANONICAL_JSON}" ]]; then
  echo "ERROR: missing ${_CANONICAL_JSON}" >&2
  exit 1
fi
eval "$(node -e "
const c = require('${_CANONICAL_JSON}');
const fs = c.firestore;
const auth = c.auth;
process.stdout.write([
  'export SIBOL_CANONICAL_PROJECT_ID=' + JSON.stringify(c.projectId),
  'export SIBOL_CANONICAL_FIRESTORE_PORT=' + fs.port,
  'export SIBOL_CANONICAL_AUTH_PORT=' + auth.port,
  'export SIBOL_CANONICAL_FUNCTIONS_PORT=' + c.functions.port,
  'export SIBOL_CANONICAL_UI_PORT=' + c.ui.port,
].join('\\n') + '\\n');
")"
export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-${SIBOL_CANONICAL_PROJECT_ID}}"
export FIRESTORE_EMULATOR_HOST="${FIRESTORE_EMULATOR_HOST:-127.0.0.1:${SIBOL_CANONICAL_FIRESTORE_PORT}}"
export FIREBASE_AUTH_EMULATOR_HOST="${FIREBASE_AUTH_EMULATOR_HOST:-127.0.0.1:${SIBOL_CANONICAL_AUTH_PORT}}"

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/enforce-canonical-emulator-env.sh"
