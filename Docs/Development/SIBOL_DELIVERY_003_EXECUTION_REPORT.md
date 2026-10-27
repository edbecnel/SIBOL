# SIBOL-DELIVERY-003 — Consolidated REG-002 / REG-003 live release

**Handover UUID:** `a6d9f243-8b71-4c50-9e32-5f0a7b84c196`  
**Work items:** SIBOL-REG-002 (`7fdcb58`), SIBOL-REG-003 (`f96b362`)  
**Firebase project:** `sibol-286d0`  
**Git HEAD (start/end):** `f96b362` (unchanged; documentation-only commit follows)  
**Release engineer:** Cursor Engineering Agent  
**Release window (UTC):** 2026-10-27 (~09:21–09:25Z index/functions/APK)

## Authorization and scope

| Authorized | Executed |
|------------|----------|
| Firestore index for teen recovery listing | **Yes** — additive only |
| Deploy `regListTeensForBarangayOrgAdminRecovery` | **Yes** — create |
| Deploy `regResetTeenPasswordByBarangayOrgAdmin` | **Yes** — create |
| Deploy `regCreateOrganization` (REG-003 validation) | **Yes** — update |
| Production APK build + Galaxy S9 install (`adb install -r`) | **Yes** |
| Live password reset | **No** |
| Live hospital creation | **No** |
| Firestore rules / full Functions deploy | **No** |

## 1. Preflight inventory

| Check | Result |
|-------|--------|
| Repository | `/Users/edbecnel/Development/GitHub/SIBOL`, branch `main`, clean tree |
| HEAD | `f96b362` — matches expected |
| `7fdcb58`, `f96b362` on `origin/main` | Present (local `main` aligned) |
| Firebase CLI target | `sibol-286d0` |
| Live Functions (before) | 20 callables; **missing** both REG-002 callables; `regCreateOrganization` present (pre–REG-003 server logic) |
| `regCreateOrganization` on live | Was deployed; **updated** in this release |
| APK Firebase target | `sibol_app/lib/config/firebase_options.dart` → `projectId: sibol-286d0` |
| Application ID | `com.most.sibol.sibol_app` |
| Unexpected source changes | None |

### Index preflight (removal risk)

Normalized comparison (ignoring `__name__` ordering fields): **21 live indexes**, **22 in repo**; **0** live-only indexes; **1** repo-only index — REG-002 composite on `users` (`role`, `selectedBarangayOrgId`, `active`). **Safe to deploy** without removing unrelated indexes.

## 2. Local verification

| Suite | Result |
|-------|--------|
| `admin.teenRecovery.test.mjs` | **12/12 pass** (emulators) |
| `admin.hospitalOrganizationCreate.test.mjs` | **5/5 pass** (emulators) |
| `admin.resetStaffPassword.test.mjs` / TR-REG-01 | **Pass** (emulators) |
| Flutter: teen recovery gate + visibility | **6/6 pass** |
| Flutter: `organization_name_validation_test.dart` | **Pass** |
| `org_identity.test.mjs` | **Fail** — `AuthzError: Full name is required` in teen PSGC registration path (`resolveTeenIdentityFields`). **Unrelated** to REG-002/003 (no teen recovery or hospital create changes in that flow). **Not** a release blocker. |

Full `npm test` was **not** claimed as clean due to the above unrelated failure.

## 3. Firestore index deployment

| Item | Detail |
|------|--------|
| Command | `firebase deploy --only firestore:indexes --project sibol-286d0` |
| Rules deploy | **Not** performed (index-only) |
| Index added | `users`: `role` + `selectedBarangayOrgId` + `active` |
| Post-deploy config | Index present in `firebase firestore:indexes` output for `users` |
| Build state | CLI does not expose READY/CREATING; **confirm in Firebase Console** before live teen listing UAT |

## 4. Scoped Cloud Functions deployment

| Function | Action | Region |
|----------|--------|--------|
| `regListTeensForBarangayOrgAdminRecovery` | **Created** | `us-central1` |
| `regResetTeenPasswordByBarangayOrgAdmin` | **Created** | `us-central1` |
| `regCreateOrganization` | **Updated** | `us-central1` |

**Command:** `firebase deploy --only functions:regListTeensForBarangayOrgAdminRecovery,functions:regResetTeenPasswordByBarangayOrgAdmin,functions:regCreateOrganization --project sibol-286d0`

**Post-deploy verify** (`compare-functions.mjs`): all three callables **on live**; `regResetStaffMemberPassword` **still present**.

**Note:** CLI exited with cleanup-policy warning after successful deploy; functions reported successful create/update. No other callables were deployed.

**Live mutating tests:** None (no password reset, no hospital create).

## 5. Production APK

| Item | Value |
|------|--------|
| Path | `sibol_app/build/app/outputs/flutter-apk/app-release.apk` |
| Size | ~59.5 MB |
| Version | `0.1.0+1` (`versionName` 0.1.0, `versionCode` 1) |
| Dart defines | `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false` |
| SHA-256 | `d27a802276d89eba07168c65e21f5efebb3bd0cdd9db4a21f9765b6a4c789858` |
| Build time (UTC) | 2026-10-27T09:25:04Z |
| Git revision | `f96b362` |

APK artifact is **not** committed to git.

## 6. Galaxy S9 installation

| Item | Value |
|------|--------|
| Device | Samsung **SM-G960U** (`44524156444d3098`, USB) |
| Package | `com.most.sibol.sibol_app` (same as build; **replace install**) |
| Install | `adb install -r` — **Success** |
| Data | Preserved (no uninstall) |
| Launch | `MainActivity` resumed after launch intent |

## 7. Non-destructive acceptance (this release)

| Check | Evidence |
|-------|----------|
| REG-002 backend authorization | Emulator suite **pass** |
| REG-002 Flutter gates (org admin vs staff) | Widget tests **pass** |
| REG-003 hospital name + duplicate rules | Emulator suite **pass** |
| REG-003 Flutter name validation | Unit tests **pass** |
| Staff password-reset callable unchanged | TR-REG-01 **pass**; callable still on live |
| Role-based UI on physical device (all personas) | **Not executed** — requires signed-in manual walkthrough; deferred to PO UAT |
| Live teen list callable | **Not invoked** (index READY not CLI-verified) |
| Live password reset | **Not performed** (by authorization) |
| Live hospital create | **Not performed** (by authorization) |

## 8. Deferred / outstanding live UAT (PO approval required)

- Reset `teen.demo@sibol.local` or any live teen password via new callables.
- Create a hospital organization in live Firebase via updated `regCreateOrganization`.
- Full role-matrix UI verification on Galaxy S9 (barangay org admin vs staff vs MOPH vs central).
- Confirm Firestore index **READY** then exercise live teen recovery **listing** only.

## 9. Risks and limitations

- `mustChangePassword` enforcement remains Flutter-primary (prototype acceptance).
- Firebase Functions artifact cleanup policy warning — no functional impact; optional `firebase functions:artifacts:setpolicy` later.
- Node 20 runtime deprecation notice on deploy — track for future upgrade.

## 10. Traceability

| Reference | ID |
|-----------|-----|
| REG-002 implementation | `7fdcb58` |
| REG-003 implementation | `f96b362` |
| This delivery handover | `a6d9f243-8b71-4c50-9e32-5f0a7b84c196` |
| REG-002 contract | `shared/docs/CONTRACT-REG-002-Teen-Password-Recovery.md` |
| REG-002 / REG-003 local reports | `SIBOL_REG_002_EXECUTION_REPORT.md`, `SIBOL_REG_003_EXECUTION_REPORT.md` |

## Classification

**PARTIAL** — Authorized deploy, index, APK, and device install are **complete**. Live password-recovery and live hospital-creation UAT remain **explicitly deferred**. Device role-matrix acceptance was not manually completed in this session.
