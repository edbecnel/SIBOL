# Callable contract: `createCoordinationReferral` (planned)

> **Status:** Implemented in repository (SIBOL-CASE-COORD-001 Increment B) — **not deployed** to `sibol-286d0` until PA authorizes Functions deploy  
> **Work item:** SIBOL-CASE-COORD-001  
> **ADR:** [ADR-0005-Case-Coordination-Minimum-Information.md](../../Docs/Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md)

## Purpose

Atomically create a minimum-information hospital coordination referral from an **acknowledged** Teen assistance request. Enforces DEC-CASE-001 and registry uniqueness without client-trusted writes.

## Authentication and authorization

- Caller must be signed in (Firebase Auth).
- Server loads `users/{uid}` via Admin SDK; requires `active == true` and `role == 'barangay'`.
- `assignedBarangay` must match the assistance request `barangay`.

## Input

```json
{
  "assistanceRequestId": "string",
  "barangayReferralSummary": "string (10–2000 chars)",
  "relatedReportId": "optional string"
}
```

## Preconditions (server-enforced)

1. `teenAssistanceRequests/{assistanceRequestId}` exists.
2. Request `status == 'acknowledged'`.
3. Request `barangay` equals caller `assignedBarangay`.
4. `barangayCoordinationRegistry/{assistanceRequestId}` **does not exist** OR exists only with `active == false` and policy allows no second referral on same id — **v1: reject if document exists at all** (registry history preserved; no duplicate key reuse).
5. Optional `relatedReportId`: if present, `reports/{id}` exists, `reportStatus == 'submitted'`, same `barangay`.

## Atomic writes (single transaction)

| Path | Content |
|------|---------|
| `caseCoordinationThreads/{newThreadId}` | Header: `barangay`, server-generated `displayRef`, `category` from assistance request, `barangayReferralSummary`, `phase: referred`, timestamps, `createdByUid` |
| `.../private/binding` | `teenUid`, `assistanceRequestId`, `createdAt`, `createdByUid` |
| `barangayCoordinationRegistry/{assistanceRequestId}` | `threadId`, `barangay`, `teenUid`, `active: true`, `createdAt` |
| `.../staffEvents/{eventId}` | `eventType: referral_submitted`, bounded `body`, `actorUid`, `createdAt` |
| `teenCoordinationLinks/{teenUid}/links/{assistanceRequestId}` | Generic `progressCode` / `progressLabel` (Increment B/D) |

## Privacy invariants

- Header and staff event bodies visible to MOPH must **not** include teen name, contact, Auth uid, or verbatim teen `description`.
- `displayRef` generated server-side (opaque; not equal to Auth uid).

## Output

```json
{
  "threadId": "string",
  "displayRef": "string"
}
```

## Failure behavior

| Condition | Code |
|-----------|------|
| Not authenticated | `unauthenticated` |
| Not barangay / inactive | `permission-denied` |
| Assistance not found | `not-found` |
| Not acknowledged / wrong barangay | `failed-precondition` |
| Registry already exists (v1) | `failed-precondition` |
| Invalid summary length | `invalid-argument` |

## Increment C note

MOPH/barangay **staff event** append and **phase** updates may use constrained client transactions or additional callables; Increment A rules deny all client writes on coordination paths until those contracts are implemented and tested.
