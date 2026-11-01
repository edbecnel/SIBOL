#!/usr/bin/env bash
# Flutter unit/widget tests with Firebase isolation static checks (Gate A/B subset).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

"$ROOT/shared/scripts/verify-emulator-isolation-static.sh"

cd "$ROOT/sibol_app"
flutter test test/firebase_isolation_test.dart test/env_config_test.dart test/emulator_config_test.dart test/offline_environment_isolation_test.dart test/offline_sync_service_test.dart "$@"
