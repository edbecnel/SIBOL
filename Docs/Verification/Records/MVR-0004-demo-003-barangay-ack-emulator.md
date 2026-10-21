# MVR-0004 — SIBOL-DEMO-003 Barangay acknowledgment (Android emulator, live Firebase)

> **Work item:** SIBOL-DEMO-003  
> **Source:** PA operator-guided manual QA report to Engineering Agent (2026-10-21, ~22:31 PHT)  
> **Firebase project:** `sibol-286d0` (ruleset `251bc159-…`; indexes per post-DEMO-003 metadata)  
> **Status:** **Executed — all steps Pass (14/14)** (operator-confirmed; PA-guided)

## Scope

Manual end-to-end verification on **Android emulator** against **live** Firestore after DEMO-003 rules/index deploy. Distinct from automated `flutter test` and `shared/firestore-rules-test`.

**Not in scope:** Physical Android device (Product Owner phone); visual re-check of corrected teen detail footer copy (see defect note below).

## Test fixture (fictional)

| Field | Value |
|-------|--------|
| Teen account | `teen.demo@sibol.local` |
| Barangay account | `barangay.demo@sibol.local` |
| Assigned site | `Barangay Tres, Balingasag` |
| New request (DEMO-003 flow) | Document ID `OHRs1h1Us6HrxSzflubR` (PA reference; live data not modified by EA) |
| New request category | Counseling referral (fictional) |
| Submitted (local) | 2026-10-21, ~22:19 PHT |
| Acknowledged (local) | 2026-10-21, ~22:25 PHT |
| Prior request (pre-DEMO-003) | Remains **Submitted**; not visible in Barangay incoming (no `barangay` field) |

No real patient or identifying information entered. Passwords not recorded.

## Sequential results

| # | Check | Result |
|---|--------|--------|
| 1 | SIBOL launched successfully on Android emulator | **Pass** |
| 2 | Barangay demo authentication succeeded | **Pass** |
| 3 | Barangay dashboard: six fictional cases displayed | **Pass** |
| 4 | Barangay dashboard: **Incoming requests** entry visible | **Pass** |
| 5 | Incoming requests: expected **empty** state (no barangay-scoped rows) | **Pass** |
| 6 | Teen demo authentication succeeded | **Pass** |
| 7 | Teen submitted new fictional counseling request (live write, ~22:19 PHT) | **Pass** |
| 8 | Barangay **Incoming requests**: same request listed with **Submitted** status | **Pass** |
| 9 | Barangay request detail: category, description, barangay site, **Acknowledge receipt** | **Pass** |
| 10 | Barangay acknowledged receipt (~22:25 PHT) | **Pass** |
| 11 | Barangay detail: status **Acknowledged**; acknowledgment button removed | **Pass** |
| 12 | Teen re-authenticated; **My requests** shows **Acknowledged** for new request | **Pass** |
| 13 | Earlier pre-DEMO-003 teen request remains **Submitted** | **Pass** |
| 14 | Teen request detail: **Acknowledged** status and correct acknowledgment timestamp | **Pass** |

## Defect observed during QA

| ID | Screen | Finding | Resolution |
|----|--------|---------|------------|
| DEMO-003-UI-01 | Teen assistance request detail | Footer still stated no barangay review workflow (DEMO-002 copy) | **Corrected in repo** — `assistance_request_detail_screen.dart`; **not yet operator-verified** on device |

## Execution record

| Field | Value |
|-------|--------|
| Environment | Android emulator |
| Firebase | Live `sibol-286d0` post-DEMO-003 deploy |
| Tester role | Operator (PA-guided walkthrough) |
| Date | 2026-10-21 |
| Outcome | **Pass (14/14)** workflow; UI copy defect logged and patched locally |

## Related records

- [SIBOL_DEMO_003_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_003_EXECUTION_REPORT.md) §11
- [firestore.rules.post-demo-003-deploy-2026-10-21.metadata.json](../Artifacts/firestore.rules.post-demo-003-deploy-2026-10-21.metadata.json)
- [MVR-0003-demo-002-teen-assistance-emulator.md](MVR-0003-demo-002-teen-assistance-emulator.md) (prior teen assistance baseline)
