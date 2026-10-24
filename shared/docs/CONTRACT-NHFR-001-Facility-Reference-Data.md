# CONTRACT-NHFR-001 — NHFR facility reference data (draft)

> **Status:** Draft — M0; **production use blocked by G-NHFR**  
> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Gate:** [G-NHFR-REGISTER.md](../../Docs/Development/G-NHFR-REGISTER.md)  
> **Acquisition:** [REFERENCE-DATA-NHFR-ACQUISITION.md](../../Docs/Development/REFERENCE-DATA-NHFR-ACQUISITION.md)

## 1. Purpose

Define versioned National Health Facility Registry (NHFR) snapshots for hospital organization registration and offline facility search.

## 2. Authoritative source (EXTERNAL)

| Attribute | Value |
|-----------|--------|
| Publisher | Department of Health (DOH), Philippines |
| Public listing | [NHFR active facilities](https://nhfr.doh.gov.ph/VActivefacilitiesList) (bulk CSV/Excel per DOH FOI guidance) |
| Interoperability id | PH Core: system `https://fhir.doh.gov.ph/phcore/Identifier/doh-nhfr-code` |
| Live API | **Not assumed** for registration validation (D-06) |

## 3. Facility code normalization (proposed)

| Rule | Detail |
|------|--------|
| Canonical storage | Normalized string; 18-digit facility code where applicable |
| Identity key | `hospital:NHFR:{normalizedCode}` |
| Short code | Display only; not uniqueness key |
| Hospital filter | Include only facility types approved in acquisition doc (D-07: hospitals) |

## 4. Artifact layout (proposed)

```
shared/facility-reference/
  manifests/nhfr-{version}.json
  artifacts/nhfr-{version}.sqlite
```

Manifest fields mirror CONTRACT-GEO-001 (version, sha256, provenance).

## 5. Geographic linkage

- Each facility row should include `psgcCityMunCode` (and optional barangay) when present in source.
- Hospital create cross-validates selected PSGC path against facility row when data quality allows.

## 6. Synthetic fixtures (Track A — allowed before G-NHFR close)

- Files named `nhfr-synthetic-test-fixture-*` with manifest flag `synthetic: true`.
- **Must not** be used for production registration or committed as production artifacts without G-NHFR close.

## 7. Behavior if dataset unavailable

- **Production** `regCreateHospitalOrganization` with real NHFR: **disabled** until G-NHFR closed.
- Engineering may use synthetic fixture for validator unit tests only.

## 8. Breaking changes

None until implementation; current repo uses demo `hospital01` only.
