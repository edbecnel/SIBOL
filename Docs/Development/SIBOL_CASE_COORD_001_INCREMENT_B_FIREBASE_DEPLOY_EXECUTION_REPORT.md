# SIBOL-CASE-COORD-001 — Increment B Firebase deploy execution report

> **Handover UUIDs:** `d8e3b7a1-5c94-4f26-8b01-6e72a9d0c453` (blocked), **`e9b43c72-6a15-4d8e-9f20-3c71b5d864a2`** (success)  
> **Application source commit:** `124263271c86b225a4b217ce9bf89f3b7ebf741b`  
> **Target project:** `sibol-286d0`

## 1. Attempt A — billing blocked (`d8e3b7a1`)

| Item | Result |
|------|--------|
| Date | 2026-10-24 |
| Outcome | **Failed** — Spark plan; Blaze required |
| Functions deployed | **None** |

Operator subsequently linked billing, approved **Blaze**, and configured a **$5/month project budget with email alerts** (alerting only, not a hard cap). EA did not modify billing account or budget settings.

## 2. Attempt B — successful deploy (`e9b43c72`)

### 2.1 Preflight

| Check | Result |
|-------|--------|
| Git | `main` @ `c1738d7`, clean (untracked `firestore-debug.log` excluded from commit) |
| Firebase project | `sibol-286d0` |
| Billing | `billingEnabled: true` (`gcloud billing projects describe sibol-286d0`) |
| Budget ($5) | **Not verified via CLI** (Billing Budget API disabled / permissions); operator-reported |
| Pre-deploy functions | **None** (`firebase functions:list` → empty) |
| Callable name / Flutter | `createCoordinationReferral` / `FirebaseFunctions.instance` (default **us-central1**) |

### 2.2 Local verification

| Suite | Result |
|-------|--------|
| Functions `npm ci`, `build`, `test` | **10/10** |
| Firestore rules | **59/59** |
| Flutter tests | **60/60** |
| Flutter analyze | 0 errors |

### 2.3 Deployment

```bash
firebase deploy --only functions:createCoordinationReferral --project sibol-286d0 --non-interactive
```

| Item | Value |
|------|--------|
| Function create | **Success** — `createCoordinationReferral` **nodejs20** **2nd Gen** **us-central1** |
| CLI exit code | **1** — artifact **cleanup policy** not set (function still deployed) |
| Post-deploy inventory | **Only** `createCoordinationReferral` (no `healthCheck`, no `submitReport`) |
| `updateTime` (UTC) | **2026-10-24T05:54:16Z** |
| Callable HTTPS | `https://us-central1-sibol-286d0.cloudfunctions.net/createCoordinationReferral` |

CLI enabled standard build APIs (Cloud Build, Artifact Registry, Cloud Run, Eventarc, etc.) as part of first Gen2 deploy.

### 2.4 Post-deployment verification (non-mutating)

| Check | Result |
|-------|--------|
| Function **ACTIVE** | **PASS** (`gcloud functions describe`) |
| Unauthenticated POST (no Auth header) | **401** `UNAUTHENTICATED` — "Sign in required." |
| Authenticated live referral | **Not executed** (handover prohibition) |
| Firestore rules/indexes deploy | **None** — live rules unchanged from Increment A |
| Response contract | Code returns `{ threadId, displayRef }` only (no teen fields) |

### 2.5 Operator acceptance

[MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) — **prepared**; **PASS not recorded** until operator completes live referral walkthrough.

## 3. Risks / follow-up

- Node.js 20 runtime deprecation warning on deploy (upgrade before 2026-10-30 per Google notice).
- Artifact registry cleanup policy warning — minor storage cost; operator may run `firebase functions:artifacts:setpolicy` if desired.
- Free-text barangay summary de-identification remains operational (ADR-0005).

## 4. Increment C

**Not started.**
