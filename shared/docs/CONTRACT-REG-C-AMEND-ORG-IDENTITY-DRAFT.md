# CONTRACT-REG-C — ORG-IDENTITY amendment (draft)

> **Status:** Draft — [CONTRACT-REG-C](CONTRACT-REG-C-Teen-Registration.md) remains effective for current implementation  
> **Work item:** SIBOL-ORG-IDENTITY-001

## `regRegisterTeenAccount` (target contract)

**Auth:** Required.

**Input (production):**

```json
{
  "selectedBarangayPsgcCode": "string",
  "psgcVersion": "string",
  "displayName": "optional",
  "privacyConsentAcknowledged": true
}
```

**Resolution (authoritative):** See implementation plan §9.1 — identity key first, then organization `status == active`.

**Effects:** Set `users.selectedBarangayOrgId` server-side only.

**Errors:** `not-found` (no org), `failed-precondition` (suspended/pending, different existing binding), `invalid-argument` (PSGC).

## Temporary compatibility (R-03) — emulator / CI only

When `SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING=true`:

**Additional input allowed:** `selectedBarangayOrgId` for allowlisted synthetic demo org (`barangay03`).

**Production:** Legacy input **rejected**.

**Removal gate:** After INT-001 connected E2E sign-off (documented in MVR-ORG-IDENTITY-001).

## `regListBarangayDirectory` (R-01 DEFER)

**No change** in this tranche. Security review: [SEC-REVIEW-001](../../Docs/Security/SEC-REVIEW-001-Barangay-Directory-Access.md).

Teen primary flow should use PSGC UI + resolution, not flat directory.

## Breaking changes

| Current | Target |
|---------|--------|
| `selectedBarangayOrgId` in input | `selectedBarangayPsgcCode` (production) |

Seeded emulator teens with existing `selectedBarangayOrgId` on profile: **unchanged** (no re-register required).
