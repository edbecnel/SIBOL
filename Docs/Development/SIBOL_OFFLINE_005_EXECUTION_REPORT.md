# SIBOL-OFFLINE-005 — Offline case save hang correction

**Handover UUID:** `f8a2c614-3d79-4b50-9e27-6c1d84a039b5`  
**Investigation:** `a5d9c271-6e42-4b18-9f30-82c6d4e71905`  
**Starting HEAD:** `d2f4123`  
**Ending HEAD:** _(see post–edit-route commit below)_

**Edit-route follow-up handover:** `c42e7a91-8f35-4d60-b2a9-7e61f0c43825` · **Baseline:** `a096242`

## Defect

Offline **Create case** left the primary button spinning indefinitely because [`CaseEditScreen`](sibol_app/lib/features/cases/presentation/screens/case_edit_screen.dart) awaited `CaseRepositoryImpl.createCase` → unbounded `await ref.set()` while the Firestore client could not complete the Future to the emulator under airplane mode.

## Root cause

UI success was coupled to **server-round-trip completion** of `set()` / `update()`, not to **local persistence**. No timeout or cache verification existed. Case create also allocated a new document id on every attempt, increasing duplicate risk after ambiguous hangs.

## Approved correction

1. **`commitWriteLocalFirst`** — 5s bounded wait, then confirm document in **cache** ([`local_firestore_write.dart`](sibol_app/lib/core/firestore/local_firestore_write.dart)).
2. **Create** — `newCaseDocumentId()` once per screen session; idempotent return when cache already matches create intent.
3. **Update / follow-up** — cache-first existence checks; same local-first commit pattern.
4. **Human-readable labels** — lifecycle, aggregate-report inclusion, and sync copy from Firestore metadata ([`case_presentation_labels.dart`](sibol_app/lib/features/cases/domain/case_presentation_labels.dart)); no raw `notSubmitted` in UI.
5. **List rows** — per-document `isFromCache` / `hasPendingWrites` via [`CaseListEntry`](sibol_app/lib/features/cases/domain/entities/case_list_entry.dart).

Firestore rules unchanged.

## Maria Offline Test (read-only emulator check)

Executed against local Firestore emulator (no writes, no reseed):

- Query: `cases` where `demoName == "Maria Offline Test"`.
- **Result:** **1 document** — `cases/fhcQrLxE0IhwPFzCPinH`, age 16, `orgId` `barangay03`, `createdAt` present on emulator (local write had reached backend or synced when emulator was queried).

## Automated verification

- `flutter test` — 176 tests pass (includes `local_firestore_write_test`, `case_presentation_labels_test`, `case_list_ui_labels_test`, `case_create_idempotency_test`).

## Limitations

- **Server rejection** after local queue (rules/capability) is not surfaced as a dedicated in-app state; pending writes remain until Firestore clears or retries exhaust (prototype).
- Save snackbars assume **local-first success** (`hasPendingWritesHint: true`); detail/list sync lines use snapshot metadata for confirmation.
- Connectivity / Wi-Fi state is **not** used for sync labels.

## O5 incident — offline edit route (diagnosis)

During manual O5, **Edit case** after a second airplane-mode cycle left a **blank or stuck** screen while logcat showed repeated Firestore **`ENETUNREACH`** to `10.0.2.2:8195` and occasional **`ENHANCE_YOUR_CALM` / `too_many_pings`** on `WatchStream`. The emulator VM and app process remained responsive (no crash/ANR). **Maria Offline Test** (`fhcQrLxE0IhwPFzCPinH`) was preserved.

**Mechanism:** Edit mode used `caseDetailStreamProvider` → unbounded `watchCase` before rendering the form. Under airplane mode the SDK reconnect loop could delay or prevent a useful first emission even when the case existed in the local cache.

## Edit-route correction

1. [`CaseEditRecordResolver`](sibol_app/lib/features/cases/domain/case_edit_record_resolver.dart) — `fetchCasePreferCache` first, bounded `fetchCase` bootstrap, then resilient `watchCase` (errors swallowed when cache already loaded).
2. [`caseEditRecordProvider`](sibol_app/lib/features/cases/presentation/providers/case_providers.dart) — edit screen subscribes to `watchCaseForEdit` instead of raw detail snapshots.
3. [`CaseEditUnavailable`](sibol_app/lib/features/cases/domain/case_edit_unavailable.dart) — recoverable message when no local copy exists.

**SDK note:** Firestore may still log reconnect warnings under airplane mode; the app no longer blocks the edit form on server reachability when a cached document exists.

## Automated verification (cumulative)

- `flutter test` — **181** tests pass (adds `case_edit_record_resolver_test`, `case_edit_screen_offline_test`).

## Manual QA

Not resumed automatically per handover.
