# SIBOL-REG-001 — M1/M2 execution report

**Handovers:** M1/M2 AGENT-001, M1/M2 RELEASE-READY-001, **M1/M2 FINAL-CORRECTIONS-001**  
**Starting HEAD (final corrections):** `ac1e3cbea2679873c2c7a4ad15f5c1f7bff1802f`

## Verification summary (repository / emulator)

| Suite | Result | Notes |
|--------|--------|--------|
| `shared/migration` npm test | **10/10** | Plan, mapping, apply dry-run/idempotency/conflict |
| `shared/firestore-rules-test` npm test | **94/94** | Includes cutover lockdown + org-scoped case list queries |
| `shared/functions` `npm test` | **24/24** | 6 authz unit + 18 coordination integration |
| `shared/provisioning` npm test | **6/6** | Preflight + `demo_org_membership` idempotency |
| `sibol_app` flutter test | **81/81** | Includes `org_context_resolver_test` |
| `sibol_app` flutter analyze | **0 errors** | 18 info/warnings (pre-existing style/deprecation) |
| MVR-REG-001 production | **NOT RUN** | See [matrix](../Verification/Records/MVR-REG-001-M1-M2-Repository-Security-Matrix.md) |

## Final corrections (FINAL-CORRECTIONS-001)

### Correction 1 — Org-scoped Flutter queries

- `OrgContextResolver` + Riverpod providers resolve authoritative `orgId` from profile + memberships (not caller-supplied).
- Repositories: `watchCasesForOrg`, assistance/report/coordination org-scoped streams; MOPH inbox unchanged at repository layer (`watchOpenThreadsForMoph`).
- Invalid `primaryOrgId` without matching membership **does not** fall back to another org.
- Rules tests: barangay case list `orgId` + `registeredAt` allow/deny.
- Indexes: `cases`, `teenAssistanceRequests`, `caseCoordinationThreads`, `reports` org-scoped composites in `firestore.indexes.json`.

### Correction 2 — Safe deployment cutover

- Artifact: `firestore.rules.cutover-lockdown` (fail-closed sensitive collections; own profile read only).
- Tests: `cutover_lockdown.rules.test.mjs`.
- Runbook: [M2 deployment/cutover](../Operations/REG-001-M2-Deployment-Cutover-Runbook.md) — lockdown **before** live M1 migration; **no** rollback to global barangay case rules.
- **PA authorization required** before deploying lockdown rules to any environment.

### Correction 3 — MOPH demonstration provisioning

- `ensureDemoOrganizationsAndMemberships` in `shared/provisioning/src/demo_org_membership.mjs` (idempotent orgs, memberships, `primaryOrgId`).
- Hospital demo org `org2222222222222222222222`; MOPH membership `coordination.hospital` only.
- Case payload validation requires `orgId` in preflight.

## Deployment boundary

No `firebase deploy`, no live migration, no production exports under this handover.

## EDF artifacts

- [M1/M2 implementation spec](SIBOL_REG_001_M1_M2_IMPLEMENTATION_SPEC.md)
- [M1 migration runbook](../Operations/REG-001-M1-Migration-Runbook.md)
- [M2 deployment/cutover runbook](../Operations/REG-001-M2-Deployment-Cutover-Runbook.md)
- [Repository security matrix](../Verification/Records/MVR-REG-001-M1-M2-Repository-Security-Matrix.md)

## Readiness (repository)

**READY WITH EXPLICIT PRECONDITIONS** — live cutover requires PA-approved lockdown deploy, M1 migration, M2 rules/indexes/functions, compatible app release, and MVR-REG-001 production execution (not done).
