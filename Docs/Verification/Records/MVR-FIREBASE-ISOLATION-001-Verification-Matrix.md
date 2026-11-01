# MVR-FIREBASE-ISOLATION-001 — Production isolation verification matrix (P0)

**Work item:** SIBOL-FIREBASE-ISOLATION-001  
**Closeout handover UUID:** `e5b7c219-4d83-4f6a-9c10-2b75e804a631`  
**Prior Gate F UUIDs:** `c8e51f20-…`, `a1e94c72-…`  
**Production project (blocked in test/debug):** `sibol-286d0`  
**Canonical emulator namespace:** `demo-sibol-emulator`  
**Repository HEAD (start):** `bf1564c6303d1fce918d93dad1def522c3e3f255`  
**Historical integrity:** [MVR-FIREBASE-PROD-INTEGRITY-001](MVR-FIREBASE-PROD-INTEGRITY-001.md), [MVR-FIREBASE-PROD-INTEGRITY-002](MVR-FIREBASE-PROD-INTEGRITY-002.md) — **closed; not repeated this cycle**

---

## Final development / production separation architecture

| Layer | Development / test | Production release |
|--------|-------------------|---------------------|
| Dart init | `FirebaseIsolation` fail-closed + `EmulatorFirebaseOptions` when emulators on | `DefaultFirebaseOptions` only in authorized release |
| Android native | `src/debug/google-services.json` → `demo-sibol-emulator`; auto-init off | Release `google-services.json` (gitignored) |
| iOS native | Bundled `GoogleService-Info-Debug.plist` → `PROJECT_ID=demo-sibol-emulator`; registered FlutterFire iOS `GOOGLE_APP_ID` (same mobile app registration as production console, **not** production project id in plist) | Gitignored `GoogleService-Info.plist` (`sibol-286d0`) |
| Node / Admin tests | `preflight-sibol-firebase-tests.sh`, guards, Gate G network deny | Provisioning scripts separate |
| Offline queue | `firebaseProjectId` stamp + cross-env rejection | Unchanged |

**Separate Firebase cloud project for development:** **Not created** (no PO authorization to register new cloud resources). iOS uses **FlutterFire-registered iOS app credentials** with **emulator canonical project id** in Debug plist/Dart. **Recommendation:** PA may later add a dedicated non-production Firebase project and re-run `flutterfire configure` for cleaner credential separation.

---

## Verification matrix (final)

| Gate | Scope | Result | Evidence |
|------|--------|--------|----------|
| 1 — Config integrity | Static Android/iOS/Debug bundle | **Pass** | `verify-emulator-isolation-static.sh` 2026-11-01; Debug `Runner.app` contains `GoogleService-Info.plist` with `PROJECT_ID=demo-sibol-emulator` |
| 2 — Negative isolation | Dart + Node unit negatives | **Pass** | `run_isolated_flutter_tests.sh` (22 tests); provisioning emulator tests |
| 3 — Android runtime | Emulator project + Auth/Firestore/Functions | **Pass (carried forward)** | [MVR-CONSENT-REFERRAL-001](MVR-CONSENT-REFERRAL-001-Verification-Matrix.md) Gates A–D device pass 2026-11-01 |
| 4 — iOS simulator runtime | Init + emulator routing | **Pass (init + Auth + local Firestore)** | See § iOS Gate 4 log below |
| 5 — Offline queue | Cross-environment replay | **Pass (carried forward)** | Gate 2 offline tests |
| 6 — Node/Admin SDK | Pre-init rejection + network deny | **Pass** | `verify-admin-sdk-network-isolation.mjs` (Gate G) |

---

## iOS Gate 4 — runtime evidence (2026-11-01)

**Build:** `flutter build ios --simulator --debug -t lib/main_gate_f_probe.dart --dart-define=USE_FIREBASE_EMULATORS=true` — **~35s**  
**Bundle:** `build/ios/iphonesimulator/Runner.app/GoogleService-Info.plist` → `PROJECT_ID=demo-sibol-emulator`, registered `GOOGLE_APP_ID` (no `sibol-286d0` in plist)

**Single launch:** `flutter run -d CF1B6EDD-BB2B-4FC9-BFC7-5506817EC01B … --use-application-binary=build/ios/iphonesimulator/Runner.app` — **~120s** bounded  
**Log:** `/tmp/gate4-ios-probe.log`

```
flutter: SIBOL_GATE_F_PROJECT_ID=demo-sibol-emulator
flutter: SIBOL_GATE_F_EMULATOR_HOST=localhost
flutter: SIBOL_GATE_F_PORTS=auth:9099,firestore:8195,functions:5001
… permission-denied @ L776 (catch-all firestore.rules on emulator)
```

| Check | Result |
|-------|--------|
| Native abort / new `.ips` after 09:53 | **No** |
| VM Service | **Available** (log shows DevTools URL) |
| Effective Firebase project | **`demo-sibol-emulator`** |
| Auth emulator | **Pass** (`createUserWithEmailAndPassword` before Firestore call) |
| Firestore emulator | **Pass** (local rules `permission-denied`, not production timeout) |
| Functions routing | **Configured** in `initializeSibolFirebase()` (ports logged; no production URL) |

**Packaging fix:** `select_firebase_plist.sh` installs to `$(BUILT_PRODUCTS_DIR)/$(WRAPPER_NAME)/GoogleService-Info.plist`; build phase moved after **Resources**.

---

## Node / Admin SDK (Gate 6 / Gate G)

**Script:** `shared/provisioning/scripts/verify-admin-sdk-network-isolation.mjs` (+ `network-deny-nonlocal.mjs`, worker)  
**Result:** All cases `REJECTED_BEFORE_ADMIN_INIT` or `LOCAL_EMULATOR_OK`; **no production network**.

---

## Network protection evidence

| Mechanism | Evidence |
|-----------|----------|
| Flutter `FirebaseIsolation` | Unit tests Gate 2 |
| Test preflight | `preflight-sibol-firebase-tests.sh` rejects `sibol-286d0` |
| Admin SDK Gate G | Process-level non-local TCP deny + guards before init |
| iOS Debug bundle | No production `PROJECT_ID` in committed Debug plist |

---

## Negative isolation tests (summary)

Production project id, missing emulator hosts, `USE_FIREBASE_EMULATORS=false` in debug, offline cross-project replay, Admin SDK production id — **fail closed** (Gate 2 + Gate 6). **No production network requests** in this cycle.

---

## Known limitations

1. **iOS client credentials** use FlutterFire-registered iOS app id (production Firebase **console registration**); runtime **project id** and **emulator hosts** are development-only. A dedicated non-production Firebase project would remove console-registration overlap (PA authorization required to create).
2. **Gate F probe Firestore write** to `_gate_f_probe` is denied by catch-all rules; emulator response confirms local routing (probe updated to record `rules-denied-local` for future runs).
3. **Application testing gate** remains **CLOSED** until PA accepts this matrix.

---

## Production modification

**None.**

---

## Acceptance classification

**IMPLEMENTED — ACCEPTANCE PENDING (PA sign-off)**

All isolation gates pass with bounded runtime evidence on iOS (init, Auth, local Firestore). Recommend PA accept or request dedicated Firebase dev project registration for credential hygiene.

**Can SIBOL development or automated testing accidentally reach production Firebase?**

**No**, for configured development and automated test entry points: fail-closed Dart guards, separated Debug native configs, emulator preflight, offline stamping, and Node Gate G network denial block production project selection and non-local Firebase endpoints before meaningful I/O. Residual risk is misconfiguration bypassing these layers (e.g. manual Release build with live credentials); that path is outside debug/test automation scope.
