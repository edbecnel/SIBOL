# SIBOL-PROTOTYPE-VERIFY-001 — Execution report

**Starting HEAD:** `e08393d`  
**Ending HEAD:** `622b31a`  
**Production deploy:** Not authorized

## 1. Emulator port conflict — resolved

- Added [`firebase.emulator-smoke-isolated.json`](../../firebase.emulator-smoke-isolated.json) with Auth **9315**, Firestore **8325** (see [`shared/emulator/smoke_isolated_ports.json`](../../shared/emulator/smoke_isolated_ports.json)).
- `shared/integration` smoke defaults to isolated config; canonical **8215/9199** and operator **8195/9099** stacks untouched.
- Shared [`smoke_harness.mjs`](../../shared/integration/test/smoke_harness.mjs) for single seed + aligned `firebase-admin` SDK.

## 2. INT-001 scenarios A–F (automated)

| Scenario | Result | Evidence |
|----------|--------|----------|
| A — Central org list | **PASS** | `int001_scenarios.smoke.mjs` |
| B — Org admin memberships | **PASS** | `int001_scenarios.smoke.mjs` |
| C — Teen server submit + client create denied | **PASS** | `int001_scenarios.smoke.mjs` |
| D — Barangay ack/referral/history | **PASS** | `prototype_journey.smoke.mjs` |
| E — MOPH referral read | **PASS** | `prototype_journey.smoke.mjs` |
| F — Security spot checks | **PASS** | `prototype_journey.smoke.mjs` (teen isolation, central case deny) |

`cd shared/integration && npm test` — **8/8 PASS**

## 3. Teen assistance authorization

**Finding:** Clients could create `teenAssistanceRequests` directly, bypassing idempotent server path.

**Resolution:** `allow create: if false` on `teenAssistanceRequests`; production path is `regSubmitTeenAssistanceRequest` only. Rules regression updated; smoke asserts `permission-denied` on client `addDoc`.

## 4. Offline MVR O-03–O-06

| ID | Result | Notes |
|----|--------|-------|
| O-03 | **NOT RUN** | App restart + queue recovery requires device/simulator session (not executed in this environment). |
| O-04 | **PASS (server)** | Idempotent replay in `assistance_submission.test.mjs` + Scenario C; device reconnect **NOT RUN**. |
| O-05 | **NOT RUN (device)** | Cross-account isolation on shared hardware not exercised; storage keys are per-`ownerUid` by design. |
| O-06 | **NOT RUN (device)** | UI delivery messaging verified by code review; no false-success snackbars on offline save paths. |

## 5. Platform builds

| Platform | Result |
|----------|--------|
| Android `flutter build apk --debug` | **PASS** (`app-debug.apk`) |
| iOS `pod install` + `flutter build ios --debug --no-codesign` | **PASS** (`Runner.app`) |

## 6. Regression

| Suite | Result |
|-------|--------|
| `shared/functions` `npm test` | **60/60 PASS** |
| `shared/firestore-rules-test` | **98/98 PASS** |
| `sibol_app` `flutter test` | **86/86 PASS** |
| `shared/integration` smoke | **8/8 PASS** |

## 7. PO demonstration readiness

**Ready** for emulator-backed demonstration with Functions + isolated or canonical emulators. **Manual** operator UI walkthrough (runbook §6) still recommended for final PO sign-off. Offline device scenarios O-03, O-05, O-06 remain **NOT RUN** on hardware.
