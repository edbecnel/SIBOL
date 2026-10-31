# MVR-CONSENT-REFERRAL-001 — Verification matrix

**Work item:** SIBOL-CONSENT-REFERRAL-001

| ID | Criterion | Method | Result |
|----|-----------|--------|--------|
| V1 | Legacy free-text referral rejected | `consent_referral.test.mjs` | **Pass** |
| V2 | Minimum structured referral | Functions integration | **Pass** |
| V3 | Authorization approve + authorized referral (gate on) | Functions integration | **Pass** |
| V4 | Decline + minimum referral | Functions integration | **Pass** |
| V5 | Legal gate off blocks authorized referral | Functions integration | **Pass** |
| V6 | Withdrawal blocks authorized use | Functions integration | **Pass** |
| V7 | Case lifecycle + structured response | `case_lifecycle_flow.test.mjs` | **Pass** |
| V8 | Authz regression structured payload | `createCoordinationReferral.authz.test.mjs` | **Not re-run in this session** |
| V9 | Firestore rules disclosure paths | Rules tests | **Not extended in this session** |
| V10 | Flutter emulator E2E walkthrough | Manual device | **BLOCKED / PENDING** — depends on role-home (CASE-LIFECYCLE V10) |
| V11 | Authorized path with legal gate off in UI | Manual | **BLOCKED** until legal activation approved |

**Classification:** IMPLEMENTED — ACCEPTANCE PENDING (V10/V11).
