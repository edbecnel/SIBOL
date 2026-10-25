# SIBOL-OFF-002 — Execution report

**Handover UUID:** `f3c6a9e2-7b41-4d85-9f20-6a8e1c5b734d`  
**Starting HEAD:** `ea1e139`  
**Ending HEAD:** `6282c9c`  
**Authorization:** PA-approved OFF-002 plan with refinements (DEC-OFF-002-01 … 06)

## Tranche commits

| Tranche | Commit | Summary |
|---------|--------|---------|
| A — W1 visibility | `2a4664a` | Global `OfflineStatusBanner`, teen pending list rows, cached-data notices on assistance streams |
| B — W2 cases | `d9be05b` | Case cache/pending UX, offline save messaging, follow-up create |
| C — W3 reports | `a5f9fe5` | `barangayReportSubmit` queue, frozen payload, `reports/{operationId}` create-only replay |
| D — Hardening/docs | `5215433` | Runbook §10 offline acceptance, this report |

## Implemented behavior by workflow

### W1 — Teen assistance + barangay inbox (queue)

- Reused `PendingOperationStore` / `OfflineSyncService` / callables (unchanged replay semantics).
- Mounted global pending banner with manual **Retry now**.
- Teen **My requests** merges queued `teenAssistanceSubmit` operations with Firestore list.
- Teen and barangay assistance lists show `CachedDataNotice` when `SnapshotMetadata.isFromCache`.

### W2 — Case management (Firestore persistence)

- Case list/detail expose cache and `hasPendingWrites` via `FirestoreListSnapshot` / `FirestoreDocumentSnapshot`.
- Create/edit/follow-up use direct Firestore writes (no duplicate custom queue).
- Minimal **Record follow-up** dialog + `CaseRepository.createFollowUp`.
- **Limitation:** concurrent edits are last-write-wins; UI does not claim conflict detection.

### W3 — Barangay → MOPH reporting (queue + idempotent doc id)

- New `PendingOperationKind.barangayReportSubmit` with counts/org frozen in payload (`BarangayReportQueuePayload`).
- Sync uses `ReportRepositoryImpl.createBarangayAggregateReport` at `reports/{reportId}` where `reportId == operationId`.
- Replay after uncertain response: `already-exists` → verify payload match → `submittedConfirmed`; mismatch → `conflict`.
- Submit screen warns when case list is from cache or has pending writes.
- **Submitted reports** lists queued submissions until server confirmation.

## Report idempotency mechanism

- Stable Firestore document ID derived from persisted `operationId` (`rpt-{micros}-{random}`).
- Create-only write (`get` then `set` if absent; existing doc triggers match check).
- No `reports.add()` on replay; no `submitReport` callable (not authorized).

## Automated verification

| Suite | Command | Result (EA) |
|-------|---------|-------------|
| Flutter unit/widget | `cd sibol_app && flutter test` | **137/137 PASS** (post D fix) |
| Offline queue | `test/offline_sync_service_test.dart` | PASS |
| Report payload | `test/barangay_report_queue_payload_test.dart` | PASS |
| W2 model | `test/follow_up_model_test.dart` | PASS |

Device/emulator offline-to-online steps are documented in runbook §10; not substituted for mocked connectivity tests.

## Emulator safeguards

- Canonical stack **not** restarted or reseeded during implementation.
- QA-001 records not targeted by automated tests.
- Functions/rules production deploy **not** performed.

## Remaining limitations

- `connectivity_plus` does not prove Firebase reachability.
- W2 LWW for overlapping offline edits (prototype acceptance).
- MOPH visibility of synced reports assumes existing rules/capabilities on the target host.
- Rules deploy required before production-like hosts accept new ack/report paths (unchanged from OFF-001).

## Minimal Product Owner acceptance

See [SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md](../Operations/SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md) §10 (steps O1–O8).

**Final prototype acceptance remains a Product Owner decision.**
