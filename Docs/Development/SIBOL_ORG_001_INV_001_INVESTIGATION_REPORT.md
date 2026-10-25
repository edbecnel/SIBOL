# SIBOL-ORG-001 — INV-001 Investigation Report

**Work item:** SIBOL-ORG-001-INV-001  
**Subject:** Barangay organization administrator dashboard organization-context failure  
**Repository baseline:** `60bdafd`  
**Emulator:** Firestore `127.0.0.1:8195`, project `sibol-286d0`

## 1. Observed failure

Account `barangay.org.admin@sibol.local` (UID `WZj7Seh3qNUlGfnDaYbL1RBA4bNV`) reached the Barangay dashboard after successful Auth. The case list area showed:

`Bad state: Organization context is not available. Check membership and primaryOrgId.`

Navigation buttons remained visible.

## 2. Error origin

[`sibol_app/lib/features/cases/presentation/providers/case_providers.dart`](../../sibol_app/lib/features/cases/presentation/providers/case_providers.dart) — `casesStreamProvider` emits `StateError` when `barangayCaseOrgIdProvider` is null.

[`barangay_home_screen.dart`](../../sibol_app/lib/features/cases/presentation/screens/barangay_home_screen.dart) (pre-FIX-001) watched that provider unconditionally for the case list.

## 3. Verified administrator profile

| Field | Value |
|-------|--------|
| `role` | `barangay` |
| `active` | `true` |
| `primaryOrgId` | `barangay03` |
| `displayName` | `Demo Barangay Org Administrator` |

## 4. Verified membership

Document `organizationMemberships/mbr_barangay03__WZj7Seh3qNUlGfnDaYbL1RBA4bNV`:

| Field | Value |
|-------|--------|
| `orgId` | `barangay03` |
| `status` | `active` |
| `capabilities` | `org.manage_members`, `org.manage_roles` |

No `case.read`, `case.write`, `report.submit`, or `coordination.barangay`.

## 5. Resolver behavior (correct)

[`OrgContextResolver.barangayOrgForCases`](../../sibol_app/lib/features/org/domain/org_context_resolver.dart) requires active membership on `primaryOrgId` granting `case.read`. With management-only caps, resolution returns `null` — by design ([`org_context_resolver_test.dart`](../../sibol_app/test/org_context_resolver_test.dart)).

## 6. Root cause

**UI contract mismatch:** the dashboard treated all Barangay sign-ins as operational users and subscribed to the case stream even when membership did not authorize `case.read`. Not a missing membership, wrong org, or GEO regression.

## 7. Management surfaces (existing)

- **Settings → Organization staff administration** — [`settings_screen.dart`](../../sibol_app/lib/features/settings/presentation/screens/settings_screen.dart) via `orgAdminManagedOrgIdsProvider` (`org.manage_members`).
- **Staff / capabilities** — [`OrgAdminStaffScreen`](../../sibol_app/lib/features/admin/presentation/screens/org_admin_staff_screen.dart) (`updateMembershipCapabilities` for `case.read` / `case.write` on staff memberships).

## 8. Correction direction

DEC-ORG-001 / FIX-001: capability-aware dashboard; preserve resolver and seed separation.
