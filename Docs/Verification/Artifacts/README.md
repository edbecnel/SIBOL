# Verification artifacts (not for routine commit)

Local rollback and deployment evidence files. **Do not commit secrets.**

## T2-3 Firestore rules deploy (2026-10-21)

| File | Purpose |
|------|---------|
| `firestore.rules.pre-t2-3-deploy-2026-10-21.rules` | Exact rules live on `sibol-286d0` **before** T2-3 hardening deploy |
| `firestore.rules.pre-t2-3-deploy-2026-10-21.metadata.json` | Rules API metadata (ruleset `276bb8c1-a3ac-403f-82ed-2075519eaa77`) |
| `firestore.rules.post-t2-3-deploy-2026-10-21.metadata.json` | Post-deploy release metadata (ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc`) |

### Rollback procedure

1. Confirm target project: `firebase use sibol-286d0`
2. Copy pre-deploy rules into repo root temporarily or deploy from artifact:

   ```bash
   cp Docs/Verification/Artifacts/firestore.rules.pre-t2-3-deploy-2026-10-21.rules /tmp/firestore.rules.rollback
   # Replace firestore.rules with rollback content only when PA authorizes rollback
   firebase deploy --only firestore:rules --project sibol-286d0
   ```

3. Alternatively redeploy ruleset `276bb8c1-a3ac-403f-82ed-2075519eaa77` via Firebase console **Rules → Release history**.

## SIBOL-DEMO-002 predeploy (2026-10-21, not yet deployed)

| File | Purpose |
|------|---------|
| `firestore.rules.pre-demo-002-deploy-2026-10-21.rules` | Proposed rules (T2-3 live + `teenAssistanceRequests`) |
| `firestore.rules.pre-demo-002-deploy-2026-10-21.metadata.json` | Predeploy verification record; live baseline ruleset `3f65a5f3-…` |
| `firestore.indexes.pre-demo-002-deploy-2026-10-21.json` | Proposed composite index snapshot |

**Rollback after DEMO-002 deploy:** restore `git show f1f7c76:firestore.rules` or release ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc` — see [SIBOL_DEMO_002_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_002_EXECUTION_REPORT.md) §7.

## SIBOL-DEMO-003 deploy (2026-10-21)

| File | Purpose |
|------|---------|
| `firestore.rules.post-demo-003-deploy-2026-10-21.metadata.json` | Post-deploy ruleset `251bc159-…`, indexes, rollback refs |
| `firestore.rules.pre-demo-002-deploy-2026-10-21.rules` | **Pre-DEMO-003 live** rollback (ruleset `2598ba63-…`, SHA `f5c743fe…`) |
| `firestore.indexes.pre-demo-002-deploy-2026-10-21.json` | Pre-DEMO-003 index snapshot (teen composite only) |

See [SIBOL_DEMO_003_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_003_EXECUTION_REPORT.md) §8.

## SIBOL-DEMO-004 deploy (2026-10-22)

| File | Purpose |
|------|---------|
| `firestore.rules.post-demo-004-deploy-2026-10-22.metadata.json` | Post-deploy ruleset `c5b24ed9-…`, four composite indexes |
| `firestore.rules.pre-demo-004-deploy-2026-10-22.rules` | **Pre-DEMO-004 live** rollback (ruleset `251bc159-…`) |

See [SIBOL_DEMO_004_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_004_EXECUTION_REPORT.md) §9.

## SIBOL-DEMO-004 predeploy (2026-10-22)

| File | Purpose |
|------|---------|
| `firestore.rules.pre-demo-004-deploy-2026-10-22.rules` | **Current live** rollback (ruleset `251bc159-…`, SHA `2feec126…`) |
| `firestore.rules.pre-demo-004-deploy-2026-10-22.metadata.json` | Capture record + live index IDs |
| `firestore.indexes.pre-demo-004-deploy-2026-10-22.json` | Two READY `teenAssistanceRequests` composites only |

See [SIBOL_DEMO_004_EXECUTION_REPORT.md](../../Development/SIBOL_DEMO_004_EXECUTION_REPORT.md) §8.
