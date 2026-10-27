# SIBOL-REG-003 — Hospital organization creation execution report

**Handover UUID:** `9d2a7f41-6e83-4b50-a129-7c4e95d0b638`  
**Firebase:** `sibol-286d0` — **no live changes**  
**Authorization:** Local implementation, tests, EDF, git push only

## Root cause

Central **Create organization** used **Hospital (MOPH)** mode with an **NHFR facility dropdown** (`nhfr-synthetic-demo-v1.json` contains a **single** synthetic facility). That UI selects a **predefined NHFR identity**, not an existing organization — but it blocked entering real hospital names.

## Backend assessment

| Callable | Arbitrary hospital name |
|----------|-------------------------|
| `regCreateHospitalOrganization` | No — requires `nhfrFacilityCode` + identity key reservation |
| `regCreateOrganization` | **Yes** — `type: hospital`, `name` (central admin only) |

Correction: Flutter hospital path now calls **`regCreateOrganization`** with a free-text **Hospital name** field. NHFR callable retained for identity-key provisioning (unchanged).

## Changes

- Flutter: `create_organization_screen.dart` — hospital name text input; barangay flow unchanged
- Flutter: `organization_name_validation.dart` + unit tests
- Functions: `assertOrganizationName`, whitespace normalize, duplicate active hospital name check
- Tests: `admin.hospitalOrganizationCreate.test.mjs`

## Verification

- Emulator tests for create, duplicate denial, non-central denial
- Flutter unit tests for name validation
- `hospital01` / live orgs not modified

## Deployment

- **Functions deploy** required for duplicate-name check on server (optional if only client updated — server validation recommended)
- **APK rebuild** required for Central Admin UI change
- **Not authorized** in this handover
