# MVR-FIREBASE-ISOLATION-001 — Production isolation verification matrix (P0 hardening)

**Work item:** SIBOL-FIREBASE-ISOLATION-001  
**Handover UUID (Gate F remediation):** `c8e51f20-6d94-4a73-b8e1-29f0a67d35c4`  
**Production project (blocked in test/debug):** `sibol-286d0`  
**Canonical emulator project:** `demo-sibol-emulator`  
**Repository HEAD (start):** `bb7e4b93e0dd175e371de609f54ed950eb80c713`  
**Classification:** **IMPLEMENTED — ACCEPTANCE PENDING** (Gate F iOS runtime not proven this cycle; Gate G passed)

---

## Verification matrix

| Control | Implementation | Gate | Result |
|---------|----------------|------|--------|
| Flutter fail-closed init | `lib/config/firebase_isolation.dart` + `main_common.dart` | A, B | **Pass** (unit tests) |
| Android debug Firebase identity | `android/app/src/debug/google-services.json`; auto-init off | A | **Pass** (static) |
| iOS debug Firebase identity | `GoogleService-Info-Debug.plist` (template) + `select_firebase_plist.sh` omits bundle plist in Debug | A | **Pass** (static + bundle inspect) |
| Integration test preflight | `emulator_test_bootstrap.dart` + `FirebaseIsolation` | A, B | **Pass** (static/code) |
| Node/Admin SDK tests | `admin_test_isolation.mjs`, `emulator_env_guard.mjs`, runners | A, B | **Pass** (unit tests) |
| Offline queue environment | `firebaseProjectId` stamp + v2 storage prefix + quarantine | D | **Pass** (unit tests) |
| Negative security tests | `test/firebase_isolation_test.dart`, provisioning tests | B | **Pass** (Dart/Node, non-network) |
| Emulator connectivity | Canonical ports 9099/8195/5001 | C | **Pass** (ports listening at Gate F attempt) |
| iOS Debug runtime (Gate F) | `lib/main_gate_f_probe.dart` | F | **Fail / blocked** (see Gate F log) |
| Node Admin SDK network denial (Gate G) | `verify-admin-sdk-network-isolation.mjs` | G | **Pass** (carried forward; not rerun) |

---

## Gate F — Root cause and correction (2026-11-01)

### Root cause

1. **FlutterFire iOS (`firebase_core` 5.x)** registers `FLTFirebaseCorePlugin` and calls `FirebaseApp.configure()` whenever `GoogleService-Info.plist` is present in the app bundle. The Android manifest flag `firebase_core_auto_init_enabled=false` is **not** honored on iOS for this path.
2. **Packaging conflict:** `GoogleService-Info.plist` was previously listed in **Copy Bundle Resources**, allowing a gitignored **production** plist (`PROJECT_ID=sibol-286d0`) into Debug builds. Native configure then aborted in `FIRApp` before Dart `main` (crash reports e.g. `Runner-2026-11-01-094153.ips`, `094757.ips`: `SIGABRT` in `+[FIRApp configure]` via `FLTFirebaseCorePlugin.register`).
3. **Misaligned Dart/native ids (intermediate attempt):** Bundling a synthetic Debug plist while Dart used production-shaped `appId` with `demo-sibol-emulator` `projectId` increased native validation risk.

### Correction (minimal)

| File | Change |
|------|--------|
| `ios/Runner/select_firebase_plist.sh` | Debug/Profile: **remove** bundled `GoogleService-Info.plist`; Release unchanged (production plist copy). |
| `ios/Runner/GoogleService-Info-Debug.plist` | Synthetic template (`demo-sibol-emulator`, `1:demo-sibol-emulator:ios:emulator-demo`); **not** copied into Debug bundle. |
| `ios/Runner.xcodeproj/project.pbxproj` | Removed orphaned `GoogleService-Info.plist in Resources` build file (script phase is sole Debug source). |
| `lib/config/emulator_firebase_options.dart` | iOS `FirebaseOptions` match synthetic template (no `DefaultFirebaseOptions.ios` production ids). |
| `shared/scripts/verify-emulator-isolation-static.sh` | Assert Debug omits bundle plist; template must not reference `sibol-286d0`. |

### Bundle inspection (post-correction)

After `flutter build ios --simulator --debug -t lib/main_gate_f_probe.dart --dart-define=USE_FIREBASE_EMULATORS=true` (~39s):

- `build/ios/iphonesimulator/Runner.app/GoogleService-Info.plist`: **absent**
- `rg sibol-286d0` on Debug `Runner.app`: **no matches** in bundled resources

### Gate F runtime attempt (single launch, bounded — 2026-11-01 final)

#### Diagnosis of prior attempt (`/tmp/sibol-gate-f-run.log`, 2026-11-01 09:47:56)

| Check | Evidence |
|-------|----------|
| Command | `flutter run -d CF1B6EDD-BB2B-4FC9-BFC7-5506817EC01B -t lib/main_gate_f_probe.dart --dart-define=USE_FIREBASE_EMULATORS=true --no-pub` (tee to log) |
| Exit | Wrapper sent **SIGINT ~124s**; not a Flutter-reported success |
| Xcode build | **Completed** (~17.7s) |
| Installation / native start | **Partial** (Impeller log); **no** `Syncing files` / VM Service URL |
| New `.ips` | **`Runner-2026-11-01-094757.ips`** at 09:47:57 (1s after log mtime) |
| VM Service | **Never available** |
| Dart `main` | **Did not reach probe** (crash before Dart) |
| Missing markers | **Native startup crash** — `+[FIRApp configure]` at `FLTFirebaseCorePlugin.register` (bundled plist era, pre-`570785b` omit fix) |

**Classification:** **Native startup crash** (not merely missing log capture).

#### Final bounded attempt (post-`570785b`, `/tmp/gate-f-final-run.log`)

| Item | Value |
|------|--------|
| Build | `flutter build ios --simulator --debug …` **25s**; bundle **no** `GoogleService-Info.plist`; **no** `sibol-286d0` |
| Launch | `flutter run … --use-application-binary=build/ios/iphonesimulator/Runner.app` |
| Runtime wall | **~150s+** (watchdog); VM attach **failed** (`Connection refused` on 127.0.0.1, attempt #50+) |
| New `.ips` | **`Runner-2026-11-01-095303.ips`** at 09:53:03 |
| Crash site | **`FLTFirebaseCorePlugin.initializeApp`** ← Dart `Firebase.initializeApp` with `EmulatorFirebaseOptions` (synthetic `1:demo-sibol-emulator:ios:emulator-demo`) → `FIRApp addAppToAppDictionary` **SIGABRT** |
| Probe markers | **None** in Flutter log |
| Dart probe | **Did not complete** (Firebase init abort) |

**Classification:** **Dart entry-point / Firebase.initializeApp failure** on iOS (native SDK rejects synthetic options). VM Service attachment failure is a **secondary symptom** of the crash/hang.

| Item | Value |
|------|--------|
| Outcome | **FAILED VERIFICATION** — no runtime proof of Auth/Firestore/Functions on emulators |

**Correction applied this cycle:** Probe switched `debugPrint` → `print` for Gate markers (local WIP; **not** verified end-to-end). **No** Firebase config change committed (would require PA-approved iOS options strategy and a new authorized launch).

**Emulator endpoints (canonical):** Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8195`, Functions `127.0.0.1:5001` — confirmed listening.

### Gate F runtime attempt (earlier single launch, pre-final diagnosis)

| Item | Value |
|------|--------|
| Command | `flutter run -d CF1B6EDD-BB2B-4FC9-BFC7-5506817EC01B -t lib/main_gate_f_probe.dart --dart-define=USE_FIREBASE_EMULATORS=true` |
| Build phase | ~124s wall (includes Xcode rebuild ~18s) |
| Probe markers | **Not observed** |
| Outcome | Superseded by diagnosis above (`094757.ips`) |


### Gate F negative security (non-network, post-fix)

| Check | Result |
|-------|--------|
| `FirebaseIsolation.enforceConfiguration` rejects `USE_FIREBASE_EMULATORS=false` in debug | **Pass** (`test/firebase_isolation_test.dart`) |
| `assertProjectAfterInit` rejects `sibol-286d0` | **Pass** |
| Static: iOS debug template ≠ production | **Pass** |
| Static: Debug bundle omits native plist | **Pass** |

No test intentionally initializes production Firebase on iOS.

---

## Gate G status (carried forward)

**Pass** — Node Admin SDK isolation scripts reject unsafe config before Admin init; valid emulator config writes locally only with non-local TCP denied. Not rerun in Gate F remediation (unchanged by iOS plist packaging).

---

## Negative test coverage (required scenarios)

| # | Scenario | Evidence |
|---|----------|----------|
| 1 | `USE_FIREBASE_EMULATORS=false` in non-release | `FirebaseIsolation.enforceConfiguration` unit test |
| 2 | `ENVIRONMENT=production` in debug | `FirebaseIsolation.enforceConfiguration` unit test |
| 3 | Project id `sibol-286d0` in debug init | `assertProjectAfterInit` unit test |
| 4–10 | Node/offline/Android static | Prior matrix + Gate A static script |
| 7 | iOS debug production plist in **bundle** | Static + Debug bundle inspect (plist omitted) |
| 11 | iOS native bypass | Debug omits plist; Dart-only init path |

---

## Known limitations

1. **Gate F iOS runtime** — **Failed.** Omit-plist packaging works statically; iOS Firebase SDK still aborts on Dart `initializeApp` with synthetic `EmulatorFirebaseOptions` (`095303.ips`). PA must approve next iOS Firebase options strategy (without production network) before another launch.
2. **Production network proof on iOS** — Not instrumented this cycle; emulators were local; no packet capture.
3. **Release production path** — Unchanged (Release copies gitignored production plist).
4. **Application testing gate** — Remains **CLOSED** (PA decision).

---

## Production modification

**None.**
