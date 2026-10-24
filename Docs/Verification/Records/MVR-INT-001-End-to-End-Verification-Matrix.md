# MVR-INT-001 — End-to-end verification matrix

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
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
| 10 | Full rules regression | `shared/firestore-rules-test` (96) | Auto PASS |
| 11 | Functions regression | `shared/functions` (48) | Auto PASS |
| 12 | Flutter unit/widget | `flutter test` (84) | Auto PASS |
| 13 | Android emulator operator E2E | Runbook §6 | NR — environment has emulator; operator attestation pending |
| 14 | iOS Simulator operator E2E | `flutter devices` | NR — no Simulator runtime; physical device only |

Formal production MVR-REG-001 remains **not complete** (deploy gate unchanged).
