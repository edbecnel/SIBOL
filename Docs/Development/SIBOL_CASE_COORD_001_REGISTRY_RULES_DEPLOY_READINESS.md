# SIBOL-CASE-COORD-001 — Registry rules v2 deploy readiness

> **Status:** Ready for PA-authorized deploy (rules **not** deployed as of this record)  
> **Handovers:** `3c7e2a91-…`, readiness `b6d2f814-…`  
> **Git (rules source):** `firestore.rules` — registry function `barangayCanReadCoordinationRegistry(assistanceRequestId)`  
> **Repo rules SHA-256:** `e5a899c250d1c3c5ffdb092bda29357ef18828a3511ea58369ab2d0baed47bb3` (verify at deploy time)

## 1. Problem (live Increment A rules on `sibol-286d0`)

Barangay registry `get`/listen on a **missing** `barangayCoordinationRegistry/{assistanceRequestId}` evaluates `resource.data` and returns **permission-denied**. Flutter default builds use a **legacy absence probe** (`coordination_registry_referral_probe.dart`, `SIBOL_COORD_REGISTRY_RULES_V2=false`).

## 2. Registry rules v2 (repository)

`barangayCanReadCoordinationRegistry(assistanceRequestId)` allows **read** when:

1. Caller is active barangay with `assignedBarangay`.
2. `teenAssistanceRequests/{assistanceRequestId}` **exists** and `barangay` matches `assignedBarangay`.
3. Registry doc is **missing**, **or** exists and `barangay` matches.

| Check | Result |
|-------|--------|
| Own existing registry row | **Allow** |
| Missing registry for owned assistance request | **Allow** (existence probe) |
| Other barangay’s registry / assistance | **Deny** |
| Teen / MOPH registry read | **Deny** |
| Unknown assistance request id | **Deny** (`exists` on teen request fails) |
| Client create/update/delete on registry | **Deny** (`allow create, update, delete: if false`) |

**Unintended paths reviewed:** No collection-list rule on registry (doc-id reads only). Cross-barangay probing of another site’s assistance id is blocked at step 2. MOPH may still read `caseCoordinationThreads` headers per Increment A (unchanged; not registry).

## 3. Deployed baseline evidence (production)

| Field | Value |
|-------|--------|
| Firebase project | `sibol-286d0` |
| Last coordination rules deploy | Increment A — 2026-10-24T05:10:17Z |
| Live ruleset (post Increment A) | `d1bb212e-53a3-44a9-95df-c91a083b9e09` |
| Live rules SHA-256 at that deploy | `3d8b82cb54c9b8ec0e4a5181f9cc7d926792345dafc097a8636866bc57e7c601` |
| Artifact | [firestore.rules.post-case-coord-001-deploy-2026-10-24.metadata.json](../Verification/Artifacts/firestore.rules.post-case-coord-001-deploy-2026-10-24.metadata.json) |

**Registry v2 is in git but not reflected in live SHA above.** Do not modify production data during readiness; deploy only changes rules metadata.

## 4. Local verification (handover `b6d2f814-…`)

| Suite | Command | Result |
|-------|---------|--------|
| Firestore rules | `cd shared/firestore-rules-test && npm test` | **66/66** pass (isolated emulator port **8215** via [`firebase.emulator-isolated.json`](../../firebase.emulator-isolated.json)) |
| Functions | `cd shared/functions && npm test` | **10/10** pass |
| Flutter | `cd sibol_app && flutter test` | **72/72** pass |
| Flutter analyze | `cd sibol_app && flutter analyze` | 0 errors |

**Port 8195:** Reserved for IDE/`flutter run` attached emulator. Isolated CI-style runs use **8215** so both can coexist. Optional attached run: `npm run test:attached` in `shared/firestore-rules-test` (requires clean emulator on 8195).

## 5. Deployment procedure (operator — PA authorization required)

**Do not run until PA authorizes deployment.**

### 5.1 Capture pre-deploy baseline

```bash
cd /path/to/SIBOL
git checkout main && git pull
shasum -a 256 firestore.rules

firebase login
firebase use sibol-286d0   # confirm only this project

firebase firestore:rulesets:list --project sibol-286d0
# Record current RELEASE ruleset id (expect d1bb212e-… until replaced)

cp firestore.rules "Docs/Verification/Artifacts/firestore.rules.pre-registry-v2-deploy-$(date -u +%Y-%m-%d).rules"
```

**Stop if** project is not `sibol-286d0` or working tree rules differ from intended commit.

### 5.2 Pre-deploy tests

```bash
cd shared/firestore-rules-test && npm ci && npm test
cd ../functions && npm ci && npm test
cd ../../sibol_app && flutter test
```

**Stop if** any suite fails.

### 5.3 Deploy Firestore rules only

```bash
cd /path/to/SIBOL
firebase deploy --only firestore:rules --project sibol-286d0
```

**Expected:** Success; new ruleset id; **no** index or functions changes.

**Stop if** deploy errors or wrong project.

### 5.4 Post-deploy rules verification (live)

Using barangay demo account and a known assistance request **without** registry row (or MVR-0008 fixture):

1. Barangay: open acknowledged request — **Refer to MOPH coordination** visible (app still legacy probe OK).
2. Optional: Firestore console — barangay cannot read other barangay registry docs.

Using request **with** registry row after MVR-0008:

3. Detail shows “referral already submitted”; registry read succeeds in client logs (no permission-denied on listen).

**Stop if** cross-barangay read succeeds or teen/MOPH can read registry.

### 5.5 Stage 2 app (after rules live)

```bash
cd sibol_app
flutter run --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true -d <device>
```

Re-run referral eligibility on acknowledged request (no false permission errors). Submit duplicate referral — **blocked** by callable.

**Stop if** referral CTA missing on eligible request or duplicate referral succeeds.

### 5.6 Record deploy artifact

Update `Docs/Verification/Artifacts/` with post-deploy metadata (ruleset id, SHA-256, timestamp). Do not move MVR-0008/0009 status.

## 6. Rollback procedure

If verification fails after rules deploy:

```bash
# Option A: redeploy captured pre-registry-v2 rules file
firebase deploy --only firestore:rules --project sibol-286d0 \
  --force  # only if using rules file from step 5.1 artifact

# Option B: release prior ruleset (use id from 5.1 list)
# firebase firestore:rules:release <prior-ruleset-id> --project sibol-286d0
```

Redeploy **only** rules; do not delete Firestore data.

Revert app to default (`SIBOL_COORD_REGISTRY_RULES_V2` unset / `false`) if Stage 2 build was distributed.

**Stop condition:** Rollback complete and barangay referral CTA behavior matches pre-deploy (legacy probe compensates for missing-doc deny).

## 7. Coordinated rollout summary

| Stage | Firestore | App |
|-------|-----------|-----|
| **Current** | Increment A (missing-doc deny) | Default — legacy probe **on** |
| **After rules deploy** | Registry v2 in repo | Default still OK |
| **Stage 2** | Registry v2 live | `SIBOL_COORD_REGISTRY_RULES_V2=true` — probe maps errors correctly |

Deploy rules **before** shipping Stage 2 builds.

## 8. References

- [SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_READINESS_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_READINESS_EXECUTION_REPORT.md)
- [MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) / [MVR-0009](../Verification/Records/MVR-0009-case-coord-001-b-history-barangay-referrals.md) — unchanged acceptance evidence
