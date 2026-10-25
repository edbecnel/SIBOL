# SIBOL-ORG-NAME-003 A01 — Organization directory foundation

**Handover UUID:** `e4b7a291-5c63-4e08-9d17-2f68b30c9a45`  
**Checkpoint:** A — schema, rules, projection, backfill utilities

## Collection

`organizationDirectory/{orgId}` — limited identity projection from `organizations/{orgId}`.

## Client access

- `get`: active authenticated users (Teen, Barangay, MOPH).
- `list`: denied.
- writes: denied (server Admin SDK only).

## Projection

`shared/functions/src/admin/organizationDirectoryProjection.ts` — hooked from organization create and status update callables.

Idempotent demo backfill: `shared/provisioning/src/sync_organization_directory.mjs`.
