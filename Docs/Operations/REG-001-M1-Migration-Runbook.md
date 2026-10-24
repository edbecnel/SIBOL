# REG-001 M1 — Organization migration runbook (repository)

**Status:** Repository-ready; **live execution not authorized** in M1/M2 agent handover.

## Prerequisites

- Explicit label → `orgId` mapping file (no inference). Default: `shared/migration/fixtures/demo_org_mapping.json`.
- Firebase Admin credentials or emulator (`FIRESTORE_EMULATOR_HOST`).
- Operator review of inventory and dry-run output.

## Commands

```bash
cd shared/migration
npm install

# Inventory (counts, barangay labels)
GCLOUD_PROJECT=<project> npm run migrate -- --inventory

# Dry-run (default): plan summary + change preview
GCLOUD_PROJECT=<project> npm run migrate -- --dry-run

# Live execute (PA gate only; requires project confirmation)
GCLOUD_PROJECT=<project> npm run migrate -- --execute --confirm-project=<project>

# Post-execute verification
GCLOUD_PROJECT=<project> npm run migrate -- --execute --confirm-project=<project> --verify
```

## Automated verification (repository)

```bash
cd shared/migration && npm test
```

Covers mapping validation, plan idempotency, dry-run (no writes), `orgId` conflict skip, verify incomplete migration, and no document deletion.

## Idempotency and recovery

- Organizations and memberships: skip if document already exists.
- Document `orgId` backfill: skip when `orgId` already matches plan.
- Blocking plan errors (unmapped labels) prevent `--execute`.
- Recovery: fix mapping or data; re-run dry-run; execute is safe to re-run.

## Operator confirmation

Live `--execute` requires `--confirm-project` matching `GCLOUD_PROJECT`. Do not run against production without coordinated DEPLOY-R1 / M1 PA authorization.
