# Offline and synchronization model

> **Tranche 1:** Documented and structurally supported; full UX in Tranche 2+

## Platform choice

- **Firestore native offline persistence** on Android/iOS (`persistenceEnabled: true` in app startup).
- No Hive/Drift unless testing proves Firestore insufficient.

## Distinctions (mandatory)

1. **Locally cached record** — `DocumentSnapshot.metadata.isFromCache`
2. **Locally modified, awaiting sync** — `metadata.hasPendingWrites`
3. **Server-confirmed record** — successful listener/update after reconnect; never trust client-only `syncState: synced`
4. **Pending report submission** — `reportStatus: pendingSubmit` (set only when submit requested offline)
5. **Server-accepted report** — Cloud Function writes `reports/{id}` with `acceptedAt`
6. **Failed submission** — `submitFailed` with error metadata (Tranche 2)

## Reporting rule

MOPH must not see barangay drafts. `firestore.rules` deny MOPH access to `cases/*`. Accepted summaries appear only under `reports/*` after server acceptance.
