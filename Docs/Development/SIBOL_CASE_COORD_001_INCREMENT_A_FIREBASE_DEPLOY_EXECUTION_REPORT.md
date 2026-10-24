# SIBOL-CASE-COORD-001 — Increment A Firebase deploy execution report

> **Handover UUID:** `c6a8e231-4d79-4b02-9f15-72d8e3c09a64`  
> **Date:** 2026-10-24  
> **Git commit (rules source):** `4de308c8e6f08cfb57dabb75ad898f3c93adde63`  
> **Target project:** `sibol-286d0`

## 1. Preflight

| Check | Result |
|-------|--------|
| Branch / HEAD / clean tree | `main` @ `4de308c`, clean |
| Firebase CLI project | `sibol-286d0` (current) |
| `firebase.json` | `firestore.rules`, `firestore.indexes.json` |
| Live rules vs repo (pre-deploy) | SHA `497df6e…` matched `1352331:firestore.rules` (DEMO-004 baseline) |
| Live composite indexes | **6** READY (teen assistance ×2, reports ×4) |
| Rules tests | `cd shared/firestore-rules-test && npm test` — **59/59** pass |

## 2. Deployment

**Command:**

```bash
firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0
```

**Outcome:** Success (rules compiled/released; indexes deployed).

| Artifact | Post-deploy |
|----------|-------------|
| Ruleset | `projects/sibol-286d0/rulesets/d1bb212e-53a3-44a9-95df-c91a083b9e09` (release updated **2026-10-24T05:10:17Z**) |
| Prior ruleset | `projects/sibol-286d0/rulesets/c5b24ed9-aebf-44a9-af28-e9b2ff0d8c9c` |
| Rules SHA (deployed) | `3d8b82cb54c9b8ec0e4a5181f9cc7d926792345dafc097a8636866bc57e7c601` |

**Not deployed:** Cloud Functions, Hosting, Auth, seed data.

## 3. Index readiness

All **9** composite indexes **READY** (observed via `gcloud firestore indexes composite list`).

New coordination indexes: `CICAgNi47oMK`, `CICAgJjFqZMK`, `CICAgJjFqZMJ`.  
Metadata: [firestore.indexes.post-case-coord-001-deploy-2026-10-24.metadata.json](../Verification/Artifacts/firestore.indexes.post-case-coord-001-deploy-2026-10-24.metadata.json).

## 4. Post-deployment verification

| Area | Evidence |
|------|----------|
| v0.5.0 rules blocks (`cases`, `teenAssistanceRequests`, `reports`) | Unchanged in diff vs pre-deploy artifact; only coordination `match` blocks appended |
| Coordination client writes | Denied by design (Increment A); emulator suite covers coordination paths |
| Live data mutation | **None** — no test documents written to production |
| Operator re-check | MVR-0003–0006 flows remain valid under unchanged assistance/report rules |

Rollback: redeploy [firestore.rules.pre-case-coord-001-deploy-2026-10-24.rules](../Verification/Artifacts/firestore.rules.pre-case-coord-001-deploy-2026-10-24.rules) and [firestore.indexes.pre-case-coord-001-deploy-2026-10-24.json](../Verification/Artifacts/firestore.indexes.pre-case-coord-001-deploy-2026-10-24.json).

## 5. Limitations

- Coordination **read** paths are live; **referral creation** still requires Increment B callable (client creates denied).
- Free-text de-identification is operational discipline, not rules-enforced (ADR-0005).

## 6. Increment B readiness

**Ready for PA authorization** of `createCoordinationReferral` implementation and Barangay/MOPH UI — Firebase foundation is deployed.
