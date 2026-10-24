# REG-001 M1/M2 — Deployment and cutover runbook (operator)

**Status:** Repository procedure; **not** live deployment authorization.  
**SPEC-REG-001:** Remains **Draft**. **MVR-REG-001:** **NOT RUN** (production verification pending).

## Preconditions (STOP if any fail)

| # | Check | Command / action |
|---|--------|------------------|
| 1 | Correct Firebase project | `firebase use` / console — must match approved project id |
| 2 | Backup | Authorized export of Firestore — **separate PA authorization only** |
| 3 | Inventory + dry-run | `cd shared/migration && GCLOUD_PROJECT=<id> npm run migrate -- --inventory` then dry-run |
| 4 | Mapping approved | No unmapped barangay labels; no duplicate orgId in mapping file |
| 5 | Regression evidence | migration, firestore-rules-test (incl. cutover lockdown), functions, flutter test/analyze |
| 6 | App build | Org-scoped queries + `orgId` writes; teen `selectedBarangayOrgId` |
| 7 | Maintenance window | Users informed; barangay workflows paused during lockdown |

## Safe cutover sequence (no permissive interval)

**Never** run live M1 migration while legacy global barangay case rules remain active in production.

| Step | Action | Expected result |
|------|--------|-----------------|
| 1 | Announce maintenance; block routine barangay/MOPH app use | No concurrent sensitive writes |
| 2 | **Deploy Firestore indexes** (M2 composites) | Index build complete in console |
| 3 | **Deploy cutover lockdown rules** (`firestore.rules.cutover-lockdown` → temporary `firestore.rules` deploy) | Client case/assistance/report/coordination access **denied** (emulator: `cutover_lockdown.rules.test.mjs`) |
| 4 | **Deploy Cloud Functions** (M2 authz callables) | New referral authz live; old app referrals may fail (acceptable in maintenance) |
| 5 | **Execute M1 migration** (Admin SDK; bypasses rules) | Orgs, memberships, `orgId` backfill, user org fields |
| 6 | **Verify migration** | `npm run migrate -- --verify`; zero blocking plan errors |
| 7 | **Deploy final M2 rules** (`firestore.rules` production cutover) | Org-scoped authorization active |
| 8 | **Release compatible mobile app** | Org-scoped queries; membership context |
| 9 | Post-cutover smoke | Same-org allow; cross-org deny; MOPH inbox; teen assistance |

### Cutover lockdown artifact

- File: `firestore.rules.cutover-lockdown` (repository root)
- Tests: `shared/firestore-rules-test/test/cutover_lockdown.rules.test.mjs`
- Deploy command (authorized ops only): copy/replace rules source or `firebase deploy --only firestore:rules` with lockdown file promoted per your release process.

### Rollback

- **Forbidden:** Restoring pre-M2 global barangay case read/write rules without data restore.
- **Allowed:** Re-deploy lockdown rules to halt access; restore Firestore from backup; redeploy prior app + rules **only** under PA-approved disaster recovery with documented security review.

## Post-cutover verification

- Cross-barangay case query and document deny.
- Org-scoped Flutter queries succeed for authorized org only.
- MOPH inbox (hospital membership + `coordination.hospital`).
- Callable referral + duplicate prevention.
- Demo seed idempotency (`shared/provisioning` tests).

## STOP criteria

- Lockdown rules not deployed before migration on production still using legacy case rules.
- Migration plan errors > 0.
- Cross-org case read succeeds in smoke tests.
- Missing composite indexes for org-scoped queries.
