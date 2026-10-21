# MVR-0003 — SIBOL-DEMO-002 Teen assistance (Android emulator, live Firebase)

> **Work item:** SIBOL-DEMO-002  
> **Source:** PA manual emulator verification report to Engineering Agent (2026-10-21)  
> **Firebase project:** `sibol-286d0` (rules + index deployed per handover `d5b8e31a-…`)  
> **Status:** **Executed — all steps Pass** (operator-confirmed; PA-guided)

## Scope

Manual end-to-end verification on **Android emulator** against **live** Firestore (not the rules unit-test emulator). Distinct from automated `flutter test` (52) and `shared/firestore-rules-test` (23).

**Not in scope:** Physical Android device (Product Owner phone) — pending.

## Test fixture (fictional)

| Field | Value |
|-------|--------|
| Account | `teen.demo@sibol.local` |
| Category | Counseling referral (demo) |
| Submitted (local) | 2026-10-21, ~21:12 Philippine time |
| Status | Submitted |
| Description (summary) | Fictional student requesting information about available counseling services for a school demonstration. |

No real patient or identifying information entered. Passwords not recorded.

## Sequential results

| # | Check | Result |
|---|--------|--------|
| 1 | SIBOL launched successfully | **Pass** |
| 2 | Teen demo authentication succeeded | **Pass** |
| 3 | Teen dashboard: **New support request** and **My requests** visible | **Pass** |
| 4 | New support request form: selectable categories | **Pass** |
| 5 | Fictional counseling referral submitted successfully (live Firebase write) | **Pass** |
| 6 | Request details: category, description, date, reference, Submitted status | **Pass** |
| 7 | My Requests: exactly one submitted request listed | **Pass** |
| 8 | After close/reopen app: Teen auth and request listing persist | **Pass** |
| 9 | After restart: request details still correct | **Pass** |
| 10 | Barangay demo auth; dashboard shows six fictional cases incl. **SIBOL QA Test**; **New case** button | **Pass** |

## Execution record

| Field | Value |
|-------|--------|
| Environment | Android emulator |
| Firebase | Live `sibol-286d0` post-DEMO-002 rules deploy |
| Tester role | Operator (PA-guided walkthrough) |
| Date | 2026-10-21 |
| Outcome | **Pass (10/10)** |

## Related records

- [SIBOL_DEMO_002_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_002_EXECUTION_REPORT.md)
- [firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json](../Artifacts/firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json)
