# SIBOL-REG-005 — Barangay 3 PSGC registration resolution

**Handover UUID:** `c4a9e172-6b35-4d80-9f21-7e03b6a5c948`  
**Firebase:** `sibol-286d0`

## Root cause

Live teen registration uses PSGC path `regRegisterTeenAccount` → `resolveBarangayOrgIdFromPsgc`. After validating the geographic chain, production resolves org id via Firestore document:

`organizationIdentityKeys/barangay:PSGC:{psgcBarangayCode}`

**Read-only live state:**

| Resource | Status |
|----------|--------|
| `organizations/barangay03` | **Active** barangay; name `Barangay 3 (Poblacion)`; `legacyBarangayLabel` `Barangay 3, Balingasag` |
| `organizationDirectory/barangay03` | **Present** |
| `organizationIdentityKeys/barangay:PSGC:1004302022` | **Missing** |
| `organizationIdentityKeys/synthetic:demo:barangay03` | **Missing** |
| Functions env `SIBOL_ALLOW_DEMO_IDENTITY` / legacy binding | **Not set** on live (correct for production) |

Flutter selection (official bundle `psgc-psa-2025-2q`): Region `1000000000` → Misamis Oriental `1004300000` → Balingasag `1004302000` → **Barangay 3 (Poblacion)** `1004302022`.

Backend reached step 5 in GEO-001 investigation: missing identity key → `not-found` → client message *not yet registered for assistance routing*.

**Not** a Flutter bug, directory absence, or wrong org id on the organization record.

## Correction (source)

Pinned prototype map `1004302022` → `barangay03` in `prototypePinnedBarangayPsgc.ts`, used **only when** identity key is absent, after full PSGC validation and active-org checks (same as identity-key path). Unregistered codes still rejected. Identity-key path unchanged when provisioned.

Files:

- `shared/functions/src/geo/prototypePinnedBarangayPsgc.ts`
- `shared/functions/src/teen/resolveBarangayOrg.ts` (refactor + fallback)
- `shared/functions/test/teen.registration.barangay03.psgc.test.mjs`

## Tests

`teen.registration.barangay03.psgc.test.mjs` + `teen.registration.test.mjs` on Firestore emulator: **17/17 pass** (demo flags **off**).

## Deployment status — **LIVE** (PO-approved)

| Item | Detail |
|------|--------|
| Function | `regRegisterTeenAccount` |
| Project | `sibol-286d0` |
| Region | `us-central1` |
| Deployed | 2026-10-27 (authorized deploy after commit `420108b`) |
| Outcome | Successful update (cleanup-policy CLI warning only) |

**No Flutter/APK change** required for this defect.

**Alternative (not executed):** `organizationIdentityKeys/barangay:PSGC:1004302022` — optional canonical follow-up.

## PO orphan Auth account

Auth user without `users/{uid}` remains; **Continue Teen registration** + Barangay 3 (`1004302022`) should now resolve to `barangay03` and create the profile.

## Classification

**PARTIAL** — Live function deployed; PO should complete registration on device and confirm success screen / teen home.
