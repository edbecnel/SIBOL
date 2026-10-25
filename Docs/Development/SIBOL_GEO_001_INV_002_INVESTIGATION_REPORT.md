# SIBOL-GEO-001 — INV-002 Investigation Report (Teen assistance routing)

**Handover:** SIBOL-GEO-001-FIX-002  
**Work item:** SIBOL-GEO-001  
**Status:** Accepted findings; correction implemented in FIX-002  

## 1. Verified root cause

Teen PSGC registration persisted **`selectedBarangayOrgId`** (organization binding) but not **`assignedBarangay`** (human-readable routing label required by assistance submission).

| Layer | Behavior |
|-------|----------|
| `runRegisterTeenAccount` (pre-FIX-002) | Wrote `selectedBarangayOrgId` only on `users/{uid}` create |
| Flutter `AssistanceRequestFormScreen` | Blocked submit when `assignedBarangay` empty (client guard before callable) |
| `runSubmitTeenAssistanceRequest` | Required both `selectedBarangayOrgId` and non-empty `assignedBarangay` |

**QA Teen 03 (emulator):** `selectedBarangayOrgId=barangay03`, `assignedBarangay` absent, `onboardingStatus=complete`. Failed submit did not create assistance or idempotency records.

## 2. Registration persistence contract (post-FIX-002)

| Field | Authority | Source |
|-------|-----------|--------|
| `selectedBarangayOrgId` | Organization routing | Server resolution from PSGC identity key or allowlisted legacy org (unchanged) |
| `assignedBarangay` | Assistance label | **PSGC path:** `{barangay.officialName}, {city_mun.officialName}` from verified bundle selection (`teenAssignedBarangay.ts`). **Legacy allowlist path:** `organizations/{orgId}.legacyBarangayLabel` when PSGC codes are not supplied |

Client cannot supply `assignedBarangay` or arbitrary org assignment. PSGC hierarchy validation reuses `validateBarangaySelection`.

## 3. Assistance submission contract

Unchanged security posture:

- Teen must be active with valid `selectedBarangayOrgId` and non-empty `assignedBarangay`.
- Target organization must exist, type `barangay`, status `active`.
- Flutter validates category/description, then routing fields, then invokes callable / offline queue.

Flutter error copy no longer references “demo profile” for missing `assignedBarangay`.

## 4. Accepted correction (FIX-002)

- `shared/functions/src/teen/teenAssignedBarangay.ts` — trusted label resolution.
- `registerTeenAccount.ts` — persist `assignedBarangay` on first profile create.
- Registration idempotency unchanged (no silent backfill on repeat registration).

## 5. Existing-account compatibility

Profiles created before FIX-002 (e.g. QA Teen 03) remain valid for sign-in but **cannot submit assistance** until `assignedBarangay` is set.

**Narrow repair (requires PO approval; not executed during FIX-002):**

1. Confirm `users/{teenUid}.selectedBarangayOrgId === barangay03` (or expected org).
2. Confirm `organizations/barangay03` is `type: barangay`, `status: active`.
3. Set `assignedBarangay` on the teen profile only:
   - **Preferred for PSGC-registered teens:** derive from PSA bundle for the barangay code used at registration (e.g. `1004302022` → `Barangay 3, Balingasag` per `psgc-psa-2025-2q`), **or**
   - **Demo alignment with seeded users:** match `legacyBarangayLabel` / `DEMO_ASSIGNED_BARANGAY` (`Barangay Tres, Balingasag`) if product accepts demo label over PSA official name for emulator QA only.

Procedure detail: [SIBOL_GEO_001_QA_TEEN_03_PROFILE_REPAIR.md](SIBOL_GEO_001_QA_TEEN_03_PROFILE_REPAIR.md).

No automatic migration in production; optional future callable or batch job is out of scope for FIX-002.

## 6. Regression coverage

| Area | Tests |
|------|--------|
| PSGC registration + `assignedBarangay` | `teen.registration.test.mjs`, `org_identity.test.mjs` |
| Label resolution rules | `teen.assignedBarangay.test.mjs` |
| Assistance guards | `assistance_submission.test.mjs` (existing) |

## 7. Architectural debt

- **`assignedBarangay` vs PSGC codes on user profile:** Assistance still keys off a legacy string label; long-term model should store PSGC barangay code on the teen profile and derive display labels at read time, or require org `legacyBarangayLabel` only for migration-era accounts.
- **Demo shim `1004302022 → barangay03`:** Emulator-only; production teens must resolve via `organizationIdentityKeys`.
- **`organizations/barangay03` without `legacyBarangayLabel`:** Legacy allowlist registration depends on org label; PSGC registration does not.

## 8. References

- INV-001: [SIBOL_GEO_001_INV_001_INVESTIGATION_REPORT.md](SIBOL_GEO_001_INV_001_INVESTIGATION_REPORT.md)
- Execution: [SIBOL_GEO_001_EXECUTION_REPORT.md](SIBOL_GEO_001_EXECUTION_REPORT.md)
