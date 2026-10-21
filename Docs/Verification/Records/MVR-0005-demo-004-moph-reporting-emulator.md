# MVR-0005 — SIBOL-DEMO-004 MOPH aggregate reporting (Android emulator, live Firebase)

> **Work item:** SIBOL-DEMO-004  
> **Source:** PA operator live verification report (handover `b82f6c41-9d35-4e70-a216-5f93c0d847ab`, 2026-10-22)  
> **Firebase project:** `sibol-286d0` (ruleset `c5b24ed9-…`; six composite indexes per post-query-fix metadata)  
> **Status:** **Executed — MOPH path Pass (7/7)** (operator-observed; PA-reviewed)

## Scope

Manual verification on **Android emulator** against **live** Firestore after:

- DEMO-004 rules/index deploy (`a9e4d271-…`)
- MOPH list query fix (`6e95734`) and index deploy (`e6a2f917-…`)

**In scope:** MOPH dashboard list stability, report detail aggregate fields, no case PII.

**Out of scope (outstanding):** Barangay-facing **submission receipt / submitted-reports history** UI (`watchReportsForBarangay` exists in repository only; no dashboard screen). Barangay submit step assumed from prior operator session (report `8hCkusDPRacAWEiMZyPK`).

Distinct from automated `flutter test` and `shared/firestore-rules-test`.

## Test fixture (fictional)

| Field | Value |
|-------|--------|
| MOPH account | `moph.demo@sibol.local` |
| Report document | `reports/8hCkusDPRacAWEiMZyPK` |
| Reporting barangay | Barangay Tres, Balingasag |
| Submitted (operator local) | 2026-10-22, ~05:28 |
| Status | `submitted` |
| Aggregate counts | Total **6** — Active **3**, Follow-up scheduled **1**, Follow-up completed **1**, Closed **1** |

No passwords recorded. EA did not modify live data for this record.

## Sequential results (operator-observed)

| # | Check | Result |
|---|--------|--------|
| 1 | MOPH dashboard lists submitted Barangay Tres report | **Pass** |
| 2 | List shows reference `8hCkusDPRacAWEiMZyPK` | **Pass** |
| 3 | Submission time ~2026-10-22 05:28 (local) | **Pass** |
| 4 | Status **submitted** | **Pass** |
| 5 | Aggregate counts match fixture (6 total; 3/1/1/1 by status) | **Pass** |
| 6 | Report detail shows aggregates only (no individual case records) | **Pass** |
| 7 | Return to dashboard; stable ~15s without `PERMISSION_DENIED` | **Pass** |

## Execution record

| Field | Value |
|-------|--------|
| Environment | Android emulator |
| Firebase | Live `sibol-286d0` |
| Tester role | Operator (PA-reviewed) |
| Date | 2026-10-22 |
| Outcome | **Pass (7/7)** MOPH reporting verification |

## Related records

- [SIBOL_DEMO_004_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_004_EXECUTION_REPORT.md) §10
- [firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json](../Artifacts/firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json)
- [MVR-0004-demo-003-barangay-ack-emulator.md](MVR-0004-demo-003-barangay-ack-emulator.md) (prior demo slice)
