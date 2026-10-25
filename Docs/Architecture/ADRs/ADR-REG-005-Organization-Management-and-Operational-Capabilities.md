# ADR-REG-005: Organization management and operational capabilities (DEC-ORG-001)

> **Status:** Accepted  
> **Date:** 2026-10-25  
> **Work item:** SIBOL-ORG-001-FIX-001  
> **Decision id:** DEC-ORG-001

## Context

Barangay Organization Administrators receive membership capabilities for staff and role management (`org.manage_members`, `org.manage_roles`) but not automatic operational capabilities (`case.read`, `case.write`, `report.submit`, `coordination.barangay`). The Barangay dashboard previously subscribed all Barangay users to the case list stream, surfacing a `StateError` when case context could not be resolved.

ADR-REG-002 DEC-008 states organization administrators **cannot** gain case/teen confidential access by admin role alone.

## Decision

1. **Separate capability groups:** Organization management and Barangay operational responsibilities are independent; neither implies the other.
2. **Dual assignment:** A single account may hold both groups only when explicitly granted on its organization membership.
3. **`primaryOrgId`:** Identifies preferred organization context; it does **not** confer capabilities. Resolution still requires an active membership on that org with the required capability string.
4. **No implicit superuser:** Organization administrators do not receive operational capabilities by role or profile alone.
5. **UI:** Client surfaces management and operational actions based on resolved capabilities; hiding navigation is UX only—Firestore rules and Cloud Functions remain authoritative.
6. **Resolver invariants:** `OrgContextResolver` semantics are unchanged; providers must not return an org id without the matching capability.

## Consequences

- Management-only administrators use **Settings** and dashboard **Staff administration** without triggering unauthorized case queries.
- Operational staff use case, assistance, report, and coordination features when their membership includes the corresponding capability strings.
- Assigning operational capabilities to an existing administrator is done through the existing **OrgAdminStaffScreen** capability editor (server `updateMembershipCapabilities`) when product policy allows—no new subsystem in FIX-001.

## References

- [ADR-REG-002](ADR-REG-002-Administrative-Authorization-and-Provisioning.md) (DEC-008)
- [SIBOL_ORG_001_INV_001_INVESTIGATION_REPORT.md](../../Development/SIBOL_ORG_001_INV_001_INVESTIGATION_REPORT.md)
- [SIBOL_ORG_001_FIX_001_EXECUTION_REPORT.md](../../Development/SIBOL_ORG_001_FIX_001_EXECUTION_REPORT.md)
