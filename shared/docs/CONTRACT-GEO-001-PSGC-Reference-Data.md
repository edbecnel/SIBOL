# CONTRACT-GEO-001 — PSGC reference data (draft)

> **Status:** Draft — M0; **not effective** until PA authorization  
> **Work item:** SIBOL-ORG-IDENTITY-001  
> **ADR:** [ADR-REG-004](../../Docs/Architecture/ADRs/ADR-REG-004-Organization-Geographic-and-Facility-Identity.md) (proposed)  
> **Acquisition:** [REFERENCE-DATA-PSGC-ACQUISITION.md](../../Docs/Development/REFERENCE-DATA-PSGC-ACQUISITION.md)

## 1. Purpose

Define versioned Philippine Standard Geographic Code (PSGC) reference artifacts, integrity rules, hierarchy validation, and supported-version policy for organization registration and teen geographic selection.

## 2. Authoritative source (EXTERNAL)

| Attribute | Value |
|-----------|--------|
| Publisher | Philippine Statistics Authority (PSA) |
| Classification | [PSGC](https://psa.gov.ph/classification/psgc) |
| Machine access | [PSA Classification API](https://psa.gov.ph/classifications-api/psgc) — `https://classification.psa.gov.ph/psgc/{version}/…` |
| Version examples | `Q2_2024` (documented on PSA API page); newer releases per PSA calendar |

SIBOL does **not** treat third-party mirrors as authoritative unless PSA terms allow and PA approves.

## 3. Artifact layout (proposed)

```
shared/geo-reference/
  manifests/psgc-{version}.json
  artifacts/psgc-{version}.sqlite   # or equivalent; commit per R-05
```

### 3.1 Manifest (`psgc-{version}.json`)

| Field | Type | Required |
|-------|------|----------|
| `version` | string | Y |
| `generatedAt` | ISO-8601 | Y |
| `sourceUrl` | string | Y |
| `sourceRetrievedAt` | ISO-8601 | Y |
| `artifactFile` | string | Y |
| `sha256` | string | Y |
| `supportedUntil` | ISO-8601 | N |

### 3.2 Graph model

Nodes: `code`, `level` (`region` | `province` | `city_mun` | `barangay`), `officialName`, `parentCode`, optional `cityClass` metadata for UI subtitles.

**Validation:** walk from barangay (or city_mun) to region via `parentCode`; reject orphan or cross-version codes.

### 3.3 Mixed administrative paths (F-01)

- Province path: region → province → city_mun → barangay.
- Direct city path: region → city_mun (HUC/ICC per dataset) → barangay.
- `psgcProvinceCode` **null/omitted** when not applicable.

## 4. Supported-version policy (F-05)

- Server exposes `supportedPsgcVersions[]` and `recommendedPsgcVersion`.
- Client submissions must use `psgcVersion ∈ supportedPsgcVersions`.
- Revoked versions: `failed-precondition` with instruction to update app (software update distinct from reference-only refresh).
- Server **never** silently maps superseded barangay code A → B.

## 5. Normalization

| Item | Rule |
|------|------|
| Code format | Store as string; preserve leading zeros per PSA export |
| Barangay identity key | `barangay:PSGC:{psgcBarangayCode}` |
| Names | Denormalized for display; regenerated from bundle on label refresh |

## 6. Flutter offline

- Bundle shipped in app assets; integrity check `sha256` on load.
- No live PSA API required for ordinary selection (D-03).

## 7. Callable (proposed)

`regGetReferenceManifest` — returns supported PSGC/NHFR versions and hashes (read-only).

## 8. Breaking changes

None until implementation handover; current repo has no PSGC contract.
