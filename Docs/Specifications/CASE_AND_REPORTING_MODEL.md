# Fictional case and reporting model (provisional)

> **Status:** Draft — Tranche 1  
> **Source:** Product-owner proposal `Docs/Reference/SIBOL.docx` + PA handover SIBOL-IMP-001  
> **Not a clinical standard**

## Case (`cases/{caseId}`)

| Field | Type | Notes |
|-------|------|-------|
| `demoName` | string | Fictional name |
| `age` | int | 13–19 enforced in app validation |
| `barangay` | string | Demo site label |
| `caseStatus` | string | `active`, `followUpScheduled`, `followUpCompleted`, `closed` |
| `registeredAt` | timestamp | |
| `nextFollowUpAt` | timestamp? | |
| `notes` | string | Non-clinical demo notes |
| `createdAt` / `updatedAt` | timestamp | |
| `reportStatus` | string | Client-visible lifecycle; **MOPH visibility requires server acceptance** |

## Follow-up (`cases/{caseId}/followUps/{followUpId}`)

| Field | Type |
|-------|------|
| `caseId` | string |
| `scheduledAt` | timestamp |
| `completedAt` | timestamp? |
| `status` | `scheduled` \| `completed` \| `cancelled` |
| `notes` | string |

## Report (`reports/{reportId}`) — Tranche 2

Written only by trusted Cloud Function after successful submit. MOPH may read documents where `reportStatus == submitted` and `acceptedAt` is set.

## Synchronization semantics (design)

| State | Meaning |
|-------|---------|
| Locally cached | Firestore SDK served from cache (`SnapshotMetadata.isFromCache`) |
| Pending write | `hasPendingWrites` on snapshot |
| Server-confirmed | Successful commit; not inferred from client-only fields |
| Pending report | `reportStatus == pendingSubmit` (Tranche 2) |
| Server-accepted report | Function wrote `reports/*` + `acceptedAt` |

See [OFFLINE_SYNC_MODEL.md](../../shared/docs/OFFLINE_SYNC_MODEL.md).
