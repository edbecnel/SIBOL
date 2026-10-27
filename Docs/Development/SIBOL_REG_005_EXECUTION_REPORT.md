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

## Deployment status — **BLOCKED pending authorization**

**Required:** deploy Cloud Function **`regRegisterTeenAccount`** to `sibol-286d0` (includes updated `resolveBarangayOrg`).

```bash
firebase deploy --only functions:regRegisterTeenAccount --project sibol-286d0
```

**No Flutter/APK change** required for this defect.

**Alternative (live data, not executed):** create `organizationIdentityKeys/barangay:PSGC:1004302022` pointing to `barangay03` (canonical long-term); would also require authorized Firestore write.

## PO orphan Auth account

Unchanged: Auth user without `users/{uid}` remains; after deploy, **Continue Teen registration** (P0 auth fix) + Barangay 3 selection should complete profile.

## Classification

**BLOCKED** until `regRegisterTeenAccount` live deploy (or authorized identity-key provisioning) is approved and executed.
