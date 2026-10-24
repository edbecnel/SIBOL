# CONTRACT-REG-001 — ORG-IDENTITY amendment (draft)

> **Status:** Draft — supersedes callable sections below **when implemented**; [CONTRACT-REG-001](CONTRACT-REG-001-Registration-and-Administration-Services.md) remains effective for current code  
> **Work item:** SIBOL-ORG-IDENTITY-001

## Summary of changes

| Callable | Change |
|----------|--------|
| `createOrganization` | **Deprecated** after INT-001 E2E; replaced by barangay/hospital-specific creates |
| `regCreateBarangayOrganization` | **New** |
| `regCreateHospitalOrganization` | **New** (G-NHFR gate for production) |
| `regGetReferenceManifest` | **New** (optional M2) |

## `regCreateBarangayOrganization`

**Caller:** Central Administrator.

**Input (required):** `psgcVersion`, `psgcRegionCode`, `psgcCityMunCode`, `psgcBarangayCode`, `initialOrgAdminEmail`, `idempotencyKey`; optional `psgcProvinceCode` (null when N/A), `displayNameAlias`, `legacyBarangayLabel`.

**Effects:**

1. Validate PSGC chain (CONTRACT-GEO-001).
2. Transaction: idempotency + `organizationIdentityKeys/barangay:PSGC:{code}` + org + org-admin invitation.
3. `status: active` (R-07).
4. Audit: `organization_created`, `org_admin_invited`.

**Output:** `{ orgId, invitationId, demoInvitationEmail }` (idempotent replay returns same).

**Errors:** `already-exists` (identity key), `invalid-argument` (PSGC), idempotency conflicts per [CONTRACT-ORG-CREATE-IDEMPOTENCY](CONTRACT-ORG-CREATE-IDEMPOTENCY.md).

## `regCreateHospitalOrganization`

**Caller:** Central Administrator.

**Input (required):** `nhfrSnapshotVersion`, `nhfrFacilityCode`, `psgcVersion`, geographic codes to city/mun minimum, `initialOrgAdminEmail`, `idempotencyKey`; optional address lines, `displayNameAlias`.

**Precondition:** G-NHFR **closed** for production; emulator may use synthetic NHFR fixture.

**Effects:** Same transactional pattern with `hospital:NHFR:{code}` identity key.

## Breaking vs compatibility

- **Breaking** for new clients expecting only `createOrganization`.
- **Non-breaking** for emulator seed until migration: legacy org documents without PSGC fields remain readable.
- Demo synthetic keys: implementation plan §10.

## Unchanged callables

`inviteStaffMember`, membership lifecycle, `setOrganizationStatus`, etc. — behavior preserved until separately amended.
