# SIBOL-REG-001 — Production staff onboarding (deferred)

**Status:** **DEFERRED — NOT AUTHORIZED**  
**Recorded:** 2026-10-26 (handover `f2d86a41-7c93-4b50-a1e8-6d9c3f207b45`)

## Intended production workflow

1. Organization Administrator enters the staff member's **real** email address.
2. SIBOL sends a secure invitation email.
3. The email contains a **time-limited, single-use** registration link with an opaque token.
4. The recipient opens the link and establishes their **own** password.
5. The server validates invitation, email, organization, and permitted capabilities.
6. The staff member completes registration and receives the authorized membership.

Invitation tokens must not expose passwords or trusted client-controlled role assignments.

## Reuse

Implement on top of existing REG-B:

- `organizationStaffInvitations` lifecycle
- `regInviteStaffMember`, `regAcceptStaffInvitation`, membership approval policy
- Capability and org-type enforcement in [`shared/functions/src/admin/policy.ts`](../../shared/functions/src/admin/policy.ts)

## Academic prototype contrast

The prototype uses **direct** provisioning via `regProvisionStaffMember` and fictitious email identifiers — see [SIBOL_REG_001_DIRECT_PROVISIONING_EXECUTION_REPORT.md](SIBOL_REG_001_DIRECT_PROVISIONING_EXECUTION_REPORT.md).

## Out of scope until authorized

- Email delivery infrastructure
- Production registration deep links
- PO approval for production onboarding policy
