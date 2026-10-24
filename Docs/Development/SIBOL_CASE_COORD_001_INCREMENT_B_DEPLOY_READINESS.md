# SIBOL-CASE-COORD-001 Increment B — Firebase Functions deploy readiness

> **Status:** **Deployed** — `createCoordinationReferral` live `us-central1` (retry `e9b43c72-…`, 2026-10-24)  
> **Handover:** `f5c2a910-7d46-4e3b-8f21-c0a9e647d352`, deploy attempt `d8e3b7a1-…`

## Deploy scope (when authorized)

| Artifact | Action |
|----------|--------|
| Cloud Function `createCoordinationReferral` | **Deploy** (`shared/functions`) |
| Existing `healthCheck`, `submitReport` stub | Retained (no behavioral change to stub) |
| Firestore rules/indexes | **No change** required for Increment B |

## Command (proposed)

```bash
cd shared/functions && npm ci && npm run build
firebase deploy --only functions:createCoordinationReferral --project sibol-286d0
```

Use targeted deploy to avoid unintended function replacement. Verify region matches Flutter `FirebaseFunctions.instance` (default `us-central1`).

## Prerequisites

- Node 20 per `package.json` engines.
- Firebase CLI authenticated to `sibol-286d0`.
- **Firebase Blaze (pay-as-you-go) plan** — **required**; deploy failed on Spark (2026-10-24).
- Cloud Functions, Cloud Build, and Artifact Registry APIs (CLI may enable after Blaze upgrade).
- Flutter app build pointing at same Firebase project.

## Regression evidence

- Functions: `npm test` — **10/10**
- Rules: **59/59**
- Flutter: **60/60**

## Rollback

- `firebase functions:delete createCoordinationReferral --project sibol-286d0` or redeploy prior functions bundle from Git parent commit.
- Coordination data written after deploy remains; registry prevents duplicate referrals per assistance id.

## Limitations

- No automated live MVR until operator exercises Barangay → MOPH path post-deploy.
- Increment C still required for MOPH/barangay messaging.
