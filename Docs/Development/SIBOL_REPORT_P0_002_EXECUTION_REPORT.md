# SIBOL-REPORT-P0-002 — Aggregate report submission correction

**Handover UUID:** `c3d72a19-6f84-4b25-9e10-a67d38b45290`  
**Starting HEAD:** `482ec42`  
**Ending HEAD:** `6f1b8ec`

## Root cause

`ReportRepositoryImpl.createBarangayAggregateReport` called `ref.get()` before `set()` to check idempotency. Firestore **read** rules on `reports/{reportId}` require an existing **submitted** document (`resource.data`), so `get()` on a missing id returns **`permission-denied`**. The create never ran.

Organization directory and report payload fields were not implicated.

## Correction

- Removed the pre-create `get()`.
- Use **`DocumentReference.set()`** on a deterministic id (create rule applies when the document does not exist; `cloud_firestore` ^7.0 has no separate `create()` API).
- On **`permission-denied`** from `set()` (typically **update** denied when the doc already exists):
  - If `barangayReportMatchesQueuedPayload` succeeds → **idempotent success** (no second report).
  - Else if `get()` shows an existing doc → throw **`already-exists`** for offline **conflict** handling.
  - Else rethrow the original denial (failed create, not treated as duplicate).

Firestore rules unchanged.

## Pre-fix emulator check

- `reports/rpt-1792920278671570-1106327422` — **does not exist**
- `reports` collection count — **0**

## Failed pending operation

Operation id **`rpt-1792920278671570-1106327422`** remains in on-device pending storage (not cleared per handover). It was classified **`failedPermanent`** after `permission-denied`. `OfflineSyncService.syncForUser` **skips** `failedPermanent` ops, so it **will not auto-retry** after the fix.

A **new** tap on **Submit report to MOPH** generates a **new** `rpt-…` id and is the safe manual path after PA acceptance. Resetting the failed op to retry the **same** id requires separate PA authorization.

## Manual retry (after PA acceptance)

1. Rebuild app with this fix on `emulator-5554` (development + `USE_FIREBASE_EMULATORS=true`).
2. Barangay → **Submit report to MOPH** → confirm preview counts → submit **once**.
3. Expect receipt or submitted-reports list; MOPH inbox should show one aggregate report.
4. Do not double-submit.

## Regression tests

- Flutter: `test/report_repository_impl_test.dart` (no pre-read, idempotent duplicate, conflict, genuine deny).
- Rules: nonexistent `get` denied; deterministic `set` create; duplicate `set` denied.

## Acceptance

**Not declared — await PA manual submit after fix.**
