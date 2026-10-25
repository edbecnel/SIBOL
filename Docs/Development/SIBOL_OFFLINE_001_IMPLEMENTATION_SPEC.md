# SIBOL-OFFLINE-001 — Essential offline implementation (prototype)

**Status:** Implemented (AGENT-001) · **Verified:** partial (automated unit + Functions; device NR)

## Scope

| In scope | Out of scope |
|----------|----------------|
| Durable pending-operation queue (secure storage) | Offline org registration / invitations |
| Teen assistance request compose + server-idempotent submit | General sync framework |
| Barangay staged ack / referral intent | Offline MOPH workflow transitions |
| Connectivity-aware retry with backoff | Official PSGC/NHFR production onboarding |
| Firestore cache labeling (MOPH read paths via existing persistence) | False “delivered” UX |

## Operation states

`savedLocally` → `waitingToSubmit` → `submitting` → `submittedConfirmed` | `failedRetryable` | `failedPermanent` | `conflict`

Local states never imply Barangay/MOPH receipt until `submittedConfirmed`.

## Server authority

- `regSubmitTeenAssistanceRequest` — idempotent teen assistance create (`assistanceSubmissionIdempotency`).
- Barangay ack — `regAcknowledgeTeenAssistanceRequest` callable with `assistanceAcknowledgmentIdempotency` (OFF-001 Tranche 1).
- Referral — `createCoordinationReferral` callable (duplicate → `conflict`).

## Flutter modules

- `lib/features/offline/` — domain, secure store, `OfflineSyncService`, `OfflineSyncHost`.
- Bundled PSGC (ORG-IDENTITY) unchanged.

## Security

- Pending payloads: category/description/summary only (no credentials).
- `flutter_secure_storage` per signed-in `ownerUid`.
