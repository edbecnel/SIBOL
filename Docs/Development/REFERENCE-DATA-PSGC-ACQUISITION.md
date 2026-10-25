# PSGC reference data — acquisition and redistribution (M0)

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Contract:** [CONTRACT-GEO-001](../../shared/docs/CONTRACT-GEO-001-PSGC-Reference-Data.md)  
> **Gate ID:** **G-PSGC** (redistribution)

## Publisher and official source

| Item | Detail |
|------|--------|
| Publisher | Philippine Statistics Authority (PSA) |
| Official page | https://psa.gov.ph/classification/psgc |
| API documentation | https://psa.gov.ph/classifications-api/psgc |
| API base | `https://classification.psa.gov.ph/psgc` |

## Dataset version (pin for M1 planning)

| Field | M0 recommendation |
|-------|-------------------|
| Initial pin | `Q2_2024` (listed on PSA API documentation at M0 preparation) |
| **SIBOL-GEO-001 shipped pin** | `psgc-psa-2025-2q` (PSA publication **2025-06-30**, build manifest in `shared/geo-reference/manifests/`) |
| Selection authority | PA confirms pin at M0 checkpoint |

## Availability and format

- PSA provides versioned JSON via Classification API (`regions`, `provinces`, `municipalities`, `barangays`, filters `reg`, `prv`, `mun`, `bgy`).
- API may require **access token** query parameter per PSA docs — treat tokens as ops secrets, not committed.
- Downloadable masterlists also published on PSA site for offline normalization.

## License and redistribution (R-05)

| Status | **CONDITIONAL — not fully verified at M0** |
|--------|---------------------------------------------|
| M0 finding | Public accessibility does **not** imply mobile app redistribution rights |
| Required | PO/legal written determination: may SIBOL commit normalized `artifacts/` and ship in Flutter assets? |
| If denied | CI secure fetch at build time; document provenance only in repo |

**Blocker:** **G-PSGC-REDIST** — open until PO signs redistribution memo.

## Integrity and provenance

- Record `sourceUrl`, `sourceRetrievedAt`, `sha256` in manifest (CONTRACT-GEO-001).
- Reproducible build script documented in M1 (not implemented in M0).

## Identifier format and normalization

- Store codes as strings; preserve leading zeros from PSA export.
- Barangay business key: full PSGC barangay code per pinned version.
- Identity document id: `barangay:PSGC:{code}`.

## Known gaps

- Token management for API automation.
- Whether latest 2025 PSA releases are API-listed (verify at acquisition time).
- Attribution requirements for in-app “Data source: PSA” notice (PO).

## M1 readiness

| Prerequisite | Status |
|--------------|--------|
| PA version pin | Pending |
| G-PSGC-REDIST | **OPEN** |
| Acquisition procedure documented | **Complete (this doc)** |
