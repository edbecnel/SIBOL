# G-NHFR — NHFR acquisition and redistribution gate

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Status:** **OPEN** (M0)

## Gate definition

Production use of **real** NHFR facility data in SIBOL (committed artifacts, mobile bundles, production `regCreateHospitalOrganization`) is **blocked** until all exit criteria below are satisfied.

## Exit criteria

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | PO/legal redistribution approval | Signed memo on file |
| 2 | Authoritative source and retrieval procedure | [REFERENCE-DATA-NHFR-ACQUISITION.md](REFERENCE-DATA-NHFR-ACQUISITION.md) |
| 3 | Hospital-only filter defined | CONTRACT-NHFR-001 + column mapping |
| 4 | Normalization rules tested on sample import | M1 report |
| 5 | Manifest + sha256 for first production snapshot | `shared/facility-reference/manifests/` |
| 6 | PA records gate closure in work register | WORK_ITEM_REGISTER update |

## Allowed before gate close

- Draft contracts and JSON schemas (M0).
- Synthetic test fixtures with `synthetic: true` manifest flag.
- Validator interface unit tests against synthetic data.

## Forbidden before gate close

- Committing production NHFR dumps without license evidence.
- Enabling real hospital registration in production Firebase.

## Owner

Product Owner (licensing); Project Architect (gate closure).

## Related blockers

- **G-PSGC-REDIST** — parallel track for PSA data (see REFERENCE-DATA-PSGC-ACQUISITION.md).
