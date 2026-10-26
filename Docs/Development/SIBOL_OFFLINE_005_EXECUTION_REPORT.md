# SIBOL-OFFLINE-005 — Offline case save hang correction

**Handover UUID:** `f8a2c614-3d79-4b50-9e27-6c1d84a039b5`  
**Investigation:** `a5d9c271-6e42-4b18-9f30-82c6d4e71905`  
**Starting HEAD:** `d2f4123`

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

## Manual QA

Not resumed automatically per handover.
