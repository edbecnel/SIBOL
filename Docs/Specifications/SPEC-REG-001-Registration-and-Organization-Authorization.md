# SPEC-REG-001 — Registration and organization authorization

> **Status:** Draft — PA architectural baseline (DEC-001–DEC-008, handover `SIBOL-REG-001-ARCH-DOC-001`)  
> **Not effective for implementation** until Product Owner confirms open policies and PA issues a separate implementation handover.  
> **Work item:** SIBOL-REG-001  
> **Last updated:** 2026-10-24

## 1. Scope

This specification defines the **target** registration, organization, membership, and administrative authorization architecture for SIBOL. It records PA-approved directions and distinguishes them from **currently implemented** demo behavior.

### 1.1 In scope

- Organization registry and stable identifiers (`orgId`).
- Application accounts (Firebase Authentication + application profile).
- Organization memberships, roles, and statuses.
- Central and Organization Administrator privileges.
- Teen self-registration and Barangay selection for assistance routing.
- Staff invitation, approval, suspension, and revocation.
- Organization-scoped authorization for sensitive cases and reports.
- Audit requirements for policy and administrative actions.
- Migration from demonstration `assignedBarangay` strings.

### 1.2 Non-goals

- Implementing registration UI, rules, or Cloud Functions (separate authorization).
- Modifying SpeakUp Connect or building a generalized multi-tenant platform (see DEC-007).
- Defining legal consent text, age thresholds, or identity-verification law (Product Owner).
- Replacing or redeploying case coordination Increments A/B/B-HISTORY (see ADR-0005).
- Changing demo provisioning scope ([PROVISIONING.md](../../shared/docs/PROVISIONING.md)) until migration is authorized.

## 2. Document classification

| Class | Meaning in this spec |
|-------|----------------------|
| **Implemented (demo)** | Behavior in `main` at investigation baseline `7f5a656` on `sibol-286d0` |
| **PA-approved architecture** | DEC-001–DEC-008 recorded in this package |
| **PO policy pending** | Requires confirmation by Product Owner (Frecy) |
| **Proposed future** | Described for traceability; not authorized |

## 3. Actors and roles

### 3.1 Organization types (PA-approved — DEC-001)

| Type | Description | Initial instance |
|------|-------------|------------------|
| `barangay` | Barangay health / BNS site | Multiple; demo uses fictional label |
| `hospital` | Participating hospital | **Misamis Oriental Provincial Hospital (MOPH)** — one hospital org initially |

Future hospitals and organization types must be representable without schema redesign.

### 3.2 Application roles (target)

| Role | Scope | PA direction |
|------|-------|--------------|
| **Teen** | Account-level; routes assistance via selected Barangay org | DEC-003 |
| **Staff** | Membership in one or more organizations with org-level role | DEC-002, DEC-005 |
| **Organization Administrator** | Manages personnel and memberships within authorized org(s) | DEC-008 |
| **Central Administrator** | Creates organizations, appoints initial org admins, recovery | DEC-004, DEC-008 |

**Implemented (demo):** Firestore `users/{uid}.role` is one of `teen`, `barangay`, `moph` with optional `assignedBarangay` string ([ADR-0003](../Architecture/ADRs/ADR-0003-Authorization-and-Server-Reporting.md)). No `central_admin` or org admin.

### 3.3 Separation of concerns (security — §4)

| Layer | Responsibility |
|-------|----------------|
| Firebase Authentication | Credential proof (email/password initially) |
| Application account | `active`, global suspension, profile fields |
| Organization | `orgId`, type, display name, org `status` |
| Membership | Link account ↔ org, membership `status`, org-level role |
| Effective permission | Derived from membership + active org context + policy |
| Sensitive case access | **Not** implied by administrative roles (DEC-008) |

Flutter navigation and role homes are **UX only**; Firestore rules and trusted callables enforce authorization.

## 4. Security requirements

### 4.1 Investigation finding (implemented gap)

**Implemented:** Any active user with `role == 'barangay'` may read and write **all** documents in `cases/*` regardless of case `barangay` string ([`firestore.rules`](../../firestore.rules)).

**Required before production use with real sensitive information:** Organization-scoped authorization for `cases/*`, `followUps/*`, and organization-bound `reports/*` (and coordination paths that reference barangay scope).

### 4.2 Security invariants (target)

1. **INV-ORG-READ:** A principal may read a case only if an **active** membership in the case’s `orgId` grants case-read permission for that org.
2. **INV-ORG-WRITE:** A principal may mutate a case only if membership grants case-write for the case’s `orgId`.
3. **INV-CROSS-BARANGAY-DENY:** Barangay org A staff cannot read or write cases whose `orgId` is Barangay org B.
4. **INV-CROSS-HOSPITAL-DENY:** Hospital org staff cannot access another hospital org’s coordination or reports unless explicitly granted (initially single MOPH org).
5. **INV-NO-SELF-APPROVE:** A user cannot approve their own membership or assign themselves Organization Administrator or Central Administrator.
6. **INV-NO-CLIENT-PRIVILEGE:** Clients cannot create or modify `role`, membership `status`, `orgId` bindings, or organization `status` without a trusted callable or Admin SDK.
7. **INV-ACCOUNT-SUSPEND:** Account-level `active == false` denies all protected operations regardless of memberships.
8. **INV-ORG-SUSPEND:** Organization `status == suspended` denies protected operations for that org’s data even if membership is `active`.
9. **INV-MEMBERSHIP-GATE:** Membership `status` must be `active` for org-scoped operations (pending/rejected/revoked denied).
10. **INV-ACTIVE-ORG:** For multi-membership accounts, protected operations must include explicit **active organization** context matching the resource `orgId`.
11. **INV-REVOCATION:** Revocation must take effect via **authoritative store** (Firestore membership/account fields); must not rely solely on Firebase custom claims for immediate deny.
12. **INV-AUDIT:** Privileged administrative and policy-configuration actions append immutable audit records (server-written).

### 4.3 Negative authorization tests (required)

See [MVR-REG-001](../Verification/Records/MVR-REG-001-registration-authorization-verification-plan.md). All marked **NOT RUN** until implementation exists.

## 5. Organization lifecycle (PA-approved)

| State | Meaning |
|-------|---------|
| `pending` | Reserved for future self-registration (not initial workflow) |
| `active` | May participate per policy |
| `suspended` | No protected data access for org |

**Creation (initial prototype):** Central Administrator creates organization and appoints initial Organization Administrator(s) (DEC-008).

**Identifiers:** Stable internal `orgId`; display `name` may change (DEC-001).

## 6. User registration lifecycle

### 6.1 Staff (DEC-002, DEC-008)

1. Organization Administrator (or Central Administrator) issues **invitation**.
2. Invitee creates Firebase Auth credentials (password self-service).
3. Application account and **pending** membership created.
4. Organization Administrator **approves** or **rejects** membership.
5. On approval, membership becomes `active`; staff gains org-scoped permissions per org role.

Central-only staff approval is **superseded** by DEC-008.

### 6.2 Teen (DEC-003)

1. Teen self-registers (Firebase Auth + minimal application profile) — **PO policy pending** for fields, age, consent.
2. Teen selects an **approved** Barangay organization for assistance routing.
3. Selection is **routing preference only** — not verified residency or identity.

**Implemented:** No teen self-registration; teen demo account is Admin SDK provisioned.

### 6.3 Central Administrator bootstrap (DEC-004)

- Initial Central Administrator(s) established via **trusted bootstrap** (Admin SDK or one-time callable), not self-service.
- Central Administrator UI is in the **Flutter** application initially; separate web admin may follow.

## 7. Membership lifecycle (DEC-005, DEC-006)

| Membership status | Protected access |
|-------------------|------------------|
| `invited` / `pending` | Denied |
| `active` | Allowed per org role and active-org context |
| `rejected` | Denied |
| `suspended` | Denied for that org |
| `revoked` | Denied; history retained |

- One account → many memberships; each has independent role and status.
- **Active organization** selection required when multiple `active` memberships exist.
- Account suspension overrides all memberships.

## 8. Administrative hierarchy (DEC-004, DEC-008)

| Actor | May |
|-------|-----|
| **Central Administrator** | Create organizations; appoint/replace initial org admins; central recovery; cannot be granted by Org Admin |
| **Organization Administrator** | Invite, approve, reject, suspend, revoke staff; assign **permitted** org-level roles only; multiple org admins including backup |
| **Organization Administrator** | **May not** access teen/case confidential data by virtue of admin role alone |
| **Organization Administrator** | **May not** remove the last active Organization Administrator without central recovery path |

All privileged mutations are **server-authoritative** ([ADR-REG-002](../Architecture/ADRs/ADR-REG-002-Administrative-Authorization-and-Provisioning.md), [CONTRACT-REG-001](../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md)).

## 9. Configurable approval policies (DEC-006)

- Organization, account, and membership statuses are independently represented.
- Protected operations require applicable account, organization, and membership authorization.
- Approval workflows must be **configurable within mandatory security boundaries** (invariants §4.2).
- Policy changes and administrative actions require **audit records**.
- Future delegated administration must not require redesigning core authorization (DEC-006, DEC-007).

**Implemented:** No policy configuration store or audit log collection.

## 10. Privacy (teen — DEC-003)

- Minimize personal information at registration.
- Barangay selection does not assert verified identity or residency.
- Coordination minimum-information boundaries remain per [ADR-0005](../Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md).

**PO policy pending:** Age rules, parental consent, identity verification, account recovery, data retention.

## 11. Migration and backward compatibility

### 11.1 Demonstration data

- Canonical demo site label: `Barangay 3, Balingasag`; organization display name: `Barangay 3 (Poblacion)` ([`shared/provisioning/src/constants.mjs`](../../shared/provisioning/src/constants.mjs)).
- Fields: `users.assignedBarangay`, `cases.barangay`, `teenAssistanceRequests.barangay`, `reports.barangay`, coordination `barangay` strings.

### 11.2 Migration strategy (proposed — not authorized)

| Phase | Behavior |
|-------|----------|
| M0 | Introduce `organizations` and memberships alongside legacy fields |
| M1 | Dual-read: match `orgId` or legacy string via registry mapping |
| M2 | Backfill `orgId` on users and domain documents |
| M3 | Rules require `orgId`; deprecate unscoped barangay case access |

See [ADR-REG-001](../Architecture/ADRs/ADR-REG-001-Organization-Identity-and-Membership.md).

## 12. Acceptance criteria (architecture package)

- [x] DEC-001–DEC-008 recorded in ADRs and this spec.
- [x] Security invariants and negative test plan documented.
- [ ] Implementation handover issued by PA.
- [ ] PO confirms open policy items (§13).
- [ ] MVR-REG-001 procedures executed (**NOT RUN**).
- [ ] Organization-scoped rules deployed and verified before real sensitive data.

## 13. Unresolved Product Owner policies

| Topic | Status |
|-------|--------|
| Minimum teen profile fields | PO pending |
| Age eligibility and verification | PO pending |
| Consent and parental notification | PO pending — do not invent legal requirements |
| Account recovery and email verification | PO pending |
| Data retention and deletion | PO pending |
| Future organization self-registration with central approval | Architecturally reserved (`pending` org); PO pending |

## 14. Related documents

| Document | Relationship |
|----------|----------------|
| [ADR-0003](../Architecture/ADRs/ADR-0003-Authorization-and-Server-Reporting.md) | **Implemented** three-role demo; extended by REG package when implemented |
| [ADR-0005](../Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md) | Coordination privacy — unchanged |
| [ADR-REG-001](../Architecture/ADRs/ADR-REG-001-Organization-Identity-and-Membership.md) | Organization and membership model |
| [ADR-REG-002](../Architecture/ADRs/ADR-REG-002-Administrative-Authorization-and-Provisioning.md) | Admin and provisioning |
| [CONTRACT-REG-001](../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md) | Callable contracts (proposed) |
| [MVR-REG-001](../Verification/Records/MVR-REG-001-registration-authorization-verification-plan.md) | Verification plan |
| [PROVISIONING.md](../../shared/docs/PROVISIONING.md) | Demo seed — not production registration |
| [REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md) | Server reporting — still authoritative |
| [COORDINATION_REFERRAL_CONTRACT.md](../../shared/docs/COORDINATION_REFERRAL_CONTRACT.md) | Referral callable — still authoritative |
