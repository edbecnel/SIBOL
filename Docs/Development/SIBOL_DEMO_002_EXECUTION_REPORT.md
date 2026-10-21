# SIBOL-DEMO-002 — Execution report (Teen assistance requests)

> **Handover UUIDs:** `a91e6f42-…` (implementation); `c3e72a91-…` (predeploy); **`d5b8e31a-7c42-4f96-9a10-2e63f087bc54` (authorized deploy)**  
> **Date:** 2026-10-21  
> **Git commit/push:** **Not authorized**  
> **Firebase deploy:** **Executed** to `sibol-286d0` (rules + indexes)  
> **PA acceptance:** Pending live E2E sign-off

## 1. PA authorization

Implement smallest secure Teen assistance-request workflow; local verification only. No Barangay `cases` exposure. No commit without separate authorization.

## 2. Implemented workflow

| Screen | Route | Purpose |
|--------|-------|---------|
| Teenager dashboard | `/teen` | **New support request**, **My requests**, fictional banner, demo resource cards |
| New support request | `/teen/assistance/new` | Category dropdown, description, non-emergency notice, submit |
| My requests | `/teen/assistance` | List own requests (ref, category, date, status) |
| Request details | `/teen/assistance/:requestId` | Read-only detail for own request |

**Not implemented (explicit):** My Case (Barangay case linkage), barangay review queue, status changes after `submitted`, emergency dispatch.

## 3. Firestore data model

**Collection:** `teenAssistanceRequests/{requestId}`

| Field | Type | Notes |
|-------|------|--------|
| `teenUid` | string | Must equal `request.auth.uid` on create |
| `category` | string | `generalSupport`, `healthInformation`, `counselingReferral`, `barangayServices` |
| `description` | string | 10–500 chars; fictional demo content |
| `status` | string | `submitted` only (client create) |
| `createdAt` | timestamp | Server/client set on create |

**Index:** composite `teenUid` ASC + `createdAt` DESC — [`firestore.indexes.json`](../../firestore.indexes.json).

## 4. Security rules

Added in [`firestore.rules`](../../firestore.rules):

- Teen **create** with `assistanceRequestCreateValid()`.
- Teen **read** own documents only.
- **No** update/delete for clients.
- Barangay/MOPH/**other teens** denied.

**Emulator tests:** [`shared/firestore-rules-test/test/assistance_requests.rules.test.mjs`](../../shared/firestore-rules-test/test/assistance_requests.rules.test.mjs) — **9 tests pass** (suite total **23 pass** on 2026-10-21).

## 5. Verification results (2026-10-21)

| Check | Result |
|-------|--------|
| `flutter test` | **52 passed** |
| `flutter analyze` | **0 errors**, 9 info hints (pre-existing + dropdown `value`) |
| Firestore rules emulator | **23/23 pass** |
| `flutter build apk --debug` | **Success** |

## 6. Files changed (implementation)

**Flutter**

- `lib/core/constants/firestore_paths.dart`
- `lib/core/constants/route_constants.dart`
- `lib/core/router/app_router.dart`
- `lib/core/providers/firebase_providers.dart`
- `lib/features/teenager/domain/**` (entity, category, status, validation, repository)
- `lib/features/teenager/data/**` (model, repository impl)
- `lib/features/teenager/presentation/**` (providers, screens, notice widget)
- `lib/shared/widgets/app_text_field.dart` (`maxLines` / `minLines`)
- `test/assistance_request_validation_test.dart`
- `test/app_redirect_test.dart`

**Firebase**

- `firestore.rules`
- `firestore.indexes.json`

**Rules tests**

- `shared/firestore-rules-test/test/assistance_requests.rules.test.mjs`

## 7. Predeployment verification (2026-10-21, handover `c3e72a91-…`)

| Check | Result |
|-------|--------|
| Firebase CLI active project | **`sibol-286d0`** (`firebase use`; no `.firebaserc` in repo — use `--project sibol-286d0` on deploy) |
| Rules delta vs live T2-3 (`f1f7c76`) | **Only** `teenAssistanceRequests` + helper functions; `users`, `cases`, `followUps`, `reports`, deny-default **unchanged** |
| Teen assistance rules | Owner-only create/read; `update`/`delete` **false**; cross-teen and barangay read **denied** (emulator) |
| Index vs app query | `where teenUid ==` + `orderBy createdAt desc` matches [`firestore.indexes.json`](../../firestore.indexes.json) |
| Unrelated rules churn | **None** beyond DEMO-002 addition |
| Live rollback baseline | Ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc` — see [post-T2-3 metadata](../Verification/Artifacts/firestore.rules.post-t2-3-deploy-2026-10-21.metadata.json) and `git show f1f7c76:firestore.rules` |
| Proposed deploy artifacts | [`firestore.rules.pre-demo-002-deploy-2026-10-21.rules`](../Verification/Artifacts/firestore.rules.pre-demo-002-deploy-2026-10-21.rules), [metadata](../Verification/Artifacts/firestore.rules.pre-demo-002-deploy-2026-10-21.metadata.json) |
| Emulator tests (repo `firestore.rules`) | **23/23 pass** (re-run at predeploy) |
| Flutter tests (local) | **52/52 pass** (unchanged from implementation report) |
| **Firebase deploy executed** | **YES** — see §8 |

### Rollback procedure (if post-DEMO-002 deploy must be reverted)

1. Restore rules file from T2-3 live baseline: `git show f1f7c76:firestore.rules` → save and deploy, **or** use Firebase Console → Firestore → Rules → release prior ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc` if still available.
2. Command (after restoring file): `firebase deploy --only firestore:rules --project sibol-286d0`
3. **Indexes:** optional to remove `teenAssistanceRequests` composite index if abandoning feature; existing Barangay queries unaffected (indexes file was empty at T2-3 deploy).
4. Re-run `cd shared/firestore-rules-test && npm test` against rollback rules before declaring recovery.

**Authorization state:** Predeploy verification **complete** (handover `c3e72a91-…`).

## 8. Live Firebase deployment (handover `d5b8e31a-…`)

| Item | Evidence |
|------|----------|
| Pre-deploy file parity | `firestore.rules` and `firestore.indexes.json` **byte-identical** to predeploy artifacts |
| Command | `firebase deploy --only firestore:rules,firestore:indexes --project sibol-286d0` |
| Result | **Success** — rules compiled and released; indexes deployed |
| Rules SHA-256 (deployed source) | `f5c743fe5e4b53d6d33ae2a9a956501af22a3cc6b60e5c5f38949e454445f3a7` |
| Ruleset release UUID | **Not retrieved** (Rules API ADC quota); prior live ruleset for rollback: `3f65a5f3-19c1-4134-98d3-d5e420864afc` |
| Post-deploy metadata | [`firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json`](../Verification/Artifacts/firestore.rules.post-demo-002-deploy-2026-10-21.metadata.json) |
| Composite index | `teenAssistanceRequests`: `teenUid` ASC + `createdAt` DESC — ID `CICAgOjXh4EK` — state **READY** (gcloud, ~12:46 UTC) |

## 9. Verification evidence (automated vs manual)

### 9.1 Automated (pre/post deploy, local/CI)

| Check | Result | Date |
|-------|--------|------|
| `flutter test` | **52 passed** | 2026-10-21 |
| `flutter analyze` | **0 errors** | 2026-10-21 |
| `shared/firestore-rules-test` (rules emulator) | **23/23 passed** | 2026-10-21 |
| `flutter build apk --debug` | **Success** | 2026-10-21 |

### 9.2 Manual — live Firebase on Android emulator (PA-guided)

**Record:** [MVR-0003](../Verification/Records/MVR-0003-demo-002-teen-assistance-emulator.md)  
**Date:** 2026-10-21 (~21:12 PHT submission in fixture)  
**Outcome:** **10/10 Pass** (operator-confirmed)

Verified on live `sibol-286d0`: Teen auth; assistance form/submit; request detail; My Requests (one row); persistence across app restart; Barangay regression (six cases incl. **SIBOL QA Test**, **New case**).

Fictional counseling-referral fixture documented in MVR-0003 (no passwords).

### 9.3 Physical device (Product Owner phone)

| Test | Result |
|------|--------|
| Realme Note 50 (`0N14604I2210DB8F`) | **Pending** — install + repeat smoke test; see §10 |
| APK artifact | `sibol_app/build/app/outputs/flutter-apk/app-debug.apk` |

## 10. Physical Android installation (Product Owner phone)

From Mac (device ID from DEMO-001: `0N14604I2210DB8F`):

```bash
cd sibol_app
flutter build apk --debug
adb -s 0N14604I2210DB8F install -r build/app/outputs/flutter-apk/app-debug.apk
```

**After rules deploy:** Teen demo script — sign in → **New support request** → fictional description → **My requests** → reopen app to confirm persistence.

## 11. Demonstration readiness (post-emulator manual QA)

| Item | Status |
|------|--------|
| Firestore rules + indexes on `sibol-286d0` | **Deployed** |
| Live Teen assistance E2E (emulator) | **Pass** — MVR-0003 |
| Live Barangay regression (emulator) | **Pass** — MVR-0003 step 10 |
| PO physical phone DEMO-002 APK | **Pending** — §10 |
| No barangay staff “review” of teen requests | Narrate prototype limitation |

## 12. Product Owner requirements traceability

- **Delivered (live-verified on emulator):** My Requests workflow (Option B slice).
- **Not delivered:** My Case (Option A) — still requires separate linked disclosure model.
- **PO Option C (both):** partially addressed; My Case remains future work.

## 13. PA acceptance

Emulator manual verification **accepted** (10/10, 2026-10-21). Final demonstration acceptance pending **physical device** verification and Architect sign-off.
