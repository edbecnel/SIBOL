# SIBOL-ORG-IDENTITY-002 — Execution report

**Handover UUID:** `a83d9f24-6e51-4b72-9c04-18f2b5e670ad`  
**Date:** 2026-10-25  
**Starting HEAD:** `4236a46`  
**Ending HEAD:** _(see git log after push)_

## Summary

Barangay New Case and report aggregation now resolve organization identity from `barangayCaseOrgIdProvider` / `barangayReportOrgIdProvider` plus `organizations/{orgId}` Firestore streams (offline-cache friendly). Staff `assignedBarangay` is no longer used for those flows. Demo provisioning aligns new case seed strings with `DEMO_ASSIGNED_BARANGAY` and sets `legacyBarangayLabel` on demo barangay org creation (merge when field absent only).

## Organization resolution

- [`BarangayOrganizationPresentation`](sibol_app/lib/features/org/domain/barangay_organization_presentation.dart): `organizationName` ← `organizations.name`; `siteLabel` ← `legacyBarangayLabel` (required for case/report legacy `barangay` field).
- Providers: `barangayCaseOrganizationProvider`, `barangayCaseOrgPresentationProvider`, `barangayReportOrganizationProvider`, `barangayReportOrgPresentationProvider` in [`org_context_providers.dart`](sibol_app/lib/features/org/presentation/providers/org_context_providers.dart).
- New Case UI shows **Barangay organization** = registry `name`; persists `cases.barangay` = `siteLabel`; `cases.orgId` unchanged from membership resolver.

## New Case display (expected)

| Source field | Example value |
|--------------|----------------|
| Read-only **Barangay organization** | `Barangay 3 (Poblacion)` from `organizations/barangay03.name` |
| Subtext **Case site label** | `Barangay 3, Balingasag` from `organizations/barangay03.legacyBarangayLabel` |
| Persisted `orgId` | `barangay03` from membership |

If `orgId` is unauthorized, membership missing, org document missing, or `legacyBarangayLabel` absent → actionable `AppErrorWidget` (no `assignedBarangay` fallback).

## Report aggregation

- [`computeBarangayReportAggregate`](sibol_app/lib/features/reporting/domain/barangay_report_aggregate.dart) filters by **`orgId`**, not `cases.barangay` string equality.
- Report submit still sends `barangay: presentation.siteLabel` for contract compatibility.
- Teen assistance and MOPH report paths untouched.

## Offline

- `OrganizationRepositoryImpl.watchOrganization` uses Firestore `snapshots()`; cached org documents supply name and `legacyBarangayLabel` when offline after prior sync.

## Demo seed alignment

- [`case_payloads.mjs`](shared/provisioning/src/case_payloads.mjs): `BARANGAY` → `DEMO_ASSIGNED_BARANGAY`.
- [`demo_org_membership.mjs`](shared/provisioning/src/demo_org_membership.mjs) / [`emulator_seed.mjs`](shared/provisioning/src/emulator_seed.mjs): set `legacyBarangayLabel` on create; merge patch when field missing (does not overwrite existing profiles/cases).

## Tests

| Suite | Result |
|-------|--------|
| `sibol_app` `flutter test` | **156 passed** |
| `shared/firestore-rules-test` `npm test` | **109 passed** |
| `shared/provisioning` `npm test` | **14 passed** |

## Deferred / risks

- **Canonical QA emulator** org `barangay03` may lack `legacyBarangayLabel` until a one-field merge (seed merge-if-absent, or manual Firestore edit). Without it, New Case / report summary show registry error (by design).
- Existing cases (e.g. Maria Test) may still store legacy `barangay` strings; they remain readable via org-scoped queries.
- Long-term: PSGC-derived labels on org records (ORG-IDENTITY-001 plan) remain deferred.

## Android emulator acceptance (minimal)

1. Sign in as `barangay.demo@sibol.local` with emulators running and org `barangay03` having `legacyBarangayLabel: Barangay 3, Balingasag` (merge if missing).
2. **New case** → read-only organization shows **Barangay 3 (Poblacion)**; site subtext **Barangay 3, Balingasag**; create succeeds with `orgId` `barangay03`.
3. **Submit report** → total cases includes Maria Test and seeded cases regardless of mixed `cases.barangay` strings; reporting barangay line uses org site label.
4. **Teen assistance** → unchanged (still uses teen `assignedBarangay` in rules).
5. Open existing Maria Test case and follow-ups → still accessible.
