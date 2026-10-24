# SIBOL-CASE-COORD-001 — Increment B Firebase deploy execution report

> **Handover UUID:** `d8e3b7a1-5c94-4f26-8b01-6e72a9d0c453`  
> **Date:** 2026-10-24  
> **Git commit (source):** `124263271c86b225a4b217ce9bf89f3b7ebf741b`  
> **Target project:** `sibol-286d0`

## 1. Preflight

| Check | Result |
|-------|--------|
| Branch / HEAD / tree | `main` @ `1242632`, **clean** |
| Firebase CLI project | `sibol-286d0` |
| `firebase.json` Functions source | `shared/functions` (predeploy `npm run build`) |
| Export name | `createCoordinationReferral` in [`index.ts`](../../shared/functions/src/index.ts) |
| Flutter callable | `httpsCallable('createCoordinationReferral')` via `FirebaseFunctions.instance` (default region) |
| Runtime | Node **20** (`package.json` engines); Functions **v2** `onCall` |
| Deployed inventory (before) | **None listable** — `firebase functions:list` failed; `gcloud functions list` reports **Cloud Functions API disabled** on project (no prior deployed functions observed) |
| Callable response | Returns `{ threadId, displayRef }` only — no teen identifiers |
| Secrets in repo | None introduced |

## 2. Local verification (pre-deploy)

| Command | Result |
|---------|--------|
| `cd shared/functions && npm ci && npm run build` | **Success** |
| `cd shared/functions && npm test` | **10/10** pass |
| `cd shared/firestore-rules-test && npm test` | **59/59** pass |
| `cd sibol_app && flutter test` | **60/60** pass |
| `cd sibol_app && flutter analyze` | 0 errors |

## 3. Deployment attempt

**Command:**

```bash
firebase deploy --only functions:createCoordinationReferral --project sibol-286d0 --non-interactive
```

**Outcome:** **FAILED** — not deployed.

```
Your project sibol-286d0 must be on the Blaze (pay-as-you-go) plan …
Required API cloudbuild.googleapis.com can't be enabled until the upgrade is complete.
```

CLI also attempted to enable `cloudfunctions.googleapis.com`, `cloudbuild.googleapis.com`, and `artifactregistry.googleapis.com` before failing on billing plan.

## 4. Operator action required (PA handover STOP)

Per handover §1: **billing / paid-service enablement requires operator approval.**

1. Upgrade Firebase project `sibol-286d0` to **Blaze** (if PA approves): https://console.firebase.google.com/project/sibol-286d0/usage/details  
2. Re-run targeted deploy (same command as §3).  
3. Confirm no unintended deploy of `healthCheck` / `submitReport` if they were never deployed — use `--only functions:createCoordinationReferral`.

**EA did not** upgrade billing, enable Blaze, or create live referral records.

## 5. Post-deployment verification

**Not applicable** — function not live. When deployed, operator should use [MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md).

Non-mutating checks after future deploy:

- `firebase functions:list --project sibol-286d0` shows `createCoordinationReferral`.
- Unauthenticated callable invocation returns `unauthenticated` (client or curl with Firebase callable protocol).

## 6. Firestore

Rules/indexes **unchanged** on live project (no rules deploy in this handover).

## 7. Increment C

**Not started.**

## 8. PA acceptance

Deploy **blocked** pending Blaze approval and successful redeploy handover or operator-authorized retry.
