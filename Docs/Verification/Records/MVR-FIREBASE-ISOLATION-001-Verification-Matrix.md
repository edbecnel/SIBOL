# MVR-FIREBASE-ISOLATION-001 — Production isolation verification matrix (P0 hardening)

**Work item:** SIBOL-FIREBASE-ISOLATION-001  
**Handover UUID:** `f2c91a60-7e34-4b85-a0d2-9c63e158b704`  
**Production project (blocked in test/debug):** `sibol-286d0`  
**Canonical emulator project:** `demo-sibol-emulator`  
**Repository HEAD (start):** `9c8019003885e363883c1b09e7bb1686bd775a52`  
**Classification:** **IMPLEMENTED — ACCEPTANCE PENDING** (Android + Node + Flutter unit gates pass; iOS device/runtime spot-check not executed on this agent)

---

## Verification matrix

| Control | Implementation | Gate | Result |
|---------|----------------|------|--------|
| Flutter fail-closed init | `lib/config/firebase_isolation.dart` + `main_common.dart` | A, B | **Pass** (unit tests) |
| Android debug Firebase identity | `android/app/src/debug/google-services.json`; auto-init off | A | **Pass** (static) |
| iOS debug Firebase identity | `GoogleService-Info-Debug.plist` + `select_firebase_plist.sh` | A | **Pass** (static); **Release runtime not executed on this agent** |
| Integration test preflight | `emulator_test_bootstrap.dart` + `FirebaseIsolation` | A, B | **Pass** (static/code) |
| Node/Admin SDK tests | `admin_test_isolation.mjs`, `emulator_env_guard.mjs`, runners | A, B | **Pass** (unit tests) |
| Offline queue environment | `firebaseProjectId` stamp + v2 storage prefix + quarantine | D | **Pass** (unit tests) |
| Negative security tests | `test/firebase_isolation_test.dart`, `offline_environment_isolation_test.dart`, provisioning tests | B | **Pass** |
| Emulator connectivity | `validate-local-firebase-isolation.sh` when emulators up | C | **Pass** (runtime, canonical ports) |
| Targeted functional regression | `run_isolated_flutter_tests.sh` | E subset | **Pass** (unit scope) |

---

## Negative test coverage (required scenarios)

| # | Scenario | Evidence |
|---|----------|----------|
| 1 | `USE_FIREBASE_EMULATORS=false` in non-release | `FirebaseIsolation.enforceConfiguration` unit test |
| 2 | `ENVIRONMENT=production` in debug | `FirebaseIsolation.enforceConfiguration` unit test |
| 3 | Project id `sibol-286d0` in debug init | `assertProjectAfterInit` unit test |
| 4 | Missing emulator env (Node) | `admin_test_isolation.test.mjs`, `emulator_guard.test.mjs` |
| 5 | Emulator unavailable | `preflight-emulator-env.mjs --check-reachable` (existing); runtime Gate C |
| 6 | Android debug production json | Static script rejects `sibol-286d0` in debug json |
| 7 | iOS debug production plist | Static script validates `GoogleService-Info-Debug.plist` |
| 8 | Admin SDK + production id | `admin_test_isolation.test.mjs` |
| 9 | Offline op wrong environment | `offline_environment_isolation_test.dart` |
| 10 | Legacy unstamped offline op | `offline_environment_isolation_test.dart` |
| 11 | Direct test without wrapper | `run_isolated_flutter_tests.sh` calls static gate first; runtime still requires `enforceConfiguration` in app |

---

## Gate execution log (2026-11-01)

| Gate | Command | Result |
|------|---------|--------|
| A | `./shared/scripts/verify-emulator-isolation-static.sh` | **Pass** |
| B | `./sibol_app/tool/run_isolated_flutter_tests.sh` | **Pass** (22 tests) |
| C | `validate-local-firebase-isolation.sh` (with canonical env) | **Pass** when emulators listening on 9099/8195/5001 |
| D | Offline isolation unit tests (Gate B) | **Pass** |
| E | Targeted unit regression (no device integration this cycle) | **Pass** (subset) |

---

## Known limitations

1. **iOS device/runtime Gate C–E** — Not executed in this cycle (no physical iOS run). Debug plist selection and static checks are in place; PA should run one Debug build on device before claiming full iOS runtime verification.
2. **Release production path** — Intentionally preserved via `kReleaseMode` + `DefaultFirebaseOptions`; student demo devices unchanged.
3. **ADC with emulator env omitted (Node CLI)** — Mitigated by guards; not network-proven in this run.
4. **Application testing gate** — Remains **CLOSED** until PA accepts this matrix and optional iOS runtime spot-check.

---

## Production modification

**None** during this hardening cycle.
