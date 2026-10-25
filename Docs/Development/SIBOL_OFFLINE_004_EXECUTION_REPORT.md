# SIBOL-OFFLINE-004 — Offline organization presentation correction

**Handover UUID:** `e8b3a640-5c27-4f91-bd62-8a0e39c75416`  
**Starting HEAD:** `707c393`  
**Ending HEAD:** `11a269b`

## Defect

Offline **New case** and **Submit report** flows blocked before any write: `organizationDirectory/{orgId}` `get` / `snapshots` returned **`permission-denied`** when the directory document was missing on the emulator import. The UI surfaced raw Firestore errors via `AppErrorWidget`.

## Root cause

1. **Option A (data):** QA emulator snapshot lacked `organizationDirectory/barangay03` even though operational org/membership data existed.
2. **Option B (client):** Case and aggregate-report forms depended on a live directory stream with no trusted offline presentation cache; missing or denied reads were not distinguished from authorization failures.

## Authorized decision

- **A:** Idempotent emulator backfill for `organizationDirectory` (canonical names only).
- **B2:** Shared cache-first presentation resolver with per-user, per-org secure storage of last-known directory-derived labels.
- **Not in scope:** B3 `organizations/` name fallback; Firestore rules changes.

## Implementation

- `OrganizationDirectoryPresentationResolver` — prefers secure cache, then Firestore cache/server fetch, then directory watch; swallows watch errors when a trusted cache exists; emits `OrganizationPresentationUnavailable` when online initialization is required.
- `OrganizationPresentationCacheStore` — `FlutterSecureStorage`, keyed `sibol.org_presentation.v1.{uid}.{orgId}`.
- `cacheFirstOrganizationDirectoryPresentationProvider` wired through `barangayCaseOrgPresentationProvider` and `barangayReportOrgPresentationProvider`.
- `OrganizationDirectoryRepository.fetchEntryPreferCache` for local Firestore cache reads.

## Emulator backfill

Script: `shared/provisioning/scripts/backfill-organization-directory-emulator.mjs`  
Result: `organizationDirectory/barangay03` **created** with name **`Barangay 3 (Poblacion)`**; `hospital01` created.

## Verification

- Flutter: resolver unit tests, provider integration tests, updated `case_edit_screen_test.dart`.
- Firestore rules: deny `get` on missing `organizationDirectory` document (119 rules tests pass).
- Full Flutter suite: 168 tests pass.

## Limitations

- First-time offline use still requires one successful online directory resolution to populate the trusted cache.
- Other screens that read `organizationDirectoryEntryProvider` directly (e.g. coordination name widgets) are unchanged; only case-create and aggregate-report presentation paths use the cache-first resolver.
- Server-side membership and case/report rules remain authoritative; cached presentation is display-only.

## Manual offline QA

Not resumed per handover. After PO acceptance, repeat OFFLINE-QA-001 O4 with directory seeded and cache warmed online once.
