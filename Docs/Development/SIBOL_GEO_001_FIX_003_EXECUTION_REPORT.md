# SIBOL-GEO-001-FIX-003 — Execution Report

**Work item:** SIBOL-GEO-001-FIX-003  
**Base HEAD:** `c8030f1`  
**Scope:** Local Firebase emulators only (`sibol-286d0`, Firestore `127.0.0.1:8195`)

## 1. PSGC identity (code `1004302022`)

| Level | Code | Official name (PSA `psgc-psa-2025-2q`) |
|-------|------|----------------------------------------|
| Barangay | `1004302022` | Barangay 3 |
| Municipality | `1004302000` | Balingasag |

Assistance routing label applied: **`Barangay 3, Balingasag`** (barangay + municipality, consistent with FIX-002). Organization **display name** set to **`Barangay 3 (Poblacion)`** per PO acceptance (distinct from PSA `officialName` on the org record).

## 2. Emulator preconditions

| Check | Result |
|-------|--------|
| `git HEAD` | `c8030f1` |
| Firestore emulator | `127.0.0.1:8195` reachable |
| Backup `.firebase-qa-backups/pre-fix-002/` | Valid `firebase-export-metadata.json` (Firestore + Auth export paths) |
| `organizations/barangay03` | `type=barangay`, `status=active`, `orgId=barangay03` |
| QA Teen 03 | Single match `displayName=QA Teen 03`, `selectedBarangayOrgId=barangay03`, `assignedBarangay` absent |
| Memberships on `barangay03` | **3** (unchanged after repair) |

## 3. Emulator repair (executed)

Script: `shared/functions/scripts/repair-geo-fix-003-emulator.mjs`  
Guards: requires `FIRESTORE_EMULATOR_HOST=127.0.0.1:8195`, project `sibol-286d0`, backup metadata, and precondition field checks; aborts if `assignedBarangay` already set.

| Document | Field | Before | After |
|----------|-------|--------|-------|
| `organizations/barangay03` | `name` | `Barangay Tres` | `Barangay 3 (Poblacion)` |
| `users/pjHSdYK7Vh2qYAnBzu6FmMeWjUMU` | `assignedBarangay` | *(missing)* | `Barangay 3, Balingasag` |

No other fields intentionally modified. Auth accounts untouched.

## 4. Seed-source corrections

| File | Change |
|------|--------|
| `shared/provisioning/src/constants.mjs` | `DEMO_BARANGAY_ORG_NAME`, `DEMO_ASSIGNED_BARANGAY` |
| `shared/migration/src/demo_orgs.mjs` | `DEMO_BARANGAY_ORG_NAME`, `DEMO_BARANGAY_LABEL` |
| `shared/migration/fixtures/demo_org_mapping.json` | Canonical label `Barangay 3, Balingasag` → `barangay03` (loader allows one label per orgId) |

**Not changed (historical fiction):** `shared/provisioning/src/case_payloads.mjs`, seeded case/report `barangay` strings still referencing `Barangay Tres, Balingasag` where already written; `sibol_app/lib/config/app_config.dart` demo filter string unchanged.

## 5. Resume Android QA

1. Keep emulators running (no restart required for Firestore field updates).
2. Hot-restart Flutter or sign out/in so `userProfileProvider` loads `assignedBarangay`.
3. Open the existing assistance request draft and submit when ready (not executed in this work item).

## 6. References

- [SIBOL_GEO_001_QA_TEEN_03_PROFILE_REPAIR.md](SIBOL_GEO_001_QA_TEEN_03_PROFILE_REPAIR.md) (procedure; repair executed under FIX-003 authorization)
- [SIBOL_GEO_001_INV_002_INVESTIGATION_REPORT.md](SIBOL_GEO_001_INV_002_INVESTIGATION_REPORT.md)
