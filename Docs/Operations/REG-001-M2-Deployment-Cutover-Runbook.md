# REG-001 M1/M2 — Deployment and cutover runbook (operator)

**Status:** Repository procedure; **not** live deployment authorization.  
**SPEC-REG-001:** Remains **Draft**. **MVR-REG-001:** **NOT RUN** (production verification pending).

## Preconditions (STOP if any fail)

| # | Check | Command / action |
|---|--------|------------------|
| 1 | Correct Firebase project | `firebase use` / console — must match approved project id |
| 2 | Backup | Authorized export of Firestore (cases, users, assistance, reports, coordination collections) — **run only under separate PA authorization** |
| 3 | Inventory | `cd shared/migration && GCLOUD_PROJECT=<id> npm run migrate -- --inventory` (authorized env only) |
| 4 | Mapping approved | Review `fixtures/demo_org_mapping.json` or production mapping file; no unmapped labels in inventory |
| 5 | Regression evidence | `shared/migration npm test`; `shared/firestore-rules-test npm test`; `shared/functions npm test`; `sibol_app flutter test` |
| 6 | App build | Release build with M2-compatible `orgId` writes and teen `selectedBarangayOrgId` |
| 7 | Maintenance window | Barangay case access must not rely on pre-M2 global rules during cutover |

## Derived safe cutover sequence

Old mobile clients without `orgId` on writes will **fail closed** after rules deploy. Concurrent writes during partial migration must be minimized.

| Step | Component | Rationale |
|------|-----------|-----------|
| 1 | **Deploy Cloud Functions** (authz-aware callables) | Server paths enforce org before clients fully updated |
| 2 | **Deploy Firestore indexes** | Required for membership and org-scoped list queries before traffic |
| 3 | **Execute M1 migration** (live, PA-gated) | Orgs, memberships, `orgId` backfill, user `primaryOrgId` / teen `selectedBarangayOrgId` |
| 4 | **Verify migration** | `npm run migrate -- --verify` + spot checks (see post-cutover) |
| 5 | **Deploy Firestore rules (M2)** | **No interval** where rules are old-global while data is org-scoped only partially — complete step 3 first |
| 6 | **Release mobile app** | Clients must send `orgId` / use membership-backed workflows |
| 7 | **Post-cutover smoke** | Same-org allow, cross-org deny, teen assistance, referral, MOPH inbox |

**Rollback:** Revert rules to pre-M2 only if accompanied by **restored data snapshot** and app version pin. Do **not** roll back to global barangay case access as a “hotfix.”

## Post-cutover verification (emulator or staging first when available)

- Cross-Barangay case read/write denied (two barangay staff accounts).
- Org admin without `case.read` denied on cases.
- Teen assistance create with `selectedBarangayOrgId`.
- Barangay acknowledge + referral callable.
- MOPH thread list/read; no teen PII on thread header.
- Aggregate report submit with `orgId`.

## STOP criteria

- Unmapped barangay labels in inventory.
- Migration plan errors > 0 on dry-run.
- Any cross-org case read succeeds in smoke tests.
- Indexes missing for production queries (see `firestore.indexes.json`).
