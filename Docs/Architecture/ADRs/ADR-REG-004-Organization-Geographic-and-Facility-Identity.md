# ADR-REG-004 — Organization geographic and facility identity

> **Status:** Proposed — **not self-approved** (M0 draft; SIBOL-ORG-IDENTITY-001)  
> **Handover:** SIBOL-ORG-IDENTITY-001-AGENT-001  
> **Related:** [ADR-REG-001](ADR-REG-001-Organization-Identity-and-Membership.md), [ADR-REG-003](ADR-REG-003-Organization-Identifier-Policy.md), [SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md](../../Development/SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md)  
> **Date:** 2026-10-25

## Context

SIBOL organizations require stable **internal** `orgId` (ADR-REG-003) and distinct **business identity** for Barangay and Hospital registration. Display names are not unique. Philippine official geography uses PSGC; hospitals use DOH NHFR facility codes. Investigation SIBOL-ORG-IDENTITY-001 (PLAN-001) documented gaps in the repository.

PO approved decisions D-02–D-13 and refinements F-01–F-08 (PLAN-002-REFINE-001).

## Decision

### Geographic identity (Barangay organizations)

1. **Business uniqueness key:** official **PSGC Barangay code** (`psgcBarangayCode`), not display name (D-02).
2. **Reference data:** versioned PSGC bundle; offline-capable in Flutter; ordinary selection does not depend on live PSA API (D-03).
3. **Hierarchy:** dataset-driven parent-child graph; UI supports province-based paths and direct region→city paths (HUC/ICC) without fabricating province codes (SIBOL-ORG-GEO-001, F-01).
4. **Versioning:** record `psgcVersion` at registration; no silent remap of codes across versions (D-04, F-05).

### Facility identity (Hospital organizations)

1. **Business uniqueness key:** normalized **NHFR facility code** (D-05).
2. **Reference data:** versioned NHFR snapshot; searchable offline when redistribution permitted (D-06).
3. **Scope:** hospitals only for prototype; RHUs excluded unless separately authorized (D-07).

### Identity registry

1. Collection **`organizationIdentityKeys`** with document ids `barangay:PSGC:{code}` and `hospital:NHFR:{code}` (D-12).
2. **Permanent reservation** in initial implementation: keys are not released on suspend; no reuse without future audited migration (F-07, R-06 deferred).
3. Uniqueness enforced in the **same transaction** as organization and initial invitation creation (F-04).

### Teen registration

1. Teen selects Barangay via controlled geography; server resolves PSGC → identity key → `orgId` (D-09, F-02).
2. No client-supplied `orgId` on production path; temporary emulator legacy shim per R-03.
3. Barangay change via re-registration is prohibited; future audited callable deferred (D-08, R-02).

### Demonstration compatibility

1. Synthetic orgs `barangay03` / `hospital01` use `synthetic_demo` identity keys; emulator-only legacy teen binding (D-13, R-03).
2. Synthetic identities must not appear as verified PSGC choices in geographic UI.

### Offline boundaries

1. **In scope:** offline PSGC (and NHFR when licensed) **reference** selection.
2. **Out of scope:** offline org-create confirmation and sync queue (SIBOL-OFFLINE-001).

## Consequences

- New contracts: CONTRACT-GEO-001, CONTRACT-NHFR-001, org-create idempotency, REG-001/REG-C amendments.
- `organization.schema.json` gains geographic and facility fields (proposed v2 schema).
- MVR-ORG-IDENTITY-001 required before production registration deploy.
- **G-NHFR** gate blocks production hospital registration until NHFR redistribution is established.

## Alternatives considered

| Alternative | Rejection |
|-------------|-----------|
| Uniqueness on display `name` | Fails homonym barangays (investigation) |
| Query `organizations` by PSGC without identity keys | Racy; not authoritative (F-02) |
| Release identity key on suspend | Rejected by PO refinement F-07 |

## Related

- [SPEC-REG-001 amend draft](../../Specifications/SPEC-REG-001-AMEND-ORG-IDENTITY-001.md)
- [CONTRACT-GEO-001](../../../shared/docs/CONTRACT-GEO-001-PSGC-Reference-Data.md)
- [CONTRACT-NHFR-001](../../../shared/docs/CONTRACT-NHFR-001-Facility-Reference-Data.md)
