# SIBOL-REG-001 — Direct staff provisioning and password management

**Handover UUID:** `f2d86a41-7c93-4b50-a1e8-6d9c3f207b45` (initial); **REG-FIX:** `c6e2f891-4a75-4d38-9b20-8e7f31a6c942`  
**Starting HEAD (REG-FIX):** `2818ddc`  
**Starting HEAD (initial):** `807a324`  
**Work item:** SIBOL-REG-001 (prototype staff administration)

## Summary

Academic prototype support for **direct** organization-administrator staff account creation (no invitation UI), **user-initiated password change**, and Settings consolidation. REG-B invitation **backend** preserved unchanged.

**Not production-ready.** Fictitious email identifiers do not receive mail; forgot-password is unreliable for recovery.

## Prototype staff policy

| Topic | Behavior |
|-------|----------|
| Who creates staff | Organization Administrator (`org.manage_members` + `org.manage_roles`) within own org |
| Workflow | Staff management → Add staff → display name, email, initial password, capabilities → server creates Auth + `users` + active membership |
| Invitations (UI) | Removed from ordinary Barangay/MOPH Settings; not used for prototype onboarding |
| Invitations (backend) | `regInviteStaffMember` and related callables **unchanged** |
| Session | Admin Auth session unchanged (server-side `auth.createUser`) |

## Backend

| Callable | Purpose |
|----------|---------|
| `regProvisionStaffMember` | Admin SDK create user; Firestore profile + active membership; audit `staff_provisioned_direct` |

Security: `assertCanManageOrg`, `assertAssignableCapabilities`, password min 8 chars, email validation, idempotency via `clientOperationId` and duplicate-email rules, Auth user deleted on Firestore failure.

Collection `staffProvisioningOperations` — client deny (rules).

## Flutter

| Area | Change |
|------|--------|
| Staff management | Add staff dialog; org-type capability pickers ([`org_staff_capability_options.dart`](../../sibol_app/lib/features/admin/domain/org_staff_capability_options.dart)) |
| Settings | Staff management (org admins only); **Change password**; **removed** Pending invitations |
| Routes | `/settings/change-password` |

## Production onboarding (deferred)

Documented in [SIBOL_REG_001_PRODUCTION_STAFF_ONBOARDING_DEFERRED.md](SIBOL_REG_001_PRODUCTION_STAFF_ONBOARDING_DEFERRED.md) — email invitation link, self-set password, server validation. **NOT AUTHORIZED** to implement.

## Password recovery limitation

Prototype accounts use fictitious `@sibol.local` identifiers. **Change password** (with current password) is the supported path. Login **Forgot password?** remains but cannot deliver email in demo environments.

## Verification

| Suite | Result |
|-------|--------|
| `shared/functions` `npm test` | **77** integration + unit (incl. `admin.provisionStaff.test.mjs` SP-01–SP-07) |
| `sibol_app` `flutter test` | **186** pass (incl. `settings_screen_prototype_test.dart`, `org_staff_capability_options_test.dart`) |

**Android device UI:** Not re-run in this session; widget tests cover Settings policy (UI-01–UI-04). Restart Functions emulator after deploy/build to register `regProvisionStaffMember` on the canonical stack.

## Development boundary

Unpaid prototype commitment ends **29 October 2026** (see [SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md](SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md)).

## Manual QA (2026-10-26, pre–REG-FIX)

| Test | Result |
|------|--------|
| UI-01–UI-04, SP-01, PW-01, MOPH admin Settings / Staff Management | **PASS** |
| SP-02 MOPH staff provisioning | **BLOCKED** (REG-FIX-01, REG-FIX-02) |

Accepted tag: `sibol-prototype-2026-10-26-offline-qa` (unchanged).

## REG-FIX-01 — MOPH administrator dashboard

**Root cause:** `mophOperationalContextProvider` treated missing `coordination.hospital` as a full-screen `StateError`, conflating org administration with hospital coordination.

**Fix:** MOPH home mirrors Barangay: org-administration card when `org.manage_members` + `org.manage_roles`; coordination/report streams use nullable `mophHospitalOrgIdProvider` (empty data when unauthorized, not an error).

## REG-FIX-02 — MOPH Add Staff capabilities

**Root cause:** `OrgAdminStaffScreen` defaulted organization type to Barangay when the directory cache was unset.

**Fix:** `regListOrganizationMemberships` returns authoritative `organizationType`; Add Staff / capability edit use that value (MOPH → `coordination.hospital` only).

## REG-FIX-03 — Administrator password reset

| Callable | Purpose |
|----------|---------|
| `regResetStaffMemberPassword` | Admin SDK password update, `mustChangePassword`, refresh-token revoke, audit `staff_password_reset_by_admin` |
| `regAcknowledgeMandatoryPasswordChange` | Clears `mustChangePassword` after verified client password update |

Authorization: org admin in target org, both org-management capabilities, eligible non-admin staff in same org; central admins and org admins protected. Passwords never logged or returned.

Mandatory change: `users.mustChangePassword` (server-only write); router forces `/settings/change-password`; `assertPasswordChangeNotRequired` on selected server operations (e.g. coordination referral create, staff provision).

## REG-FIX-04 — Staff identity in directory

`regListOrganizationMemberships` enriches each row with `displayName` and `email` (Auth Admin lookup) for authorized org administrators only.

## REG-FIX-05 / REG-FIX-06 — UX copy

Persistent **OK** success dialog after password change and admin reset. Barangay/MOPH admin dashboards use direct-provisioning wording (no invitation UI).

## Verification (REG-FIX)

| Suite | Result |
|-------|--------|
| `shared/functions` integration | **80** pass (incl. `admin.resetStaffPassword.test.mjs`, updated list-memberships tests) |
| `sibol_app` focused tests | `moph_dashboard_authorization_test`, `app_redirect_test`, `barangay_dashboard_capability_test` pass |

**Emulator:** Rebuild Functions (`npm run build`); reload emulator process to register new callables — **do not** reset Auth/Firestore or wipe Android data.

## Prototype closure (2026-10-26)

**Handover UUID:** `b4e81c62-7d39-4a50-9f26-c3a108e75d92`

SIBOL-REG-001 is **functionally accepted and closed** for the academic prototype scope. Manual QA evidence, PA decision, and production deployment restriction are recorded in [SIBOL_REG_001_PROTOTYPE_CLOSURE_EXECUTION_REPORT.md](SIBOL_REG_001_PROTOTYPE_CLOSURE_EXECUTION_REPORT.md).

Deferred mandatory-password backend enforcement (not production-acceptable): [SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md](SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md).

## Known limitations

- No production email for invitations or recovery.
- Mandatory password gate enforced on **selected** callables only (not every Firestore read/write path); see security investigation.
- Central admin invitation/bootstrap flows still exist server-side; not exposed on ordinary staff Settings.
- **Not production-ready** — deployment prohibited until deferred security work is completed under a future work item.
