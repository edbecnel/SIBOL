# SIBOL-QA-CONN-002 — Execution report

**Handover UUID:** `d48e2a71-9c35-4f80-a6b2-73e19c5d042f`  
**Prior investigation:** SIBOL-QA-CONN-001  
**Starting HEAD:** `f7cf4c4`  
**Ending HEAD:** `fea47f7`  

## Root cause (accepted hypothesis)

Firestore listeners used default `includeMetadataChanges: false`. When persisted cache already matched the server, only snapshot **metadata** (`isFromCache: false`) changed. The UI bound to `SnapshotMetadata.isFromCache` never received an event, so **Cached only** and dashboard cache notices could persist after reconnect.

Runtime confirmation on PO device is still via retest; behavior matches SDK semantics and static analysis.

## Implementation

| Area | Change |
|------|--------|
| Metadata listeners | `snapshotsWithCacheMetadata()` → `includeMetadataChanges: true` on case list, case detail, follow-ups, and W1 assistance list streams |
| Shared helper | `lib/core/firestore/firestore_snapshot_listeners.dart` |
| Sync semantics | Unchanged `FollowUpSyncState` / **Pending sync** vs **Cached only** |
| Copy | `CachedDataNotice` no longer implies Android is disconnected |
| Emulator init | Kept `useFirestoreEmulator` before `settings`; comment only |

## Emulator configuration (static verification)

| Check | Expected |
|-------|----------|
| Project | `sibol-286d0` (`firebase_options.dart`) |
| Android host | `10.0.2.2` (`EmulatorHosts.firebase`) |
| Firestore port | `8195` |
| Auth port | `9099` |
| Flag | `USE_FIREBASE_EMULATORS=true` (`EnvConfig.useEmulators`) |

## Tests

| Suite | Result |
|-------|--------|
| `flutter test` | **153/153 PASS** |
| `firestore_metadata_ui_regression_test.dart` | Metadata transition + pending sync preserved |

## Android emulator retest (PO)

| Step | Expected |
|------|----------|
| Open Maria Test case online after prior sync | Follow-ups load; **Cached only** clears within seconds if server reachable |
| Dashboard case list | Cache notice clears after server snapshot (not stuck indefinitely) |
| Offline add follow-up | **Pending sync** remains until `createdAt` ack |
| Kill/reopen offline | **Pending sync** still shown (QA-FIX-001 path) |

## Remaining risks

- `connectivity_plus` still unrelated to Firestore network state.
- Streams without cache UX unchanged (narrow scope).
- Production path unchanged when emulators flag is false.
