# MVR-0006 — SIBOL-DEMO-005 Barangay report history and receipt (Android emulator, live Firebase)

> **Work item:** SIBOL-DEMO-005  
> **Source:** PA operator acceptance (handover `f4b29c61-8e35-4a70-b216-9d83e5c047fa`, 2026-10-22)  
> **Firebase project:** `sibol-286d0`  
> **Status:** **Executed — Pass (7/7 observed)** (operator-confirmed; PA-reviewed)

## Scope

Manual verification on **Android emulator** against **live** Firestore for Barangay **Submitted reports** history and **submission receipt** (post-DEMO-005 app build).

**In scope:** Dashboard entry, history list, receipt fields, persistence across sign-out/sign-in.

**Not manually verified:** Automatic navigation to receipt immediately after a **new** submit (no additional live report created during this session).

Distinct from automated `flutter test` and `shared/firestore-rules-test`.

## Test fixture (fictional)

| Field | Value |
|-------|--------|
| Barangay account | `barangay.demo@sibol.local` |
| Assigned site | Barangay Tres, Balingasag |
| Report document | `reports/8hCkusDPRacAWEiMZyPK` (existing from prior operator session) |
| Submitted (operator local) | 2026-10-22, ~05:28 |
| Aggregate counts | Total **6** — Active **3**, Follow-up scheduled **1**, Follow-up completed **1**, Closed **1** |

No passwords recorded. EA did not modify live data.

## Sequential results (operator-observed)

| # | Check | Result |
|---|--------|--------|
| 1 | Barangay dashboard: **Submitted reports** option visible | **Pass** |
| 2 | Submitted reports history lists existing Barangay Tres report | **Pass** |
| 3 | Receipt reference `8hCkusDPRacAWEiMZyPK` | **Pass** |
| 4 | Submission timestamp ~2026-10-22 05:28 (local) | **Pass** |
| 5 | Aggregate counts 3 / 1 / 1 / 1 (total 6) | **Pass** |
| 6 | Receipt shows aggregates only; no individual case details | **Pass** |
| 7 | After sign-out and sign-in, same receipt still accessible | **Pass** |

## Not tested (documented gap)

| Item | Status |
|------|--------|
| Post-submit `pushReplacement` to receipt after **new** live submission | **Not tested** (no new report created) |

## Execution record

| Field | Value |
|-------|--------|
| Environment | Android emulator |
| Firebase | Live `sibol-286d0` |
| Tester role | Operator (PA acceptance) |
| Date | 2026-10-22 |
| Outcome | **Pass (7/7)** for history/receipt/persistence |

## Related records

- [SIBOL_DEMO_005_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_005_EXECUTION_REPORT.md) §7–§8
- [MVR-0005-demo-004-moph-reporting-emulator.md](MVR-0005-demo-004-moph-reporting-emulator.md) (same report fixture, MOPH path)
