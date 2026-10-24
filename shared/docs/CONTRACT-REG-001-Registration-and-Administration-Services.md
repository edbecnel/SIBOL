# CONTRACT-REG-001 — Registration and administration services (proposed)

> **Status:** **REG-B implemented in repository** (callables `reg*` + emulator bootstrap); not deployed  
> **Implementation handover:** `SIBOL-REG-001-REG-B-AGENT-001`  
> **Work item:** SIBOL-REG-001  
> **Normative spec:** [SPEC-REG-001](../../Docs/Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md)  
> **ADRs:** [ADR-REG-001](../../Docs/Architecture/ADRs/ADR-REG-001-Organization-Identity-and-Membership.md), [ADR-REG-002](../../Docs/Architecture/ADRs/ADR-REG-002-Administrative-Authorization-and-Provisioning.md)

## Purpose

Define **proposed** HTTPS callable interfaces for organization lifecycle, staff invitations, membership approval, role assignment, suspension, and revocation. All interfaces are **server-authoritative**; Firestore client writes to privileged paths remain **denied** unless explicitly opened in a future rules change with matching tests.

## Common conventions

### Authentication

- Caller must present valid Firebase Auth ID token (`request.auth.uid`).

### Authorization

- Each callable loads **application account** (e.g. `accounts/{uid}` or extended `users/{uid}`) and relevant **memberships**.
- Central Administrator operations require `centralAdmin == true` (or equivalent membership role `central_admin` on a designated system org — implementation detail).
- Organization Administrator operations require active membership with `orgRole == org_admin` for the target `orgId`.
- **Active organization:** Staff callables that mutate org data require `contextOrgId` matching an active membership and, where applicable, caller’s `activeOrgId`.

### Audit

- On success, append document to `auditEvents/{eventId}` (or org-scoped subcollection) with: `eventType`, `actorUid`, `targetOrgId`, `targetUid`, `payloadSummary`, `createdAt` (server timestamp). Clients cannot write audit paths.

### Errors

- Use `HttpsError` codes: `unauthenticated`, `permission-denied`, `failed-precondition`, `not-found`, `invalid-argument`, `already-exists`.

### Idempotency

- Invitation and approval callables should accept optional `idempotencyKey` for safe retries (implementation detail).

---

## `bootstrapCentralAdmin` (one-time / PA-authorized)

**Caller:** Admin SDK script or PA-gated deploy only — **not** a public client callable in production.

**Input:** `{ email, displayName }` (password set via Auth invite or separate secure channel).

**Authorization:** Offline credentials / deploy gate.

**Effects:** Create Auth user; create account profile; grant Central Administrator flag.

**Output:** `{ uid }`

---

## `createOrganization`

**Caller:** Central Administrator.

**Input:**

```json
{
  "type": "barangay | hospital",
  "name": "string",
  "initialOrgAdminEmail": "string",
  "legacyBarangayLabel": "optional string for migration"
}
```

**Preconditions:**

- `type` allowed by policy.
- `name` non-empty.
- Initial org admin email not already Central Administrator unless policy allows.
- Caller is Central Administrator (`isCentralAdmin`).

**Organization identifier (INT-001-AMEND-001 / ADR-REG-003 proposed):**

- The server generates `orgId` as the Firestore document id (`generateOrgId()`); clients **must not** supply `orgId` on this callable.
- Validation: `shared/reg/src/org_id.mjs` (`isValidOrgId`). Demonstration ids: `barangay03`, `hospital01`.

**Effects:**

- Create `organizations/{orgId}` with `status: active`.
- Create invitation for initial Organization Administrator.
- Audit: `organization_created`, `org_admin_invited`.

**Output:** `{ orgId, invitationId }`

---

## `inviteStaffMember`

**Caller:** Organization Administrator (target org) or Central Administrator.

**Input:**

```json
{
  "orgId": "string",
  "email": "string",
  "orgRole": "string (permitted roles enum)"
}
```

**Preconditions:**

- Caller is org admin for `orgId` (or central admin).
- `orgRole` is in permitted set for org type; **not** `central_admin` or `org_admin` unless caller is central admin appointing org admin.

**Effects:**

- Create pending membership / invitation record.
- Send invitation (email — delivery mechanism PO/ops).
- Audit: `staff_invited`.

**Output:** `{ invitationId, membershipId }`

---

## `acceptStaffInvitation`

**Caller:** Invitee after Auth sign-up / sign-in.

**Input:** `{ invitationId }`

**Preconditions:**

- Auth email matches invitation.
- Invitation not expired or revoked.

**Effects:**

- Link `accountUid` to membership; set membership `status: pending` (awaiting org admin approval per DEC-008).

**Output:** `{ membershipId, status: "pending" }`

---

## `approveMembership` / `rejectMembership`

**Caller:** Organization Administrator for `orgId`.

**Input:** `{ membershipId, decision: "approve" | "reject", reason?: "string" }`

**Preconditions:**

- Membership `orgId` matches caller’s admin scope.
- **INV-NO-SELF-APPROVE:** `membership.accountUid != caller uid`.

**Effects:**

- Set membership `active` or `rejected`.
- Audit: `membership_approved` | `membership_rejected`.

---

## `assignOrgRole`

**Caller:** Organization Administrator.

**Input:** `{ membershipId, orgRole }`

**Preconditions:**

- Target membership in caller’s org.
- `orgRole` permitted; cannot assign `central_admin`.
- Cannot demote last active `org_admin` without central recovery flow.

**Effects:** Update `orgRole`; audit `role_assigned`.

---

## `setActiveOrganization`

**Caller:** Account owner with multiple active memberships.

**Input:** `{ orgId }`

**Preconditions:** Caller has `active` membership in `orgId`.

**Effects:** Set account `activeOrgId`; audit `active_org_changed`.

---

## `suspendMembership` / `revokeMembership`

**Caller:** Organization Administrator or Central Administrator (per policy).

**Input:** `{ membershipId, reason }`

**Effects:** `status: suspended` or `revoked`; audit event.

---

## `suspendAccount`

**Caller:** Central Administrator (or delegated policy).

**Input:** `{ accountUid, reason }`

**Effects:** Account `active: false`; optional Auth `disabled`; audit. **INV-ACCOUNT-SUSPEND.**

---

## `suspendOrganization`

**Caller:** Central Administrator.

**Input:** `{ orgId, reason }`

**Effects:** Organization `status: suspended`; audit.

---

## `recoverOrganizationAdmin`

**Caller:** Central Administrator.

**Input:** `{ orgId, newOrgAdminEmail }`

**Preconditions:** Org has zero active `org_admin` memberships or PA-declared emergency.

**Effects:** Invite/appoint org admin; audit `org_admin_recovered`.

---

## `registerTeenAccount`

**Caller:** Unauthenticated or newly authenticated teen (PO policy defines exact flow).

**Input (minimal — PO pending fields):**

```json
{
  "displayName": "optional string",
  "selectedBarangayOrgId": "string"
}
```

**Preconditions:**

- `selectedBarangayOrgId` references `organizations` with `type == barangay` and `status == active`.

**Effects:**

- Create teen account profile; store routing org id; **no** verified residency claim.
- Audit: `teen_registered` (minimal payload).

**Output:** `{ accountUid }`

---

## `completeTeenAuthRegistration`

**Caller:** Teen during Firebase Auth sign-up completion hook or callable immediately after Auth create.

**Input:** Auth uid + `registerTeenAccount` fields.

**Note:** Exact split between Auth triggers and callables is an implementation decision; must preserve server validation of `selectedBarangayOrgId`.

---

## Compatibility notes (demo)

- Existing `createCoordinationReferral` remains governed by [COORDINATION_REFERRAL_CONTRACT.md](COORDINATION_REFERRAL_CONTRACT.md) until migrated to membership/`orgId` checks.
- `submitReport` remains stub per [REPORTING_CONTRACT.md](REPORTING_CONTRACT.md) until Tranche 2 reporting implementation.

## Verification

See [MVR-REG-001](../../Docs/Verification/Records/MVR-REG-001-registration-authorization-verification-plan.md) — all procedures **NOT RUN**.
