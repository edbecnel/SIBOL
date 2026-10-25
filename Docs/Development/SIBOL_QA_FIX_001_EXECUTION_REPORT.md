# SIBOL-QA-FIX-001 — Execution report

**Handover UUID:** `c9f2a681-4e73-4d05-8b16-2a7e90c53f44`  
**Starting HEAD:** `d7951b8`  
**Ending HEAD:** `821f558`  

## 1. P0 — Missing **Pending sync** after offline restart

### Root cause

The timeline relied only on `DocumentSnapshot.metadata.hasPendingWrites`. After an app restart, the Firestore SDK often reports `hasPendingWrites: false` for locally persisted writes that are **not yet acknowledged on the server**, while `createdAt` (a `FieldValue.serverTimestamp()`) remains **absent** in the cached document. The UI then showed neither **Pending sync** nor an honest unknown state—only activity fields (e.g. notes), which PO misread alongside `status: completed` on older builds.

### Fix

- `FollowUpSyncState.awaitingServerConfirmation`: true when `hasPendingWrites` **or** (`createdByUid` set and `createdAt` not yet present in the document).
- `FollowUpTimelineEntry.awaitingServerConfirmation` propagated from `CaseRepositoryImpl.watchFollowUps`.
- Timeline chip uses `awaitingServerConfirmation` (not business status).

### Limitation (documented)

Legacy seeded follow-ups without `createdByUid` are not marked pending when `createdAt` is missing. New staff entries always set `createdByUid`.

## 2. P1 — Global banner / **Retry now**

### Root cause

1. **Retry now** called `syncForUser` but did **not** `invalidate(pendingOperationsProvider)`—banner count stayed stale with no feedback.
2. While **offline**, `syncForUser` returned immediately with **no user-visible message**.
3. `pendingForUser` excluded `submitting` state, understating in-flight work.

### Fix

- `syncForUser` returns `OfflineSyncSummary` with offline/confirmed/pending messaging.
- Banner **Retry now** shows a `SnackBar`, invalidates pending provider, shows in-progress spinner.
- Banner lists pending **operation kinds** and surfaces `lastError` when present.
- `submitting` included in actionable pending set.
- `OfflineSyncHost` refreshes pending list on app **resume**.

### Queued operation disposition

No store wipe. Inspect the banner subtitle after update: it names the kind (e.g. `request acknowledgment`, `teen assistance request`, `barangay report`). If PO still sees `1` action while offline, **Retry now** should report *Device is offline…*; when online, either sync succeeds or *Last issue* shows the server error. **Do not clear secure storage** without PA approval.

## 3. P1 — Barangay on **New case**

### Root cause

Free-text **Barangay** allowed labels such as “Barangay Tres” inconsistent with `users/{uid}.assignedBarangay` (`Barangay 3, Balingasag` in demo seed).

### Fix

- Create flow binds `case.barangay` to `userProfile.assignedBarangay` (read-only **Barangay site (from your organization)**).
- Missing `assignedBarangay` blocks create with an administrator message.
- Edit flow shows barangay read-only (no unauthorized reassignment).
- **Canonical source:** Firestore user profile `assignedBarangay` (provisioned from org/PSGC constants, e.g. `DEMO_ASSIGNED_BARANGAY` in `shared/provisioning`).

Existing cases (including **Maria Test**) are **not** rewritten.

## 4. Tests

| Suite | Result |
|-------|--------|
| `flutter test` | **148/148 PASS** |
| New: `follow_up_sync_state_test.dart`, `offline_sync_summary_test.dart` |
| Updated: `case_edit_screen_test.dart`, `case_follow_up_timeline_test.dart` |

Emulator-backed Android retest required for PO sign-off (see runbook steps below).

## 5. Minimal Android emulator retest

| Step | Action | Expected |
|------|--------|----------|
| 1 | Barangay sign-in → open case `8lzS3WI5VYJh8cY77nrD` (or any case) | Case detail loads |
| 2 | Airplane mode ON → **Add follow-up** → save | **Pending sync** chip on new row |
| 3 | Force-stop app → reopen (still offline) | Same row still shows **Pending sync** |
| 4 | Airplane mode OFF → wait for sync | Chip clears; entry appears in emulator Firestore |
| 5 | If banner shows pending queue action → **Retry now** offline | SnackBar: device offline |
| 6 | **Retry now** online | SnackBar reports sync result; count updates or error shown |
| 7 | **New case** screen | Barangay shows **Barangay 3, Balingasag** (read-only); cannot type “Tres” |

## 6. Remaining blockers

None for local emulator demo. Production deploy unchanged.
