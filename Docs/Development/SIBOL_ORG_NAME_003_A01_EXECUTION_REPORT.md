# SIBOL-ORG-NAME-003 A01 — Execution report

**Handover UUID:** `e4b7a291-5c63-4e08-9d17-2f68b30c9a45`  
**Starting HEAD:** `46d9abc`  
**Checkpoint A commit:** `93e0006` — directory schema, rules, projection, provisioning sync  
**Checkpoint B commit:** _(see ending HEAD below)_ — Flutter directory integration and UI

## Directory schema and rules

- Contract: `shared/contracts/organization_directory.schema.json`
- Rules: `organizationDirectory/{orgId}` — `get` for active users with field validation; `list` and client writes denied
- Rules tests: `shared/firestore-rules-test/test/organization_directory.rules.test.mjs` (includes suspended status get, organizations read denied)

## Trusted projection and backfill

- `shared/functions/src/admin/organizationDirectoryProjection.ts` on org create and status update
- Idempotent emulator backfill: `shared/provisioning/scripts/backfill-organization-directory-emulator.mjs`
- **Local emulator backfill (2026-10-25):** `barangay03` and `hospital01` **created**; `organizations/*` unchanged

Verified `organizationDirectory/barangay03`:

- `name`: Barangay 3 (Poblacion)
- `geographicSiteLabel`: Barangay 3, Balingasag

## Flutter integration

Shared layer: `OrganizationDirectoryEntry`, repository (`snapshots()` / `get()` for offline cache), providers, `OrganizationDirectoryNameText` / `OrganizationIdentityDetailRows`.

Screens using canonical directory name:

1. Barangay referral compose and preview  
2. Coordination thread detail (MOPH / barangay)  
3. Barangay incoming request detail  
4. MOPH home (coordination + reports lists)  
5. Barangay report submit preview (REPORT-QA-001 lifecycle bucket labels)  
6. MOPH aggregate report detail  

Case/report barangay presentation via `organizationDirectoryPresentationProvider` in `org_context_providers.dart`.

Historical records: `orgId` on coordination threads, assistance requests, aggregate reports; site label shown separately when directory unavailable.

## Offline behavior

Directory reads use Firestore document `snapshots()` / `get()` (same persistence as other collections). Uncached org shows loading/unavailable via directory widgets — not legacy `assignedBarangay` as canonical name.

## Automated verification

| Suite | Result |
|-------|--------|
| Flutter `flutter test` | **157** pass |
| Firestore rules `npm test` | **115** pass |
| Functions `npm test` | **70** pass |
| Provisioning `npm test` | **16** pass |

## Local emulator

- Firestore emulator **8195** reachable during backfill
- Rules from repo (Checkpoint A); no production deploy
- No Auth/Firestore reseed; QA anchors preserved

## Android application

- Prior `flutter run` on `emulator-5554` with `USE_FIREBASE_EMULATORS=true` (PO session)
- **After Checkpoint B:** rebuild or hot restart required to load directory UI changes

## Remaining manual acceptance (Checkpoint C)

1. Relaunch app against local emulators (development + `USE_FIREBASE_EMULATORS=true`).
2. As Barangay, open prepared referral review for QA coordination thread.
3. **Expected:** organization row shows **Barangay 3 (Poblacion)** (not site label as canonical name).
4. Do **not** submit the referral.

## Prototype acceptance

**Not declared — await PA acceptance.**
