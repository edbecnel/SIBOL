# SIBOL-GEO-001-INV-001 — Investigation Report

**Handover:** SIBOL-GEO-001-INV-001 (read-only investigation)  
**Follow-up:** SIBOL-GEO-001-FIX-001 (configuration recovery)  
**Repository HEAD at investigation:** `ffbb427`  
**Date:** 2026-10-25  

## 1. Observed QA failure

After selecting official PSGC geography (Region X → Misamis Oriental → Balingasag → Barangay 3) and consent, **Complete registration** showed:

> This Barangay is not yet registered for assistance routing in SIBOL. Choose another Barangay or contact your administrator.

Geographic selection: **PASS**. Registration submission: **FAIL**.

## 2. Evidence collected (read-only)

| Check | Method | Result |
|-------|--------|--------|
| Functions worker env | `ps eww` on emulator Functions runtime (port 5001) | **No** `SIBOL_ALLOW_*` variables |
| `organizations/barangay03` | Admin SDK → Firestore emulator `8195` | **Exists**, `status=active` |
| `organizationIdentityKeys/barangay:PSGC:1004302022` | Same | **Missing** |
| `organizationIdentityKeys/synthetic:demo:barangay03` | Same | **Missing** |
| Built Functions code | `shared/functions/lib/teen/resolveBarangayOrg.js` | Includes `demoPsgcShim` (GEO-001 at `ffbb427`) |
| Flutter error mapping | `user_error_message.dart` | Maps backend `"not registered in SIBOL"` to PO message |

Automated Teen registration submit during investigation: **not performed**.

## 3. Registration resolution path

1. Flutter `registerTeenAccount` sends `selectedBarangayPsgcCode` = barangay PSGC (expected `1004302022` for Barangay 3).
2. `regRegisterTeenAccount` → `resolveBarangayOrgIdFromPsgc`.
3. PSGC chain validated against bundle `psgc-psa-2025-2q`.
4. If `SIBOL_ALLOW_DEMO_IDENTITY === "true"`: `demoPsgcShim` maps `1004302022` → `barangay03`, then `resolveLegacyTeenOrgId` (requires `SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING === "true"`).
5. Otherwise: lookup `organizationIdentityKeys/barangay:PSGC:1004302022`; missing document → `AuthzError` **not-found** with message *Selected Barangay is not registered in SIBOL yet.*

**Failure point (verified):** Step 5 with demo flags **off** and identity key **absent**.

## 4. Root cause

**Primary:** Local Functions emulator process did not have demonstration environment flags set, so the authorized PSGC→`barangay03` shim never ran.

**Contributing:** No `barangay:PSGC:1004302022` identity key in emulator data (normal for demo seed; not required when shim + flags work).

**Not cause:** Missing `organizations/barangay03` (present). Stale pre-GEO Functions build (shim present in built lib).

**Documentation gap:** SIBOL-GEO-001 completion report emphasized `SIBOL_ALLOW_DEMO_IDENTITY` only; code also requires **`SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING`** for the shim path because it calls `resolveLegacyTeenOrgId`.

## 5. Production safeguards

- Flags are read only from `process.env` at runtime (`demoFlags.ts`); default is **disabled** when unset.
- `demoPsgcShim.ts` is explicit, pinned map (`1004302022` → `barangay03`); not a generic bypass.
- Production deploy is **not** authorized to set these variables.
- Firestore rules unchanged; no client-side org assignment.

## 6. Proposed recovery (SIBOL-GEO-001-FIX-001)

1. **Configuration (emulator-only):** Export both flags before starting (or when restarting) the emulator stack via gitignored `.env.emulator.local` sourced from updated `.env.emulator.example`.
2. **Functions worker reload:** Environment variables are inherited when the Functions emulator **child process** starts. A **running** emulator cannot pick up new flags without reloading Functions (typically restarting `firebase emulators:start` in the operator terminal). **Do not** reset Firestore/Auth data; preserve import/export flags if used.
3. **No data reseed** required for shim path: `organizations/barangay03` already active.
4. **No** new `organizationIdentityKeys` document required when shim + flags are active.

## 7. Operator restart procedure (approval required — not executed by EA)

When the PO approves restart **without** clearing data:

```bash
# 1. In the terminal running emulators: Ctrl+C (graceful stop).
#    If you use persistence, ensure prior session used --export-on-exit or note import path.

# 2. From repo root, ensure local env includes demo flags (see .env.emulator.example).
cp -n .env.emulator.example .env.emulator.local   # if not already present
# Edit .env.emulator.local: set both SIBOL_ALLOW_* lines to true (uncommented).

# 3. Start emulators (add --import=... if you normally use saved data).
source .env.emulator.local
./shared/scripts/start-demo-emulators.sh
# Example with persistence:
# ./shared/scripts/start-demo-emulators.sh --import=./.emulator-data/int-001 --export-on-exit

# 4. Verify flags on new Functions worker (optional):
# ps ewwp $(lsof -t -i :5001 | head -1) | tr ' ' '\n' | grep SIBOL_

# 5. On Android: tap Complete registration again (same account; no app data clear).
```

**Risks:** Stopping emulators without export may lose in-memory Firestore/Auth changes since last export; use the same `--import` path as before when available.

## 8. Verification after restart (PO)

- Teen registration completes for Barangay 3 without “not yet registered” error.
- No production configuration change.
