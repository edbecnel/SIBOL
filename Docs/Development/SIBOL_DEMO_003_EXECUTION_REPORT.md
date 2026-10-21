# SIBOL-DEMO-003 — Execution report (Barangay acknowledgment of teen requests)

> **Handover UUIDs:** `b6f2d9a4-…` (implementation); `f2c8a731-…` (profile provisioning); `e8d2b614-5a73-4c09-9f21-6b47d83e105a` (Firebase deploy authorization)  
> **Date:** 2026-10-21  
> **Git commit/push:** **Not authorized**  
> **Firebase deploy:** **Executed** 2026-10-21 — see §8  
> **PA acceptance:** Live E2E **Pass (14/14)** on emulator (§11); UI copy defect corrected locally (not re-verified on device)

## 1. PA authorization

Extend SIBOL-DEMO-002 with Barangay incoming list, detail, and **Acknowledge** workflow. No changes to `cases` or `reports` permissions.

## 2. Organizational prerequisite (trusted assignment)

**Finding:** `users/{uid}` had no barangay/site field — insufficient to scope Barangay access.

**Solution (minimal):** Provisioned field **`assignedBarangay`** on demo teen and barangay profiles (Admin SDK / [`provision.mjs`](../../shared/provisioning/src/provision.mjs) only; clients cannot write it per existing `users` update rules).

- Demo value: **`Barangay Tres, Balingasag`** ([`DEMO_ASSIGNED_BARANGAY`](../../shared/provisioning/src/constants.mjs)) — aligns with seeded cases.
- Teen **create** copies `assignedBarangay` from profile into request `barangay` (rules enforce equality).
- Barangay **read/update** only when `resource.barangay == user.assignedBarangay`.

**Not done:** Retroactive `barangay` on existing `teenAssistanceRequests` created before DEMO-003 (per handover). Those documents lack `barangay` and will **not** appear in Barangay incoming list until a **new** teen submission after profile + rules deploy.

## 2.1 Live demo profile provisioning (2026-10-21)

**Mechanism:** Firebase Admin SDK (`applicationDefault()`), Firestore `users/{uid}.update({ assignedBarangay })` only — no Auth changes, no other users, no passwords logged.

**Pre-read (same day):** both profiles existed; `assignedBarangay` **absent** (`null`).

| Account | UID (Auth) | Before `assignedBarangay` | After `assignedBarangay` | Verified |
|---------|------------|---------------------------|--------------------------|----------|
| `teen.demo@sibol.local` | `Zgw0Kon5ImfwrGrrnC5ZRxwiOm33` | *(unset)* | `Barangay Tres, Balingasag` | **Yes** |
| `barangay.demo@sibol.local` | `Nki7S2QAbhaeHmfInvA4brAoxv83` | *(unset)* | `Barangay Tres, Balingasag` | **Yes** |

Post-update read confirmed expected value; `role`, `displayName`, and `active` unchanged on both documents.

**Remaining before demo:** Live E2E on device/emulator (§9); APK install on PO phone if needed.

## 3. Implemented workflow

| Step | UI |
|------|-----|
| Teen submits request | Unchanged DEMO-002 flow; requires `assignedBarangay` on profile |
| Barangay dashboard | **Incoming requests** button |
| List | Reference, category, date, status |
| Detail | Full description + **Acknowledge receipt** when `submitted` |
| Acknowledge | Sets `acknowledged`, `acknowledgedAt`, `acknowledgedByUid` |
| Teen My Requests / detail | Shows **Acknowledged** status when updated |

Copy clarifies acknowledgment is fictional receipt only (not counseling/emergency).

## 4. Firestore model extension

**Collection:** `teenAssistanceRequests` (unchanged path)

| Field | Create | Acknowledge update |
|-------|--------|-------------------|
| `teenUid`, `category`, `description`, `createdAt`, `barangay`, `status` | Teen create | Immutable |
| `status` | `submitted` | → `acknowledged` |
| `acknowledgedAt` | — | timestamp |
| `acknowledgedByUid` | — | barangay staff uid |

**Indexes added:** `barangay` ASC + `createdAt` DESC (in addition to existing `teenUid` index).

## 5. Security rules

- Teen create: includes validated `barangay` from profile.
- Read: teen own **or** barangay matching `assignedBarangay`.
- Update: barangay acknowledge only (`submitted` → `acknowledged`); teen update denied.
- `cases` / `reports`: unchanged.

## 6. Local verification (2026-10-21)

| Check | Result |
|-------|--------|
| `flutter test` | **54 passed** |
| `shared/firestore-rules-test` | **25/25 passed** |
| `flutter build apk --debug` | Run before phone install (post-implementation) |

## 7. Final predeployment verification (2026-10-21)

| # | Check | Result |
|---|--------|--------|
| 1 | Firebase CLI target `sibol-286d0` | **PASS** |
| 2 | Proposed `firestore.rules` vs **live** (rollback artifact [`firestore.rules.pre-demo-002-deploy-2026-10-21.rules`](../Verification/Artifacts/firestore.rules.pre-demo-002-deploy-2026-10-21.rules), SHA `f5c743fe…`) — `cases` + `reports` blocks **unchanged**; delta limited to `teenAssistanceRequests` (barangay assignment, barangay read/ack, teen create `barangay` field) | **PASS** |
| 3 | Proposed `firestore.indexes.json` — retains `teenUid`+`createdAt` index; adds `barangay`+`createdAt` for Barangay incoming query; live has one index (`CICAgOjXh4EK`, READY) | **PASS** |
| 4 | `shared/firestore-rules-test` on repo `firestore.rules` | **PASS** (25/25) |
| 5 | Rollback artifacts — rules: pre-DEMO-003 live snapshot above; indexes: [`firestore.indexes.pre-demo-002-deploy-2026-10-21.json`](../Verification/Artifacts/firestore.indexes.pre-demo-002-deploy-2026-10-21.json); metadata: [`firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json`](../Verification/Artifacts/firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json) | **PASS** |
| 6 | Demo `assignedBarangay` on teen + barangay profiles | **PASS** (§2.1) |

**Proposed rules SHA-256:** `2feec126f6e63cb88ec054f227ce230b99ae66e077061989d2f9937c7df424ae`

## 8. Live Firebase deployment (handover `e8d2b614-5a73-4c09-9f21-6b47d83e105a`)

### 8.1 Pre-deploy safeguards (2026-10-21)

| Safeguard | Result |
|-----------|--------|
| `firebase use` → `sibol-286d0` | **PASS** |
| `firestore.rules` SHA-256 `2feec126…` | **PASS** |
| `firestore.indexes.json` — teen + barangay composites | **PASS** |
| Rollback artifacts match live pre-deploy (rules `f5c743fe…`; index `CICAgOjXh4EK` READY only) | **PASS** — no re-capture required |

### 8.2 Deploy

| Item | Evidence |
|------|----------|
| Command | `firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0` |
| Result | **Success** — rules compiled/released; indexes deployed |
| Rules SHA-256 (source) | `2feec126f6e63cb88ec054f227ce230b99ae66e077061989d2f9937c7df424ae` |
| Active ruleset | `projects/sibol-286d0/rulesets/251bc159-efc3-446b-92e3-deae2c5f7719` (release `cloud.firestore` updated **2026-10-21T14:00:21Z**) |
| Prior live ruleset (rollback ref) | `projects/sibol-286d0/rulesets/2598ba63-33cc-4e55-9512-7a04f372ccb6` (SHA `f5c743fe…`) |
| Post-deploy metadata | [`firestore.rules.post-demo-003-deploy-2026-10-21.metadata.json`](../Verification/Artifacts/firestore.rules.post-demo-003-deploy-2026-10-21.metadata.json) |

### 8.3 Index verification (gcloud)

| Index | ID | State |
|-------|-----|--------|
| `teenUid` + `createdAt` | `CICAgOjXh4EK` | **READY** |
| `barangay` + `createdAt` | `CICAgJiUpoMK` | **READY** (observed 2026-10-21T14:04:36Z) |

### 8.4 Rollback

1. Restore [`firestore.rules.pre-demo-002-deploy-2026-10-21.rules`](../Verification/Artifacts/firestore.rules.pre-demo-002-deploy-2026-10-21.rules) to repo `firestore.rules` when PA authorizes, **or** release prior ruleset `2598ba63-33cc-4e55-9512-7a04f372ccb6` in Console.
2. Deploy rules only (indexes optional): `firebase deploy --only firestore:rules --project sibol-286d0`
3. Barangay composite index may remain without breaking DEMO-002 teen queries.

## 9. Demonstration script (tomorrow)

1. ~~Confirm profiles have `assignedBarangay`~~ — **done** (§2.1).
2. ~~Deploy rules + indexes~~ — **done** (§8).
3. Teen: submit **new** fictional request (required; pre-DEMO-003 requests lack `barangay`).
4. Barangay: **Incoming requests** → open → **Acknowledge receipt**.
5. Teen: **My requests** → status **Acknowledged**.

## 10. PA acceptance

| Gate | Status |
|------|--------|
| Predeploy verification | **Accepted** (prior handover) |
| Firebase rules/indexes deploy (`e8d2b614-…`) | **Complete** (§8) |
| Live E2E (teen submit → barangay incoming → acknowledge) | **Pass (14/14)** — [MVR-0004](../Verification/Records/MVR-0004-demo-003-barangay-ack-emulator.md) |
| Architect sign-off | Per PA (manual QA complete; UI copy fix pending visual re-check) |

## 11. Manual QA — live Firebase, Android emulator (2026-10-21)

**Record:** [MVR-0004](../Verification/Records/MVR-0004-demo-003-barangay-ack-emulator.md)  
**Outcome:** **14/14 Pass** (PA operator-guided; live `sibol-286d0` post-§8 deploy)

**Reference request (DEMO-003 path):** `teenAssistanceRequests/OHRs1h1Us6HrxSzflubR` — counseling referral submitted ~22:19 PHT; acknowledged ~22:25 PHT. Pre-DEMO-003 teen request remained **Submitted** and excluded from Barangay incoming (expected).

### 11.1 UI defect and correction

| Item | Detail |
|------|--------|
| Defect | Teen request detail footer still showed DEMO-002 text (“stored for your account only … no barangay review workflow”) |
| File | [`assistance_request_detail_screen.dart`](../../sibol_app/lib/features/teenager/presentation/screens/assistance_request_detail_screen.dart) |
| Authorized fix | Replaced with: *Demonstration prototype: your request can be viewed and acknowledged by your assigned barangay. Acknowledgment confirms receipt only; it does not mean assistance has been provided.* |
| Operator visual verification of new copy | **Not performed** — requires hot restart/rebuild on emulator |

### 11.2 Automated checks after copy fix (2026-10-21)

| Check | Result |
|-------|--------|
| `flutter analyze` | **0 errors**; 1 pre-existing **warning** (`duplicate_import` in `assistance_request_form_screen.dart`); 9 info lints |
| `flutter test` | **54 passed** |
