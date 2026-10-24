# SIBOL-CASE-COORD-001 — Registry rules v2 deploy execution report

> **Handover UUID:** `d8a41c73-5e29-4f60-b192-7c3e8a65f204`  
> **Git start/end:** `a1b22a0737c37e9b1845bc23bd6d9f54d10a0dc3` (docs-only commit follows)  
> **Firebase project:** `sibol-286d0`  
> **Increment C:** **NOT** deployed or implemented

## 1. Preconditions

| Check | Result |
|-------|--------|
| HEAD `a1b22a0` on `main` | **Pass** |
| Repo `firestore.rules` SHA-256 | `e5a899c250d1c3c5ffdb092bda29357ef18828a3511ea58369ab2d0baed47bb3` |
| `firebase use sibol-286d0` | **Pass** |
| Live release (pre-deploy) | `d1bb212e-53a3-44a9-95df-c91a083b9e09` (update `2026-10-24T05:10:17Z`) |

## 2. Rollback baseline

| Item | Value |
|------|--------|
| Artifact | [firestore.rules.pre-registry-v2-deploy-2026-10-24.rules](../Verification/Artifacts/firestore.rules.pre-registry-v2-deploy-2026-10-24.rules) |
| SHA-256 | `3d8b82cb54c9b8ec0e4a5181f9cc7d926792345dafc097a8636866bc57e7c601` |
| Ruleset id | `d1bb212e-53a3-44a9-95df-c91a083b9e09` |
| Capture | Firebase Rules API GET (matches Increment A metadata) |
| Metadata | [firestore.rules.pre-registry-v2-deploy-2026-10-24.metadata.json](../Verification/Artifacts/firestore.rules.pre-registry-v2-deploy-2026-10-24.metadata.json) |

Redeploy: replace repo `firestore.rules` with artifact (or checkout pre-deploy commit) and `firebase deploy --only firestore:rules --project sibol-286d0`.

## 3. Local verification (pre-deploy)

`cd shared/firestore-rules-test && npm test` — **66/66 pass** (isolated emulator port 8215).

Registry suite includes: existing/missing registry allow; teen/MOPH/other barangay/unknown deny; client write deny.

## 4. Deployment

```bash
firebase deploy --only firestore:rules --project sibol-286d0
```

**Result:** success (compile warnings only; unchanged from prior deploys).

| Field | Value |
|-------|--------|
| Post-deploy ruleset | `projects/sibol-286d0/rulesets/cd5f9e6c-ccd7-404c-b75d-ef1cebae36c1` |
| Release updated | `2026-10-24T08:46:38.360561Z` |
| Deployed rules SHA-256 (API) | `e5a899c250d1c3c5ffdb092bda29357ef18828a3511ea58369ab2d0baed47bb3` |
| Post metadata | [firestore.rules.post-registry-v2-deploy-2026-10-24.metadata.json](../Verification/Artifacts/firestore.rules.post-registry-v2-deploy-2026-10-24.metadata.json) |

**Not deployed:** Firestore indexes, Cloud Functions, Hosting, or other resources.

## 5. Live verification

| Check | Method | Result |
|-------|--------|--------|
| Deployed rules contain `barangayCanReadCoordinationRegistry` | Rules API GET ruleset | **Pass** |
| Deployed SHA matches git | SHA-256 compare | **Pass** |
| Fixture: registry row exists | Admin SDK | `3odtqzgOTgIaIL8wuWue` — registry **exists** |
| Fixture: no registry row | Admin SDK | `OHRs1h1Us6HrxSzflubR` — registry **missing** |
| Client-signed get/create as barangay/teen/MOPH | Custom token / demo password | **Not run in EA** — ADC cannot sign custom tokens; `SIBOL_DEMO_PASSWORD_*` unset |

**Security posture:** Same rules file as passing emulator suite is live. **Operator follow-up:** sign in with [demo accounts](../../../shared/docs/DEMO_ACCOUNTS.md) and confirm registry get on fixtures above (allow/deny per readiness §5.4). No rollback triggered (no evidence of unauthorized access).

Cross-barangay denial: no non-demo `teenAssistanceRequests` barangay in project; covered by rules tests **66/66**.

## 6. Flutter Stage 2 (verification build only)

Default app config unchanged (`SIBOL_COORD_REGISTRY_RULES_V2` default `false`).

```bash
cd sibol_app
flutter test --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
```

**Result:** **72/72 pass** (includes registry probe v2 + `BarangayMophReferralAction` widget tests).

Production app binaries were **not** republished; Stage 2 flag is for post-rules client rollout when approved.

## 7. Rollback performed

**None.**

## 8. Remaining risks

- **Stage 2 app rollout** still optional; default builds use legacy absence probe (safe on v2 rules but redundant).
- **Operator client smoke** on live Auth recommended for audit trail.
- **MVR-0008 doc id typo:** record shows `3odtqzgOTgIalL8wuWue`; live id is `3odtqzgOTgIaIL8wuWue` (unchanged; MVR not reopened).

## 9. PA / operator

Optional: short live barangay smoke on fixtures; schedule Stage 2 store/build when ready.
