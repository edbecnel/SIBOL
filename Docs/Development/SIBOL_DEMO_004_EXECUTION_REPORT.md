# SIBOL-DEMO-004 — Execution report (Barangay-to-MOPH reporting)

> **Handover UUID:** `7d4e9a21-3c85-4f16-b2a0-6e97d14c582f`  
> **Date:** 2026-10-22  
> **Git restore point:** tag `sibol-demo-003-working-baseline` @ `c06fd2b`  
> **Firebase deploy:** **Not authorized** — rules/indexes changed locally only  
> **Manual QA:** **Not executed** (await operator)

## 1. PA authorization

Minimal functional Barangay → MOPH aggregate reporting for PO demonstration. Preserve DEMO-002/003 behavior. No Auth account changes. No live data modification by EA.

## 2. Design (demo scope)

| Topic | Decision |
|-------|----------|
| Collection | Existing `reports/{reportId}` |
| Payload | **Aggregate only** — barangay label, submission time, status counts; **no** case names, ages, or clinical outcomes |
| Barangay submit | Client `create` with `FieldValue.serverTimestamp()` for `submittedAt` / `acceptedAt`; rules enforce `== request.time` and count integrity |
| MOPH visibility | Read `reportStatus == submitted` with `acceptedAt` set (unchanged gate) |
| Case isolation | MOPH still denied `cases/*`; teen denied `reports/*` |
| Future hardening | Callable `submitReport` ([`shared/functions`](../../shared/functions/src/index.ts)) remains target for production-style acceptance |

Barangay counts are computed from in-app case list filtered to `users.assignedBarangay` (same pattern as DEMO-003).

## 3. Barangay functionality

| Item | Location |
|------|----------|
| Dashboard entry **Submit report to MOPH** | [`barangay_home_screen.dart`](../../sibol_app/lib/features/cases/presentation/screens/barangay_home_screen.dart) |
| Preview + confirm + Firestore create | [`barangay_submit_report_screen.dart`](../../sibol_app/lib/features/reporting/presentation/screens/barangay_submit_report_screen.dart) |
| Aggregate computation | [`barangay_report_aggregate.dart`](../../sibol_app/lib/features/reporting/domain/barangay_report_aggregate.dart) |
| Repository | [`report_repository_impl.dart`](../../sibol_app/lib/features/reporting/data/repositories/report_repository_impl.dart) |

## 4. MOPH functionality

| Item | Location |
|------|----------|
| Submitted reports list (Firestore stream) | [`moph_home_screen.dart`](../../sibol_app/lib/features/moph/presentation/screens/moph_home_screen.dart) |
| Report detail (counts + metadata) | [`moph_report_detail_screen.dart`](../../sibol_app/lib/features/moph/presentation/screens/moph_report_detail_screen.dart) |
| Routes | [`route_constants.dart`](../../sibol_app/lib/core/constants/route_constants.dart), [`app_router.dart`](../../sibol_app/lib/core/router/app_router.dart) |

## 5. Firestore rules and indexes (local — not deployed)

**Rules:** [`firestore.rules`](../../firestore.rules) — `barangayReportCreateValid`, barangay read own-site submitted reports, MOPH read submitted, deny updates.

**Indexes added** in [`firestore.indexes.json`](../../firestore.indexes.json):

- `reports`: `reportStatus` + `submittedAt` (MOPH list)
- `reports`: `barangay` + `submittedAt` (optional barangay history query)

## 6. Automated verification (2026-10-22)

| Check | Result |
|-------|--------|
| `flutter test` | **55 passed** |
| `flutter analyze` | **0 errors**; 1 pre-existing **warning** (`duplicate_import` in `assistance_request_form_screen.dart`); 10 info |
| `shared/firestore-rules-test` | **31/31 passed** (includes [`reports.rules.test.mjs`](../../shared/firestore-rules-test/test/reports.rules.test.mjs)) |
| `flutter build apk --debug` | **Success** — `sibol_app/build/app/outputs/flutter-apk/app-debug.apk` |

## 7. Git checkpoints

| Milestone | Commit | Notes |
|-----------|--------|-------|
| Implementation + rules + tests | *(see EA completion report)* | Pushed to `main` |
| EDF register / CHANGELOG | *(same or follow-up commit)* | This document |

## 8. Required Firebase deployment (PA authorization pending)

```bash
firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0
```

Until deploy, live `sibol-286d0` retains DEMO-003 rules (barangay **cannot** create `reports`; MOPH list will stay empty/error on query).

## 9. Manual verification

**Status:** Not started. Suggested script: Barangay submit aggregate → sign in MOPH → list + detail. Record in MVR when executed.

## 10. PA acceptance

Pending manual demo verification and Firebase deploy authorization.
