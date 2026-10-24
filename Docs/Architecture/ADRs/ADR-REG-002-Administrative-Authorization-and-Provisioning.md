# ADR-REG-002: Administrative authorization and provisioning (DEC-002, DEC-004, DEC-006, DEC-008)

> **Status:** Accepted (architecture) — PA directions DEC-002, DEC-004, DEC-006, DEC-008 via handover `SIBOL-REG-001-ARCH-DOC-001`  
> **Implementation:** **Not authorized** by this ADR  
> **Date:** 2026-10-24  
> **Work item:** SIBOL-REG-001

## Context

Demonstration provisioning uses Firebase Admin SDK seed ([PROVISIONING.md](../../../shared/docs/PROVISIONING.md)) with fixed `teen` / `barangay` / `moph` roles. Firestore denies client creation of `users/{uid}` ([`firestore.rules`](../../../firestore.rules)). There is no administrator role, invitation flow, or audit trail.

DEC-008 **supersedes** the investigation’s provisional “central-only staff approval” for ongoing operations: Organization Administrators manage their own personnel from the initial prototype, within bounds below.

## Decision

### DEC-004 — Central administration

1. **Central Administrator** is a distinct privileged role (not `teen` / `barangay` / `moph` demo roles).
2. Initial admin UX lives in the **Flutter** mobile application.
3. Privileged operations are **server-authoritative** (callable and/or Admin SDK); clients cannot assign roles or approve memberships by direct Firestore writes.
4. A separate web admin console may be added later without changing authorization invariants.

### DEC-002 — Staff onboarding

1. **Invitation-based** registration; staff set their own passwords (Firebase Auth).
2. Membership remains **inactive** until **approved**.
3. Trusted backend services perform all privileged changes.

### DEC-008 — Organization administration

| Central Administrator | Organization Administrator |
|----------------------|----------------------------|
| Create organizations | Invite staff to **their** org(s) |
| Appoint initial Organization Administrator(s) | Approve, reject, suspend, revoke memberships |
| Central recovery (e.g. last org admin) | Assign **permitted org-level roles** only |
| | **Cannot** grant Central Administrator |
| | **Cannot** gain case/teen confidential access by admin role alone |

Additional rules:

- Support **multiple** Organization Administrators per org (including backup).
- **Prevent** removal of the **last active** Organization Administrator without **central recovery**.
- **No self-approval** and **no unauthorized privilege escalation** (server-enforced).
- All privileged actions **append audit records** (immutable, server-written).

### DEC-006 — Lifecycles and policy

- Organization `status`, account `active`, and membership `status` are **independent**.
- Protected operations require all applicable checks to pass.
- Approval workflows are **configurable** within mandatory security boundaries ([SPEC-REG-001](../../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md) §4.2).
- Design for **future delegated administration** without redesigning core authorization.

### DEC-003 — Teen registration (administrative boundary)

- Teen self-registration does **not** require Barangay pre-approval.
- Barangay org selection is routing only; provisioning callables/rules must not treat selection as staff approval of identity.

### DEC-007 — Reusable mechanisms

- Separate **reusable** registration/authorization primitives (membership, invitation, audit event schema) from **SIBOL-specific** policy (org types, role names, approval steps).
- Expose explicit interfaces for future apps (e.g. SpeakUp Connect); **do not** modify SpeakUp Connect in this work item.

### Trusted provisioning (bootstrap)

1. **Bootstrap:** First Central Administrator via controlled Admin SDK or one-time deploy script (PA-authorized), analogous to demo seed safeguards.
2. **Ongoing:** Callables in [CONTRACT-REG-001](../../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md) — **proposed only**.

### Security tradeoffs

| Approach | Choice |
|----------|--------|
| Client-writable profiles | **Denied** (retain deny-by-default) |
| Custom claims for tenancy | Optional **cache** after server updates; **not** sole revocation path |
| Org Admin reads all cases | **Denied** by default — admin ≠ clinical access |
| Audit | Server-append-only collection or subcollection |

### Relationship to ADR-0003

[ADR-0003](ADR-0003-Authorization-and-Server-Reporting.md) remains valid for **current production/demo** behavior until REG implementation deploys. When implemented:

- Demo roles map to **membership org roles** during migration.
- Server-authoritative reporting ([REPORTING_CONTRACT.md](../../../shared/docs/REPORTING_CONTRACT.md)) unchanged in principle; reporting callables must validate **org context**.

## Consequences

- New callables and rules tests before any Firebase deploy.
- Demo seed remains for fictional accounts until PA authorizes migration.
- MVR-REG-001 defines verification; no MVR execution in this documentation handover.

## Related

- [SPEC-REG-001](../../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md)
- [ADR-REG-001](ADR-REG-001-Organization-Identity-and-Membership.md)
- [CONTRACT-REG-001](../../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md)
- [PROVISIONING.md](../../../shared/docs/PROVISIONING.md) — demo scope only
