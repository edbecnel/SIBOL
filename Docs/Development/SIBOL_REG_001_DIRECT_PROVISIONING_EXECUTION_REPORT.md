# SIBOL-REG-001 — Direct staff provisioning and password management

**Handover UUID:** `f2d86a41-7c93-4b50-a1e8-6d9c3f207b45`  
**Starting HEAD:** `807a324`  
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

## Known limitations

- No administrator-initiated password reset.
- No production email for invitations or recovery.
- Staff list shows `accountUid` (not email) from membership listing API.
- Central admin invitation/bootstrap flows still exist server-side; not exposed on ordinary staff Settings.
