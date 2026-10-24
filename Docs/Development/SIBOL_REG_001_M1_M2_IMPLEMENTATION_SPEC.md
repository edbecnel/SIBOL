# SIBOL-REG-001 — M1/M2 implementation specification (repository)

**Work item:** SIBOL-REG-001  
**Scope:** M1 migration tooling (dry-run); M2 organization-scoped authorization in rules, Functions, app, indexes, tests.

## M1

- Package: `shared/migration/` (plan, inventory, apply, CLI, fixtures, unit tests).
- Explicit mapping only (`demo_org_mapping.json`); unmapped labels surface as plan errors.
- Backfill targets: `cases`, `teenAssistanceRequests`, `reports`, `caseCoordinationThreads`, `barangayCoordinationRegistry`; user `primaryOrgId` / teen `selectedBarangayOrgId`.

## M2

- **Cases / follow-ups:** `orgId` required; `case.read` / `case.write` via `capabilityGranted`; immutable `orgId`; no `isBarangay()` global access.
- **Assistance / reports / coordination:** resource `orgId` + capabilities (`coordination.barangay`, `report.submit`, `coordination.hospital`); legacy barangay string not used for authorization.
- **Callable:** `createCoordinationReferral` uses membership + `coordination.barangay` on assistance `orgId`; writes `orgId` on thread and registry.
- **Flutter:** `orgId` on case, assistance, and aggregate report writes (demo org constants).

## Release bundle

Deploy together: `firestore.rules`, `firestore.indexes.json`, Functions, app build, M1 data migration.
