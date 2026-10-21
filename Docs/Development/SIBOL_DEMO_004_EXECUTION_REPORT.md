# SIBOL-DEMO-004 — Execution report (Barangay-to-MOPH reporting)

> **Handover UUIDs:** `7d4e9a21-…` (implementation); `b82f6c41-…` (live MOPH verification record)  
> **Date:** 2026-10-22  
> **Git restore point:** tag `sibol-demo-003-working-baseline` @ `c06fd2b`  
> **Firebase deploy:** **Executed** 2026-10-22 — see §9 (handover `a9e4d271-…`)  
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
| Implementation + rules + tests | `1d4f012` | Pushed to `origin/main` |
| EDF register / CHANGELOG | `3db1f9c` | This document |

## 8. Final predeployment verification (2026-10-22)

| # | Check | Result |
|---|--------|--------|
| 1 | Firebase target `sibol-286d0`; active ruleset `projects/sibol-286d0/rulesets/251bc159-efc3-446b-92e3-deae2c5f7719` (release updated 2026-10-21T14:00:21Z) | **PASS** |
| 2 | Proposed `firestore.rules` vs **live** (SHA `2feec126…`, ruleset `251bc159-…`) — `cases` and `teenAssistanceRequests` blocks **unchanged**; delta limited to `reports` (barangay aggregate create + barangay read own submitted) | **PASS** |
| 3 | Proposed `firestore.indexes.json` retains both live `teenAssistanceRequests` composites (`CICAgOjXh4EK`, `CICAgJiUpoMK`, READY); **adds** two `reports` composites (`reportStatus`+`submittedAt`, `barangay`+`submittedAt`) | **PASS** |
| 4 | Aggregate schema compatible with live fiction: **6** cases, all `barangay == Barangay Tres, Balingasag` (matches demo `assignedBarangay` and app filter) | **PASS** |
| 5 | Demo profiles (read-only Admin SDK): teen `Zgw0Kon5…` and barangay `Nki7S2Q…` → `assignedBarangay` **Barangay Tres, Balingasag**; `moph.demo@sibol.local` → uid `eZNb99Ji…`, `role` **moph**, `active` **true** | **PASS** |
| 6 | `shared/firestore-rules-test` on repo `firestore.rules` | **PASS** (31/31) |
| 7 | Rollback artifacts for **current** live config captured/verified | **PASS** — see §8.1 |

**Proposed rules SHA-256:** `497df6e50fbcfbb1e6a2951df3aa9d0fae86841b8ed2e6a69329e9c2adfd4082`  
**Predeploy accepted** — deploy authorized separately (§9).

### 8.1 Rollback references (pre-DEMO-004 live)

| Artifact | Path |
|----------|------|
| Rules file | [`firestore.rules.pre-demo-004-deploy-2026-10-22.rules`](../Verification/Artifacts/firestore.rules.pre-demo-004-deploy-2026-10-22.rules) |
| Rules metadata | [`firestore.rules.pre-demo-004-deploy-2026-10-22.metadata.json`](../Verification/Artifacts/firestore.rules.pre-demo-004-deploy-2026-10-22.metadata.json) |
| Indexes snapshot | [`firestore.indexes.pre-demo-004-deploy-2026-10-22.json`](../Verification/Artifacts/firestore.indexes.pre-demo-004-deploy-2026-10-22.json) |

## 9. Live Firebase deployment (handover `a9e4d271-6b35-4c80-9f12-7d6e23b50a41`)

### 9.1 Pre-deploy safeguards

| Safeguard | Result |
|-----------|--------|
| `firebase use` → `sibol-286d0` | **PASS** |
| `firestore.rules` SHA `497df6e…` | **PASS** |
| Indexes file: 2 existing teen + 2 new `reports` | **PASS** |
| Rollback artifact SHA `2feec126…` / ruleset `251bc159-…` | **PASS** |

### 9.2 Deploy

| Item | Evidence |
|------|----------|
| Command | `firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0` |
| Result | **Success** |
| Rules SHA-256 (source) | `497df6e50fbcfbb1e6a2951df3aa9d0fae86841b8ed2e6a69329e9c2adfd4082` |
| Active ruleset | `projects/sibol-286d0/rulesets/c5b24ed9-aebf-44a9-af28-e9b2ff0d8c9c` (release updated **2026-10-21T21:07:19Z**) |
| Prior live ruleset (rollback) | `projects/sibol-286d0/rulesets/251bc159-efc3-446b-92e3-deae2c5f7719` |
| Post-deploy metadata | [`firestore.rules.post-demo-004-deploy-2026-10-22.metadata.json`](../Verification/Artifacts/firestore.rules.post-demo-004-deploy-2026-10-22.metadata.json) |

### 9.3 Index verification (gcloud)

| Collection | Fields | ID | State |
|------------|--------|-----|--------|
| `teenAssistanceRequests` | `teenUid` + `createdAt` | `CICAgOjXh4EK` | **READY** |
| `teenAssistanceRequests` | `barangay` + `createdAt` | `CICAgJiUpoMK` | **READY** |
| `reports` | `reportStatus` + `submittedAt` | `CICAgJim14AK` | **READY** (~21:12:25Z) |
| `reports` | `barangay` + `submittedAt` | `CICAgJim14AJ` | **READY** (~21:12:24Z) |

No unexpected index removals observed.

### 9.4 Rollback after DEMO-004 deploy

Restore [`firestore.rules.pre-demo-004-deploy-2026-10-22.rules`](../Verification/Artifacts/firestore.rules.pre-demo-004-deploy-2026-10-22.rules) when PA authorizes, **or** release prior ruleset `251bc159-efc3-446b-92e3-deae2c5f7719`.

## 10. Manual verification — MOPH reporting (operator-observed, 2026-10-22)

**Record:** [MVR-0005](../Verification/Records/MVR-0005-demo-004-moph-reporting-emulator.md)  
**Handover:** `b82f6c41-9d35-4e70-a216-5f93c0d847ab`  
**Outcome:** **Pass (7/7)** on Android emulator, live `sibol-286d0` (post query-fix app + indexes)

| Evidence item | Operator observation |
|---------------|-------------------|
| MOPH dashboard | Submitted **Barangay Tres** report visible |
| Reference | `8hCkusDPRacAWEiMZyPK` |
| Submitted | 2026-10-22, ~05:28 (local) |
| Status | `submitted` |
| Aggregates | Total **6** — Active **3**, Follow-up scheduled **1**, Follow-up completed **1**, Closed **1** |
| Detail | Aggregate fields only; no per-case records |
| Stability | Dashboard remained stable ~15s after return; no `PERMISSION_DENIED` |

**Not verified in this session:** Barangay **submission receipt / submitted-reports history** UI (repository `watchReportsForBarangay` implemented; no barangay dashboard screen — future enhancement).

## 12. Defect — MOPH list `permission-denied` (handover `c5f8a219-…`)

### 12.1 Symptom

Live operator test: MOPH dashboard briefly showed a submitted report, then  
`[cloud_firestore/permission-denied]` on the list stream.

### 12.2 Cause

`watchSubmittedReportsForMoph()` queried `reportStatus == submitted` + `orderBy(submittedAt)` only. Deployed rules also require `acceptedAt != null`. Firestore rejects the **collection query** as insecure (not merely filtering rows). Single-document reads could still succeed.

### 12.3 Correction (2026-10-22, no rules change)

**File:** [`report_repository_impl.dart`](../../sibol_app/lib/features/reporting/data/repositories/report_repository_impl.dart)

- MOPH list: add `where('acceptedAt', isGreaterThan: _minAcceptedAt)` and `orderBy('acceptedAt', descending: true)` (submission ordering preserved in practice — `acceptedAt` and `submittedAt` are set together via server timestamp on create).
- Barangay list (`watchReportsForBarangay`): same `acceptedAt` + `reportStatus` constraints for rules parity.

**Indexes** (added in [`firestore.indexes.json`](../../firestore.indexes.json); prior four composites retained):

- `reports`: `reportStatus` + `acceptedAt` (MOPH)
- `reports`: `barangay` + `reportStatus` + `acceptedAt` (barangay)

### 12.4 Regression evidence

| Check | Result |
|-------|--------|
| `shared/firestore-rules-test` | **34/34** (incl. MOPH production vs legacy list query, legacy doc in collection, barangay list, teen deny) |
| `flutter test` | **55 passed** |
| `flutter analyze` | **0 errors**; 1 existing warning |
| `flutter build apk --debug` | **Success** |

### 12.5 Index deployment — query fix (handover `e6a2f917-…`)

| Item | Evidence |
|------|----------|
| Command | `firebase deploy --only firestore:indexes --project sibol-286d0` |
| Result | **Success** |
| Indexes file SHA-256 | `4536d3f020d36bd32449906a31ed2e4158e81b893babfa52dcb4f57142b802a7` (commit `6e95734`) |
| Rules deploy | **Not executed** — active ruleset unchanged `c5b24ed9-aebf-44a9-af28-e9b2ff0d8c9c` |
| Metadata | [`firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json`](../Verification/Artifacts/firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json) |

**Six composites (all READY):** `CICAgOjXh4EK`, `CICAgJiUpoMK`, `CICAgJim14AK`, `CICAgJim14AJ`, `CICAgJjF9oIK`, `CICAgJj7z4EK`.

**App:** rebuild/install debug APK (`6e95734` or later) for corrected MOPH list query.

## 11. PA acceptance

| Gate | Status |
|------|--------|
| Predeploy verification | **Accepted** |
| Firebase rules/indexes deploy (`a9e4d271-…`) | **Complete** (§9) |
| Operator MOPH reporting verification (list + detail + stability) | **Pass** — MVR-0005 (`b82f6c41-…`) |
| Barangay submission receipt / history UI | **Outstanding** (not in DEMO-004 scope delivered) |
| Live report creation by EA | **Not performed** (operator/baranagay session) |
