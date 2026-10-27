# SIBOL-REG-002-HOTFIX-001 — Teen recovery menu visibility

**Handover UUID:** `e3a7d920-6b41-4f85-a2c0-9d76e58b143f`  
**Priority:** P0  
**Firebase:** `sibol-286d0` (no Auth changes in this hotfix)

## Root cause

1. **Navigation / discoverability (confirmed defect)**  
   REG-002 added **Teen account recovery** only as an `OutlinedButton` at the top of the **Staff management** list (`OrgAdminStaffScreen`). It was **not** linked from the Barangay **Organization administration** card or **Settings**, where org administrators already open staff tasks. SIBOL-DELIVERY-003 did not perform signed-in role navigation on device, so this gap was not caught before the PO walkthrough.

2. **Eligibility (not a code bug; common demo mistake)**  
   The menu is intended for accounts with active **org.manage_members** and **org.manage_roles** on a Barangay org (`membershipIsOrgAdministrator` / `orgAdminManagedOrgIdsProvider`). Live **`barangay.demo@sibol.local`** has operational capabilities only—no org-administration card and no teen recovery. Live **`barangay.org.admin@sibol.local`** has org-admin caps on `barangay03`. Hospital org admins (`moph.org.admin@sibol.local`, `hospital01`) correctly have staff management for a **hospital** org only; teen recovery remains Barangay-scoped.

3. **Staff screen org type (hardening)**  
   Staff screen visibility used `_organizationType` from `regListOrganizationMemberships` only. Hotfix resolves organization type from the **`organizations`** Firestore document first, then falls back to the callable response, so the Staff screen button stays aligned with canonical org type.

Backend authorization for REG-002 was **not** changed.

## Fix (Flutter)

| Area | Change |
|------|--------|
| `canAccessBarangayTeenRecoveryProvider` | Barangay org admins only (excludes central and hospital-home org admins) |
| `barangay_home_screen.dart` | **Teen account recovery** on org-administration card |
| `settings_screen.dart` | **Teen account recovery** when org admin |
| `org_admin_staff_screen.dart` | Firestore-backed org type for Barangay staff button |

Central Administrator path unchanged: **Teen account recovery** on `CentralAdminOrgDetailScreen` for Barangay orgs.

## Automated verification (no live sign-in)

| Suite | Result |
|-------|--------|
| `admin.teenRecovery.test.mjs` (emulators) | **12/12 pass** |
| `barangay_dashboard_capability_test.dart` | Org admin sees teen recovery; operational staff **does not** |
| `settings_screen_prototype_test.dart` | Org admin sees teen recovery in settings |
| `admin_teen_recovery_gate_test.dart` | Org admin vs staff gate |
| `org_admin_teen_recovery_visibility_test.dart` | Recovery screen denied without org admin |

**Not run:** Live Firebase sign-in or on-device UI walkthrough (no authorized credentials / procedure).

Optional future device test: `integration_test/barangay_org_admin_teen_recovery_device_test.dart` (requires PO-supplied password dart-define only).

## APK (Galaxy S9)

| Item | Value |
|------|--------|
| Install | `adb install -r` on **SM-G960U**, preserve app data |
| Defines | `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false` |
| SHA-256 | *(recorded at build in completion report)* |

## Manual UAT required (PO)

Sign in as **`barangay.org.admin@sibol.local`** (authorized password):

1. Barangay dashboard → Organization administration → **Teen account recovery** visible.
2. Settings → **Teen account recovery** visible.
3. Staff management → **Teen account recovery** visible (Barangay org).
4. Screen opens; teen list loads if index is READY (no password reset without separate approval).

Confirm **`barangay.demo@sibol.local`** does **not** show these entries.

## Classification

**PARTIAL** — Code fix, automated tests, and APK install complete; **live signed-in UI verification pending PO manual check**.
