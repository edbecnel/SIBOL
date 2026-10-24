# MVR-INT-001 — End-to-end verification matrix

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
> **Amendment UUID:** `e4b7c291-5a63-4d08-9f12-6c83a0e745bd` — demo org ids `barangay03`, `hospital01`  
> **Continuation UUID:** `a6d2c941-7e35-4b80-9f26-c103e8d754ab` (AGENT-002)  
> **Work item:** SIBOL-INT-001

Legend: **Auto** = emulator automated test; **Manual** = operator UI walkthrough; **NR** = not run in this execution.

| # | Journey / control | Evidence | Result |
|---|-------------------|----------|--------|
| 1 | Central org create / list | `admin.operations.test.mjs` | Auto PASS |
| 2 | Org admin staff lifecycle | `admin.operations.test.mjs` | Auto PASS |
| 3 | Teen registration callables | `teen.registration.test.mjs` | Auto PASS |
| 4 | Teen assistance create (rules) | `assistance_requests.rules.test.mjs` | Auto PASS |
| 5 | Barangay ack + referral + MOPH read | `prototype_journey.smoke.mjs` | Auto PASS |
| 6 | Cross-org denial | `org_scoped_security.rules.test.mjs`, smoke | Auto PASS |
| 7 | Central admin no case read | smoke | Auto PASS |
| 8 | Teen isolation | smoke | Auto PASS |
| 9 | Coordination referral authz | `createCoordinationReferral.authz.test.mjs` | Auto PASS |
| 10 | Full rules regression | `shared/firestore-rules-test` (95 tests, serial) | Auto PASS (AGENT-002) |
| 11 | Functions regression | `shared/functions` (49) | Auto PASS (AGENT-002) |
| 15 | Emulator seed + verify | `seed-emulator-demo.sh`, `verify:emulator` | Auto PASS (AGENT-002) |
| 12 | Flutter unit/widget | `flutter test` (84) | Auto PASS |
| 13 | Android emulator operator E2E | Runbook §6 scenarios A–F | Manual **NR** (AGENT-002: APK build PASS; `flutter run` not attested) |
| 14 | iOS Simulator operator E2E | `flutter devices` | Manual **NR** (simulator not booted; wireless iPhone only) |

Formal production MVR-REG-001 remains **not complete** (deploy gate unchanged).
