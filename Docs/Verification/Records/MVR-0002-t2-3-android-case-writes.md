# MVR-0002 — T2-3 Android manual QA (case create/edit)

> **Handover:** `a4e71d39-2c86-4b05-91f3-6d80a2e47c19` (rules deploy); **live writes** require separate PA authorization after this walkthrough is prepared  
> **Firestore rules:** T2-3 hardened rules deployed 2026-10-21 (ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc`)  
> **Status:** **Prepared — not executed** by EA

## Preconditions

- Android emulator or device with `sibol_app` built against `main` at `f1f7c76` or later.
- Demo passwords from password manager into shell (values **not** recorded here):

  ```bash
  export SIBOL_DEMO_PASSWORD_BARANGAY='…'
  export SIBOL_DEMO_PASSWORD_TEEN='…'
  export SIBOL_DEMO_PASSWORD_MOPH='…'
  ```

- Fictional-data banner visible; no real PII.

## Sequential walkthrough

| Step | Action | Expected result | Record observation |
|------|--------|-----------------|-------------------|
| 1 | Launch app; sign in as `barangay.demo@sibol.local` | Barangay home loads; case list visible; fictional banner shown | Pass / Fail + notes |
| 2 | Open `demo-case-002` (or any listed demo case) | Case detail shows demo name, status, notes; no error state | |
| 3 | Scroll to follow-up timeline on a case with follow-ups (e.g. `demo-case-002`) | At least one follow-up row with date/notes | |
| 4 | Tap **+** / create case; enter fictional name (≥2 chars), age 13–19, barangay, status, notes | Form validates; save succeeds | **Only when PA authorizes live writes** |
| 5 | Return to list; open the new case | Fields match entered fictional data | |
| 6 | Edit case (pencil); change notes; save | Success snackbar/navigation; detail shows new notes | |
| 7 | Force-close app; reopen; open same case | Edited notes persist | |
| 8 | Sign out; sign in as `teen.demo@sibol.local` | Teen home only; no case list or case routes | |
| 9 | Sign out; sign in as `moph.demo@sibol.local` | MOPH dashboard; no barangay case CRUD | |
| 10 | (Optional) Attempt to infer reporting UI on case detail | No client path to set `reportStatus` to submitted; reporting remains server workflow | |

## Execution record

| Field | Value |
|-------|--------|
| Tester | |
| Date | |
| App build / commit | |
| Outcome | Pending |
