# ADR-REG-001: Organization identity and membership (DEC-001, DEC-005)

> **Status:** Accepted (architecture) — PA directions DEC-001, DEC-005 via handover `SIBOL-REG-001-ARCH-DOC-001`  
> **Implementation:** **Not authorized** by this ADR  
> **Date:** 2026-10-24  
> **Work item:** SIBOL-REG-001

## Context

SIBOL investigation (`SIBOL-REG-001-INVESTIGATION-001`, baseline `7f5a656`) found:

- No `organizations` collection; Barangay scope is a **duplicate string** (`assignedBarangay`, `cases.barangay`, etc.).
- Multiple staff per site are supported only by sharing the same string.
- Barangay users can access **all** `cases/*` in current rules — unacceptable for production sensitive data.

[ADR-0003](ADR-0003-Authorization-and-Server-Reporting.md) remains the record of **implemented** demo authorization until REG implementation is deployed.

## Decision

### DEC-001 — Organization identity

1. Each Barangay and each participating hospital is a **distinct organization** with stable internal **`orgId`** (opaque, immutable).
2. **MOPH** means **Misamis Oriental Provincial Hospital** — initially **one** `hospital` organization.
3. Display **name** may change without changing `orgId`.
4. Multiple personnel accounts per organization are required.
5. Schema and registry must allow **future hospitals** and **organization types** without breaking existing `orgId` references.

### Organization registry (proposed shape)

Collection: `organizations/{orgId}`

| Field | Purpose |
|-------|---------|
| `orgId` | Document id (stable) |
| `type` | `barangay` \| `hospital` \| (extensible) |
| `name` | Display name (mutable) |
| `status` | `active` \| `suspended` \| `pending` (future self-reg) |
| `createdAt`, `updatedAt` | Audit timestamps |

Optional: `legacyBarangayLabel` for migration from demo strings.

### DEC-005 — Multiple memberships

1. Link accounts to organizations via **`organizationMemberships/{membershipId}`** (or `organizations/{orgId}/members/{uid}` — implementation choice; contracts use logical membership id).
2. Fields include: `accountUid`, `orgId`, `orgRole`, `status`, `invitedBy`, approval metadata.
3. One account may hold **multiple** memberships with **independent** roles and statuses.
4. Single-membership workflow is the normal initial path.
5. Multi-membership accounts must select an **active organization** before org-scoped protected operations; authorization checks **resource `orgId` == active org context**.
6. Account-level suspension (`accounts` or extended `users` profile) **overrides** all memberships.

### Active organization selection

- Stored server-side on account profile (e.g. `activeOrgId`) or session token issued by callable after validation.
- Client must pass `orgId` context on callables; rules use membership + resource `orgId` equality.

### Alternatives considered

| Option | Tradeoff |
|--------|----------|
| **A. `orgId` only on `users` (single org)** | Simple; fails DEC-005 |
| **B. Barangay name as primary key** | Matches demo; rename breaks joins — **rejected** |
| **C. Firebase custom claims as sole tenancy** | Fast rules; poor revocation and multi-org — **rejected as sole mechanism** (claims may supplement after server sync) |
| **D. Membership subcollection + stable `orgId` (chosen)** | Meets DEC-001/005/006; requires migration |

### Compatibility with `assignedBarangay`

| Stage | Behavior |
|-------|----------|
| Demo (now) | `users.assignedBarangay` string; rules match assistance/report coordination |
| Transition | Map demo label → `orgId` in organization registry; dual-write `orgId` on new documents |
| Target | `assignedBarangay` deprecated; teen routing uses `selectedBarangayOrgId` or equivalent |

Do not delete historical string fields until backfill and verification complete.

## Consequences

- Firestore rules must load membership and organization status (not only `users.role`).
- Case and report documents gain **`orgId`** (Barangay org for case ownership; hospital org for hospital-scoped artifacts as defined in implementation spec).
- Flutter must add active-org UX for multi-membership staff.
- SpeakUp Connect may reuse **membership patterns** via DEC-007 interfaces; no SpeakUp changes in this work item.

## Related

- [SPEC-REG-001](../../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md)
- [ADR-REG-002](ADR-REG-002-Administrative-Authorization-and-Provisioning.md)
- [ADR-0003](ADR-0003-Authorization-and-Server-Reporting.md) — current implementation
- [ADR-0005](ADR-0005-Case-Coordination-Minimum-Information.md) — coordination paths
