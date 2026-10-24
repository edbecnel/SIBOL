# SPEC-REG-001 — Amendment ORG-IDENTITY-001 (draft)

> **Status:** **Draft — not effective for implementation** until PA marks effective and issues implementation handover beyond M0  
> **Base spec:** [SPEC-REG-001](SPEC-REG-001-Registration-and-Organization-Authorization.md)  
> **Work item:** SIBOL-ORG-IDENTITY-001  
> **ADR:** [ADR-REG-004](../Architecture/ADRs/ADR-REG-004-Organization-Geographic-and-Facility-Identity.md) (proposed)

## 1. Scope of amendment

Adds organization **business identity**, geographic reference policy, facility identity, identity-key registry, and teen PSGC resolution. Does not change case coordination minimum-information (ADR-0005).

## 2. Organization registry (extends §5 DEC-001)

| Field class | Purpose |
|-------------|---------|
| `orgId` | Internal immutable identifier (ADR-REG-003) |
| `psgcBarangayCode` / NHFR code | Business identity (type-dependent) |
| `name`, `displayNameAlias` | Presentation (D-11, R-04) |
| `officialBarangayName` / `facilityOfficialName` | Official label from reference data |
| `psgcVersion` / `nhfrSnapshotVersion` | Pinned reference versions |

## 3. Uniqueness invariants (new)

- **INV-PSGC-BARANGAY-UNIQUE:** At most one reserved identity key per PSGC barangay code (all org statuses).
- **INV-NHFR-HOSPITAL-UNIQUE:** At most one reserved identity key per NHFR facility code (hospitals in scope).
- **INV-IDENTITY-KEY-AUTHORITATIVE:** Teen and admin resolution must use `organizationIdentityKeys` before trusting organization documents.
- **INV-NO-CLIENT-ORGID-CREATE:** Clients cannot supply `orgId` on create or teen register (production).

## 4. Organization creation (extends administrative hierarchy)

- Central Administrator creates Barangay/Hospital orgs via PSGC/NHFR-validated callables (see CONTRACT-REG-001 amendment draft).
- Default `status: active` (R-07); schema retains `pending` for future policy.
- Mandatory creation **idempotency** (F-04).

## 5. Teen registration (extends §6.2 DEC-003)

- Routing via **PSGC selection** and server resolution to `selectedBarangayOrgId`.
- Barangay selection is not proof of residency.
- Re-registration with different Barangay **rejected** (D-08).

## 6. Breaking changes (when implemented)

| Area | Current (repo) | Target |
|------|----------------|--------|
| `regCreateOrganization` | Free-text name | PSGC/NHFR callables (legacy deprecated post–INT-001 E2E) |
| `regRegisterTeenAccount` | `selectedBarangayOrgId` | `selectedBarangayPsgcCode` (+ R-03 emulator shim) |
| `organizations` documents | No PSGC fields | Extended schema v2 |

**Compatibility:** Synthetic demo orgs and seeded users per implementation plan §10.

## 7. Non-goals (unchanged)

Organization self-registration; teen barangay change callable (R-02 deferred); identity key release (R-06 deferred).
