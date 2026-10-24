# MVR-REG-001 — M1/M2 repository security verification matrix

**Scope:** Emulator and unit tests in repository. **Not** a substitute for MVR-REG-001 production execution.  
**MVR-REG-001 formal status:** **NOT RUN**.

| Scenario | Evidence | Executed |
|----------|----------|----------|
| Same-org case read/write | `cases.rules.test.mjs` | Yes (emulator) |
| Org-scoped case **list** query (same org / cross org) | `cases.rules.test.mjs` | Yes |
| Cutover lockdown (no sensitive reads/writes) | `cutover_lockdown.rules.test.mjs` | Yes |
| Flutter org context (membership / forged primary) | `sibol_app/test/org_context_resolver_test.dart` | Yes (unit) |
| MOPH demo org + membership seed idempotency | `provisioning/test/demo_org_membership.test.mjs` | Yes (unit) |
| Cross-org case deny | `cases.rules.test.mjs`, `org_scoped_security.rules.test.mjs` | Yes |
| Forged `orgId` on create | `cases.rules.test.mjs` | Yes |
| Missing `orgId` on case | `cases.rules.test.mjs` | Yes |
| Immutable case `orgId` | `cases.rules.test.mjs` | Yes |
| Org admin without case caps | `cases.rules.test.mjs`, `org_scoped_security.rules.test.mjs` | Yes |
| Central admin without case caps | `org_scoped_security.rules.test.mjs` | Yes |
| Inactive account | `org_scoped_security.rules.test.mjs` | Yes |
| Follow-up inherits parent org | `org_scoped_security.rules.test.mjs` | Yes |
| Suspended org/membership | `organizations_memberships.rules.test.mjs` | Yes |
| Assistance org-scoped | `assistance_requests.rules.test.mjs` | Yes |
| Reports org-scoped | `reports.rules.test.mjs` | Yes |
| Coordination threads/registry | `case_coordination.rules.test.mjs` | Yes |
| Callable referral authorized | `createCoordinationReferral.test.mjs` | Yes (emulator) |
| Callable missing/suspended membership | `createCoordinationReferral.authz.test.mjs` | Yes |
| Callable wrong capability / forged org | `createCoordinationReferral.authz.test.mjs` | Yes |
| Duplicate referral | `createCoordinationReferral.test.mjs` | Yes |
| M1 dry-run no writes | `migration/test/apply.test.mjs` | Yes (unit) |
| M1 idempotency / orgId conflict | `migration/test/apply.test.mjs` | Yes |
| M1 mapping validation | `migration/test/mapping.test.mjs` | Yes |
| Production Firestore smoke | — | **No** |
| Production MVR-REG-001 checklist | — | **No** |
