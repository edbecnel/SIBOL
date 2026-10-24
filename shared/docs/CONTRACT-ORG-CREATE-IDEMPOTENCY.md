# CONTRACT — Organization creation idempotency (draft)

> **Status:** Draft — M0  
> **Work item:** SIBOL-ORG-IDENTITY-001 (F-04)  
> **Applies to:** `regCreateBarangayOrganization`, `regCreateHospitalOrganization` (proposed)

## 1. Purpose

Prevent duplicate organizations and duplicate initial administrator invitations when clients retry after timeouts or lost responses.

## 2. Request

| Field | Type | Required |
|-------|------|----------|
| `idempotencyKey` | string (UUID v4) | **Yes** |

Scoped per **Central Administrator** `uid` and callable operation name.

## 3. Storage

**Collection:** `organizationCreationIdempotency/{centralAdminUid}__{idempotencyKey}`

Schema: [organization_creation_idempotency.schema.json](../contracts/organization_creation_idempotency.schema.json)

Client writes: **denied** (Firestore rules).

## 4. Record lifecycle

| `status` | Meaning |
|----------|---------|
| `in_progress` | Transaction started (optional; may omit if single atomic tx) |
| `completed` | Org + invitation + identity key committed; `response` populated |
| `failed` | Terminal error; retry may use new key |

**Retention:** `expiresAt` recommended 30 days for GC; audit events retain permanent record.

## 5. `requestFingerprint`

Stable SHA-256 over canonical JSON of identity-relevant fields (PSGC codes, NHFR code, emails, display alias). Excludes timestamps.

## 6. Behaviors

| Case | Result |
|------|--------|
| Same key + same fingerprint + `completed` | Return stored `response` (200/success) |
| Same key + different fingerprint | `failed-precondition` |
| Concurrent same key | One transaction wins; other retries read `completed` or fails create |
| Transaction failure | No `completed`; safe retry with same key |

## 7. Atomicity

Single Firestore transaction:

1. Claim idempotency (or read completed).
2. Create `organizationIdentityKeys` document.
3. Create `organizations/{orgId}`.
4. Create initial `organizationStaffInvitations` document.
5. Mark idempotency `completed` with response snapshot.

## 8. Compatibility

Existing `regCreateOrganization` has no idempotency until replaced; legacy callable unchanged until deprecation gate (implementation plan §10).
