# SIBOL-ORG-001 — INV-002 Investigation Report

**Work item:** SIBOL-ORG-001-INV-002  
**Subject:** Firestore membership `PERMISSION_DENIED` and missing Organization administration card  
**Baseline:** `bdf8fdc`

## Root cause

The Flutter client listed memberships with:

`organizationMemberships.where('accountUid', isEqualTo: uid)`

Firestore rules at `organizationMemberships/{membershipId}` require `membershipId == mbr_{orgId}__{uid}`. That constraint cannot be proven for a collection **list** filtered only on `accountUid`, so the query is denied (rules L241; catch-all deny L492 in diagnostics).

Direct **get** on `mbr_barangay03__{uid}` is authorized. Admin SDK reads during INV-001 did not reflect client rule evaluation.

## Symptoms

- `accountMembershipsProvider` yielded empty memberships.
- `orgAdminManagedOrgIdsProvider` hid the administration card.
- Operational org-id providers also saw empty memberships.
- FIX-001 made the administration card depend on loaded capabilities, exposing the defect.

## Correction direction (FIX-002)

Listen to the canonical membership document using `users/{uid}.primaryOrgId` and `mbr_{primaryOrgId}__{uid}` without weakening rules or enumerating the collection.

## References

- [SIBOL_ORG_001_FIX_002_EXECUTION_REPORT.md](SIBOL_ORG_001_FIX_002_EXECUTION_REPORT.md)
- [ADR-REG-005](../Architecture/ADRs/ADR-REG-005-Organization-Management-and-Operational-Capabilities.md)
