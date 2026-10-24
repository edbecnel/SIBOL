# SIBOL-CASE-COORD-001 Increment A — Firebase deploy readiness

> **Status:** **Deployed** 2026-10-24 (handover `c6a8e231-…`)  
> **Project:** `sibol-286d0`

## Proposed deploy artifacts

| Artifact | Change |
|----------|--------|
| `firestore.rules` | New coordination paths; deny-all client writes on coordination collections |
| `firestore.indexes.json` | +3 composites on `caseCoordinationThreads`, `barangayCoordinationRegistry` |

## Regression evidence

- `cd shared/firestore-rules-test && npm test` — **59/59** pass (includes prior 36 scenarios).

## Rollback

- Redeploy previous ruleset and index definitions from commit prior to coordination deploy (tag `v0.5.0` rules at `ba7c133` + REL-005 docs at `1352331` baseline).
- New indexes may remain **unused** until queries run; removing unused indexes is optional cleanup.

## Not in this deploy

- Cloud Functions (`createCoordinationReferral`).
- Flutter application binaries.
- Seed data mutations.

## Deploy record

See [SIBOL_CASE_COORD_001_INCREMENT_A_FIREBASE_DEPLOY_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_INCREMENT_A_FIREBASE_DEPLOY_EXECUTION_REPORT.md) and verification artifacts `firestore.*.post-case-coord-001-deploy-2026-10-24.metadata.json`.
