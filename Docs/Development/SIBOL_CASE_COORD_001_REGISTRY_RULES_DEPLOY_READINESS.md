# SIBOL-CASE-COORD-001 — Registry rules deploy readiness

> **Status:** Rules corrected in repo; **not deployed** to `sibol-286d0`  
> **Handover:** `3c7e2a91-5b84-4f06-a139-8d20e65c742b`  
> **Git:** `barangayCanReadCoordinationRegistry(assistanceRequestId)` in `firestore.rules` @ `089ea44`+

## Problem (live Increment A rules)

Barangay registry `get`/listen on a **missing** `barangayCoordinationRegistry/{assistanceRequestId}` document evaluates `resource.data` and returns **permission-denied**. The Flutter app used a **legacy absence probe** (see `coordination_registry_referral_probe.dart`) so the referral CTA still appears until rules are deployed.

## Corrected rules (repo)

Barangay may read a registry document id when:

1. `teenAssistanceRequests/{assistanceRequestId}` exists and `barangay` matches `users/{uid}.assignedBarangay`.
2. Registry doc is **missing**, or exists and `barangay` matches.

Teen and MOPH: **denied**. Client create/update/delete on registry: **denied** (unchanged).

## Coordinated rollout (two stages)

| Stage | Action | App build |
|-------|--------|-----------|
| **1 — current live** | Increment A rules + `createCoordinationReferral` callable | Default build (`SIBOL_COORD_REGISTRY_RULES_V2` unset / `false`) — legacy absence probe **on** |
| **2 — after rules deploy** | `firebase deploy --only firestore:rules --project sibol-286d0` (PA authorization required) | Release build with `--dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true` so `permission-denied` is surfaced, not mapped to “no referral” |

**Order:** Deploy rules **before** shipping Stage 2 app builds. If the app ships Stage 2 before rules deploy, barangay users may see eligibility errors on acknowledged requests.

## Verification before deploy

```bash
cd shared/firestore-rules-test && npm test
```

Includes: missing registry (owned request), existing registry, cross-barangay denial, teen/MOPH denial, unknown assistance id.

## Post-deploy operator check (optional)

Barangay opens an acknowledged request **without** referral → **Refer to MOPH coordination** visible; no Firestore error in logs.
