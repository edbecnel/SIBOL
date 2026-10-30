# MVR-CASE-LIFECYCLE-001 — Verification matrix

**Work item:** SIBOL-CASE-LIFECYCLE-001  
**Environment:** Isolated Firestore/Auth emulator (`firebase.emulator-functions-test.json`, project `demo-sibol-coord-fn`)

| ID | Requirement | Method | Result |
|----|-------------|--------|--------|
| V1 | Open case from acknowledged assistance | `openBarangayCaseFromAssistance.test.mjs` | **Pass** |
| V2 | Idempotent / concurrent open → one case | Same + concurrent test | **Pass** |
| V3 | Close blocked with active referral | `transitionBarangayCaseStatus.test.mjs` | **Pass** |
| V4 | Full coordination + resolve/close + audit | `case_lifecycle_flow.test.mjs` | **Pass** |
| V5 | Cross-hospital MOPH denied | `case_lifecycle_flow.test.mjs` | **Pass** |
| V6 | Flutter open-case UI wired | Code inspection + `dart analyze` | **Pass** (no analyzer errors on scoped paths) |
| V7 | Barangay coordination response panel wired | Code inspection | **Pass** |
| V8 | Client lifecycle field writes blocked | Rules in `firestore.rules` | **Not re-run** (rules unit harness not executed this tranche) |
| V9 | Offline follow-ups unchanged | Code inspection | **Not re-run** (no regression test executed) |
| V10 | Manual emulator UI walkthrough | [Walkthrough](./SIBOL_CASE_LIFECYCLE_001_EMULATOR_WALKTHROUGH.md) | **Prepared — not executed** |

**Runner command:**

```bash
cd shared/functions && node scripts/run-case-lifecycle-integration-tests.mjs
```

Last execution: **7/7** tests passed (automated emulator integration).
