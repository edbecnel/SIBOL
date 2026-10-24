# NHFR reference data — acquisition and redistribution (M0)

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Contract:** [CONTRACT-NHFR-001](../../shared/docs/CONTRACT-NHFR-001-Facility-Reference-Data.md)  
> **Gate:** [G-NHFR-REGISTER.md](G-NHFR-REGISTER.md)

## Publisher and official source

| Item | Detail |
|------|--------|
| Publisher | Department of Health (DOH), Philippines |
| Registry | National Health Facility Registry (NHFR) |
| Public list | https://nhfr.doh.gov.ph/VActivefacilitiesList |
| Bulk export | CSV/Excel per DOH guidance (see FOI reference on nhfr.doh.gov.ph) |
| Interoperability | PH Core FHIR identifier system `https://fhir.doh.gov.ph/phcore/Identifier/doh-nhfr-code` |

## Dataset version

| Field | M0 status |
|-------|-----------|
| Pin version | **Not assigned** — awaits first successful licensed import |
| Update cadence | Proposed quarterly ops review (PO) |

## Availability and format

- Bulk facility list suitable for snapshot normalization.
- **Per-facility live validation API:** not assumed (EXTERNAL; e-referral community notes limited query support).
- SIBOL validation model: **versioned snapshot** at create time (D-06).

## License and redistribution

| Status | **NOT ESTABLISHED — G-NHFR OPEN** |
|--------|-----------------------------------|
| M0 finding | DOH data may be publicly listed but **redistribution into mobile app bundles requires explicit permission** |
| Required | PO/legal memo on NHFR CSV redistribution, attribution, and field minimization |

## Facility code representation

| Form | Use |
|------|-----|
| 18-digit NHFR code | Canonical `businessCode` and identity key |
| 5-digit short code | UI hint only |
| Normalization | Strip whitespace; validate length/checksum rules in M1 validator spec |

## Hospital-type classification (D-07)

- M0: define allowed `facilityType` / category values when first dump is inspected.
- Exclude RHU and non-hospital types from production picker until PO expands scope.

## Geographic linkage quality

- Expect `city/municipality` and sometimes barangay fields in dump; document completeness % during first import.
- Cross-check against PSGC city/mun codes during hospital create (implementation).

## Validation of source completeness

- M1: row counts vs DOH published totals; duplicate facility code scan; null rate on required columns.

## Behavior if blocked

- **Production** hospital registration: **disabled**.
- **Track A:** synthetic `nhfr-synthetic-test-fixture` for schema/validator tests only — labeled non-authoritative.

## M1 readiness

| Item | Status |
|------|--------|
| G-NHFR | **OPEN** |
| Acquisition doc | **Complete** |
| Real artifact in repo | **Blocked** |
