# Case and reporting model (provisional)

> **Status:** Updated for SIBOL-CASE-IDENTITY-001  
> **Not a clinical standard**

## Case (`cases/{caseId}`)

### Core (all documents)

| Field | Type | Notes |
|-------|------|-------|
| `orgId` | string | Organization scope (required by security rules) |
| `demoName` | string | Display name mirror; kept for backward compatibility |
| `fullName` | string | Required on extended documents |
| `age` | int | Stored; prefer DOB-derived age when `dateOfBirth` present |
| `barangay` | string | Site label |
| `caseStatus` | string | `active`, `followUpScheduled`, `followUpCompleted`, `closed` |
| `registeredAt` | timestamp | UI label **Case opened** |
| `nextFollowUpAt` | timestamp? | |
| `notes` | string | Staff case notes |
| `createdAt` / `updatedAt` | timestamp | |
| `reportStatus` | string | Client-visible lifecycle |

### Identity extension (SIBOL-CASE-IDENTITY-001)

| Field | Type | Notes |
|-------|------|-------|
| `subjectKind` | string | `registered` \| `unregistered` |
| `caseCompleteness` | string | `draft` \| `active` \| `legacyIncomplete` |
| `dateOfBirth` | string | `YYYY-MM-DD` when captured |
| `contactEmail` | string? | Contact only (not proof of account for unregistered) |
| `contactPhone` | string? | |
| `parentGuardianContact` | string? | |
| `teenUid` | string? | Required for `registered` active cases |
| `linkedAccountEmail` | string? | Auth email **snapshot** recorded at verified linkage (not a live Auth mirror) |
| `identityLinkedAt` | timestamp? | When registered linkage was verified |
| `teenProfileSyncedAt` | timestamp? | **Legacy only** — last automatic profile→case sync before SIBOL-CASE-IDENTITY-001 ownership correction; no longer written |

**Independence rule (SIBOL-CASE-IDENTITY-001 ownership correction):** Teen profile edits (`users/{uid}`) never automatically overwrite established Barangay case identity/contact fields (`cases/{caseId}`). Barangay case edits never overwrite teen site registration or Firebase Authentication credentials. Registered cases may receive a **one-time** identity/contact snapshot when linkage is verified via `regResolveRegisteredTeenForCase`; subsequent changes on either side remain independent.

**Legacy documents** without `caseCompleteness` remain valid (age-only QA/demo records).

**Drafts** may omit DOB and contact; **active** cases require full name, DOB, barangay, and at least one contact method.

**Reporting** excludes `draft` cases from aggregate counts (client-side).

## Teen profile (`users/{teenUid}`) — self-service fields

| Field | Notes |
|-------|-------|
| `displayName` | Full name |
| `dateOfBirth` | `YYYY-MM-DD` |
| `assignedBarangay` | Barangay label |
| `contactEmail` / `contactPhone` | At least one required after profile update |
| `parentGuardianContact` | Optional |

Sign-in email remains Firebase Authentication (separate from `contactEmail`).

## Callable verification (registered case linkage)

- `regListRegisteredTeensForCase` — org-scoped teen picker (`case.write`).
- `regResolveRegisteredTeenForCase` — **one-time** authoritative snapshot before registered case activation or linkage (online). Does not modify `users/{uid}`.
- `regSyncRegisteredTeenCasesFromProfile` — **disabled (compatibility stub).** Callable remains registered for older clients but returns `failed-precondition` and performs **no Firestore writes**. Ongoing profile↔case synchronization was removed; use case edit for Barangay corrections and **Edit my profile** for teen self-service.

## Follow-up (`cases/{caseId}/followUps/{followUpId}`)

| Field | Type |
|-------|------|
| `caseId` | string |
| `scheduledAt` | timestamp |
| `completedAt` | timestamp? |
| `status` | `scheduled` \| `completed` \| `cancelled` |
| `notes` | string |
| `createdByUid` | string? | Staff recorder |
| `createdAt` | timestamp? | |

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
