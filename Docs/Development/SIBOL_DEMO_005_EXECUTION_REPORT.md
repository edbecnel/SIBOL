# SIBOL-DEMO-005 — Execution report (Barangay submission receipt and history)

> **Handover UUID:** `a7c39e42-6d81-4b50-9f23-e5a16d7084bc`  
> **Date:** 2026-10-22  
> **Firebase deploy:** **Not authorized** — no rules/index changes required  
> **Operator manual QA:** **Not executed** (await operator)

## 1. PA authorization

Barangay **Submitted reports** history and persistent **submission receipt** after MOPH aggregate submit. Preserve DEMO-004 MOPH path and security boundaries.

## 2. Security and index compatibility (pre-implementation)

| Check | Finding |
|-------|---------|
| `watchReportsForBarangay()` | Production query: `barangay` + `reportStatus` + `acceptedAt` + `orderBy(acceptedAt)` — matches `barangayCanReadSubmittedReport()` |
| Firestore rules | No change required |
| Composite index | `CICAgJj7z4EK` (`barangay` + `reportStatus` + `acceptedAt`) — **deployed READY** on `sibol-286d0` |
| Cross-barangay / teen | Rules deny; emulator tests added |

## 3. Implemented UI and navigation

| Feature | Path |
|---------|------|
| Dashboard **Submitted reports** | [`barangay_home_screen.dart`](../../sibol_app/lib/features/cases/presentation/screens/barangay_home_screen.dart) |
| History list | [`barangay_submitted_reports_screen.dart`](../../sibol_app/lib/features/reporting/presentation/screens/barangay_submitted_reports_screen.dart) |
| Receipt / detail | [`barangay_report_receipt_screen.dart`](../../sibol_app/lib/features/reporting/presentation/screens/barangay_report_receipt_screen.dart) |
| Shared aggregate layout | [`aggregate_report_detail_body.dart`](../../sibol_app/lib/features/reporting/presentation/widgets/aggregate_report_detail_body.dart) (MOPH detail refactored to reuse) |
| Post-submit navigation | [`barangay_submit_report_screen.dart`](../../sibol_app/lib/features/reporting/presentation/screens/barangay_submit_report_screen.dart) → `pushReplacement` to receipt |
| Routes | [`route_constants.dart`](../../sibol_app/lib/core/constants/route_constants.dart), [`app_router.dart`](../../sibol_app/lib/core/router/app_router.dart) |

## 4. Repository / providers

- Reused `watchReportsForBarangay()`; added `watchReportForBarangay(reportId, barangay)` for receipt stream.
- Providers: `barangaySubmittedReportsProvider`, `barangayReportReceiptProvider` in [`report_providers.dart`](../../sibol_app/lib/features/reporting/presentation/providers/report_providers.dart).

## 5. Automated verification (2026-10-22)

| Check | Result |
|-------|--------|
| `shared/firestore-rules-test` | **36/36** |
| `flutter test` | **55 passed** |
| `flutter analyze` | **0 errors**; 1 pre-existing warning |
| `flutter build apk --debug` | **Success** |

## 6. Firebase deployment

**None required** for this work item (indexes and rules already support queries).

## 7. Operator manual QA script (not yet executed)

| Step | Action | Expected observation |
|------|--------|----------------------|
| 1 | Sign in as `barangay.demo@sibol.local` | Barangay dashboard loads |
| 2 | Tap **Submitted reports** | List shows prior aggregate report(s) for Barangay Tres; empty state if none |
| 3 | Open a report | Receipt shows reference ID, barangay, date/time, status, total and status counts; no individual case names |
| 4 | Sign out; sign in again; reopen **Submitted reports** → same receipt | Receipt still available |
| 5 | **Submit report to MOPH** (if appropriate) | After confirm, lands on **Submission receipt** (not only snackbar); back does not return to submit form |
| 6 | Sign in as `moph.demo@sibol.local` | MOPH list/detail still works (DEMO-004 regression) |

## 8. PA acceptance

Pending operator manual QA.
