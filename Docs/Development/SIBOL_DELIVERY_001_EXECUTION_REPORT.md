# SIBOL-DELIVERY-001 — Execution report (pre-approval)

**Handover UUID:** `f3a718c2-6d49-4e05-b832-9c74d0a1e956`  
**Git HEAD (prep):** `8adb841`  
**Firebase:** `sibol-286d0`  
**Status:** **LIVE DEPLOY COMPLETE** (2026-10-27, PO `APPROVE FINAL DEPLOY`)

## Summary

Live Firebase is far behind the current app and emulator stack. A **full emulator export import is not feasible** (Auth passwords are not exportable; UIDs differ; QA records must not move). Prepared **selective idempotent migration** tooling, **read-only live inventory**, **Functions/rules gap analysis**, and a **live-target Android release APK** for Frecy.

## Local vs live (discovery)

| Area | Local emulator snapshot | Live `sibol-286d0` (read-only) |
|------|-------------------------|--------------------------------|
| Canonical export | `.firebase-qa-backups/po-case-identity-prep-20261026-1832` | N/A |
| Auth accounts | 12 emails (incl. 5 QA/non-demo) | 3 emails (`teen|barangay|moph.demo@sibol.local`) |
| Firestore `users` | (in export; not parsed here) | 3 |
| `cases` | — | 6 |
| `teenAssistanceRequests` | — | 5 |
| Barangay label | Mixed (PSGC-style in QA) | `Barangay Tres, Balingasag` (legacy) |
| Cloud Functions deployed | Full repo set when emulators run | **1** (`createCoordinationReferral`) |
| Firestore rules (repo) | `firestore.rules` @ HEAD (~24k) | Live rules **not** equivalent to repo (CLI fetch ≠ repo size) |

**Emulator export does not migrate:** rules, indexes, Functions code, or Auth password material.

## Migration approach (selected)

1. **Backup live** Firestore (and optionally Auth metadata) to a PO-approved GCS bucket **before any write**.
2. **Deploy** `firestore.rules`, `firestore.indexes.json`, and **all** Functions from repo `main` @ HEAD.
3. **Data:** idempotent `shared/provisioning` seed (create missing Auth by email; **never** change existing passwords; skip existing `demo-case-*` docs).
4. **Org mapping:** `shared/migration` dry-run/execute for `orgId` / membership alignment on existing live documents (no QA case ids).
5. **Exclude** emulator-only QA accounts and Maria Offline Test–class records unless separately approved.

UID preservation on live: **only when Auth user already exists for that email**; new users get new UIDs.

## Dry-run results

Command: `cd shared/delivery && npm run dry-run`

| Check | Result |
|-------|--------|
| Emulator export auth inventory | 12 accounts; **5 flagged QA/non-demo** (excluded from migration manifest) |
| Live inventory | 3 Auth users; counts as in table above |
| Functions compare | **32 repo exports missing on live**, including all demo-critical callables except `createCoordinationReferral` |
| Live writes | **None** |

Demo-critical missing on live (must deploy): `regRegisterTeenAccount`, `regSubmitTeenAssistanceRequest`, `regAcknowledgeTeenAssistanceRequest`, `regResolveRegisteredTeenForCase`, `regListRegisteredTeensForCase`, `regListBarangayDirectory`, `regSyncRegisteredTeenCasesFromProfile` (disabled stub), `healthCheck`, plus admin/registration callables as needed.

**Reporting:** `submitReport` callable in repo returns `failed-precondition` (Tranche 2). Aggregate reporting on live may rely on client Firestore writes per `features/reporting/README.md` — verify after rules deploy.

**Case identity:** App @ `8adb841` expects disabled `regSync` and independent profile/case fields — requires deployed Functions + current rules.

## Backup readiness

| Item | Status |
|------|--------|
| Emulator snapshot on disk | **Yes** — `po-case-identity-prep-20261026-1832` |
| Live Firestore export | **Not run** — requires PO-approved GCS bucket and one `gcloud firestore export` command |
| Rollback plan | Restore Firestore export; redeploy previous rules/functions from last known tag |

## Frecy Android APK (live Firebase)

| Item | Detail |
|------|--------|
| Built | **Yes** — `app-release.apk` (~57 MB) |
| SHA-256 | `765ba5f43f00f5931b4f05e664ed8a411a2e3f07fa6e5d6b0bf489f12f294311` |
| Dart defines | `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false` |
| Install doc | [SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md](../Operations/SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md) |

APK is **not** committed (build artifact). Transfer to phone when ready.

## Demo account inventory (emails only)

**Live (existing):** `teen.demo@sibol.local`, `barangay.demo@sibol.local`, `moph.demo@sibol.local`

**Emulator-only (do not migrate without approval):** `maria.qa.staff@sibol.local`, `moph.qa.staff@sibol.local`, `teen.qa02@example.com`, `teen.qa03@example.com`, `teen.qa006.agent@example.com`

**Additional fictional emulator staff (optional after deploy):** `central.admin@sibol.local`, `barangay.org.admin@sibol.local`, `backup.barangay.admin@sibol.local`, `moph.org.admin@sibol.local` — provision via emulator seed tooling or extended live provisioning, not raw export import.

## Product Owner approval request (single gate)

Reply **APPROVE LIVE DELIVERY** only if all of the following are acceptable:

1. **Backup:** Run Firestore export to a bucket you designate (engineering executes; no passwords in repo).
2. **Deploy to `sibol-286d0`:** Current `firestore.rules`, `firestore.indexes.json`, and **full** Cloud Functions from repo `main`.
3. **Data migration:** Idempotent demo provisioning + orgId migration scripts — **create** missing demo resources; **no** password resets; **no** overwrite of existing `demo-case-*` documents; **exclude** QA emulator accounts.
4. **Auth:** Create Auth users only for approved fictional emails that are missing; existing demo passwords unchanged.

**Not included unless you ask:** deleting live data, importing QA cases, iOS build, Play Store publish, weakening security rules.

## Live execution (2026-10-27)

| Step | Result |
|------|--------|
| Backup bucket | **Created** `gs://sibol-286d0-delivery-backups` (`asia-southeast1`) |
| Firestore export | **OK** `gs://sibol-286d0-delivery-backups/pre-delivery-20261027T023121Z/` |
| Firestore rules | **Deployed** from repo |
| Firestore indexes | **Deployed** from `firestore.indexes.json` |
| Cloud Functions | **11 deployed** (demo-minimal set); `healthCheck` → `{"ok":true}` |
| Demo orgs/memberships | **Created** `barangay03`, `hospital01`, 2 memberships, `organizationDirectory` |
| Auth / demo-case bodies | **Unchanged** (no password resets; cases not overwritten) |
| `orgId` backfill | **17 documents** additive `orgId` only (6 cases incl. non-demo `t40YTI3e…`, assistance, reports, coordination) |
| QA import | **Not performed** |

Deploy note: Firebase CLI exited non-zero on **artifact cleanup policy** prompt only; all listed functions reported success.

## Post-deploy verification

| Check | Result |
|-------|--------|
| `healthCheck` (live HTTPS) | PASS |
| `cases/demo-case-001`.orgId | `barangay03` |
| `organizations/barangay03` | exists |
| `organizationMemberships` | 2 active |

Full UI walkthrough on Frecy device: **pending PO** (APK already built for live Firebase).

### Central Administrator completion (2026-10-27, handover `b7e19a42-…`)

| Item | Result |
|------|--------|
| Live Auth `central.admin@sibol.local` | **Created** (new UID; password from `SIBOL_EMULATOR_PASSWORD_CENTRAL` via script, not logged) |
| Firestore profile | `role: barangay`, `active: true`, `isCentralAdmin: true` |
| Admin Functions deployed | 9 callables (no `bootstrapCentralAdminForEmulator`) |
| Flutter | **Manage staff** on Central Admin org detail → `OrgAdminStaffScreen` |
| APK | Rebuilt for live Firebase; installed on Galaxy S9 (`install -r`) |

Script: `shared/delivery/scripts/provision-central-admin-live.mjs`

## Remaining limitations

1. **`submitReport`** callable still returns Tranche 2 disabled; aggregate report flow uses client Firestore paths.
2. **Release APK** uses debug signing (`build.gradle.kts`).
3. **Functions artifact cleanup policy** not set (minor storage cost; run `firebase functions:artifacts:setpolicy` if desired).
4. **Admin/staff callables** not deployed (out of demo-minimal scope).

## Tooling added

- `shared/delivery/` — `npm run dry-run`, `inventory-export`, `compare-functions`, `apply-demo-orgs-live.mjs`
- Mapping alias `Barangay Tres, Balingasag` → `barangay03`
- This report and Frecy install guide

### Central staff screen + Barangay org admin restore (2026-10-27, handover `c7f42a91-…`)

| Item | Status |
|------|--------|
| Flutter `OrgAdminStaffScreen` gate | Central Admin may open staff UI: `isCentral \|\| managed.contains(orgId)` |
| Regression test | `account_memberships_provider_test.dart` — central admin without org membership |
| Live `barangay.org.admin@sibol.local` | **Not provisioned** — dry-run only (see below) |
| `regResetStaffMemberPassword` | Already on live rev `regresetstaffmemberpassword-00002-qal` (no redeploy in this handover) |
| Live password reset UAT | **Not executed** — requires separate PO authorization |

**Dry-run (live read + plan):** `node shared/delivery/scripts/provision-barangay-org-admin-live.mjs --dry-run`

| Field | Dry-run result |
|-------|----------------|
| `organizationExists` | `true` (`barangay03`) |
| `existingAuthUid` | `null` (account absent in live Auth) |
| Planned actions | Create Auth user, Firestore profile (`barangay`, active), org-admin membership (`org.manage_members`, `org.manage_roles`), `primaryOrgId: barangay03` |
| Blueprint | Matches `EMULATOR_DEMO_USER_BLUEPRINTS.barangay_org_admin` (new live UID; no emulator UID copy) |
| Password env | `SIBOL_EMULATOR_PASSWORD_BARANGAY_ORG_ADMIN` (available locally; never logged) |

**Execute (blocked pending PO):** `node shared/delivery/scripts/provision-barangay-org-admin-live.mjs --execute --confirm-project=sibol-286d0`

**PO approval for live provisioning:** Reply **APPROVE LIVE BARANGAY ORG ADMIN PROVISION** to run execute above. Password reset UAT remains **APPROVE LIVE PASSWORD RESET UAT** separately.
