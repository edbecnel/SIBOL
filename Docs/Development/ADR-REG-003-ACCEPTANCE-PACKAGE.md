# ADR-REG-003 — Formal acceptance package

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Handover:** SIBOL-ORG-IDENTITY-001-AGENT-001 (M0)  
> **Target ADR:** [ADR-REG-003](../Architecture/ADRs/ADR-REG-003-Organization-Identifier-Policy.md)  
> **Disposition (D-01):** PO approved technical direction — **PA EDF acceptance pending**  
> **Date prepared:** 2026-10-25

## 1. Purpose

Provide evidence and procedure for elevating ADR-REG-003 from **Proposed** to **Accepted** without self-approval.

## 2. Alignment evidence

| ADR-REG-003 decision | Repository evidence (pre–ORG-IDENTITY implementation) |
|----------------------|------------------------------------------------------|
| Immutable `orgId` as document id | `runCreateOrganization`, `organization.schema.json` |
| `generateOrgId()` server-side | `shared/functions/src/admin/ids.ts` |
| `isValidOrgId` validation | `shared/reg/src/org_id.mjs`, rules, Flutter `OrgContextResolver` |
| Demo ids `barangay03`, `hospital01` | Provisioning, INT-001-AMEND-001 report |
| Membership `mbr_{orgId}__{uid}` | `shared/reg/src/membership_id.mjs` |

**Investigation:** [SIBOL_ORG_IDENTITY_001_INVESTIGATION_REPORT.md](SIBOL_ORG_IDENTITY_001_INVESTIGATION_REPORT.md) (VERIFIED).

## 3. Relationship to ORG-IDENTITY program

ADR-REG-003 covers **internal** `orgId` only. **Business identity** (PSGC barangay code, NHFR facility code) is defined in proposed [ADR-REG-004](../Architecture/ADRs/ADR-REG-004-Organization-Geographic-and-Facility-Identity.md). Acceptance of ADR-REG-003 does not imply acceptance of ADR-REG-004.

## 4. Recommended acceptance motion

**Motion:** Accept ADR-REG-003 as **Accepted**, superseding fixed `org` + 22-character REG-A notes for identifier validation and creation policy.

**Preconditions:**

1. PA records approval in EDF (meeting note, handover closure, or register entry).
2. ADR-REG-003 front matter updated to **Status: Accepted** with acceptance date and handover id — **only after** step 1.

## 5. Acceptance procedure (EDF)

1. PA reviews this package and investigation/plan traceability.
2. PO confirms D-01 remains in force.
3. PA issues acceptance record (reference UUID `9e4c72b1-6a35-4f08-b2d9-81c573e0a624` chain).
4. EA or PA updates ADR-REG-003 status field and [ADRs/README.md](../Architecture/ADRs/README.md) index.
5. CHANGELOG notes ADR-REG-003 accepted (separate from M0 doc commit if acceptance follows later).

## 6. Current status

| Item | Status |
|------|--------|
| ADR-REG-003 document | **Proposed** (unchanged in M0) |
| Acceptance package | **Prepared** (this document) |
| PA formal acceptance | **Not recorded** |

**Evidence of acceptance:** *None at M0 completion — awaiting PA.*
