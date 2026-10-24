# SIBOL-INT-001-SEED-001 — Execution report

| Field | Value |
|-------|--------|
| Handover ID | SIBOL-INT-001-SEED-001 |
| UUID | `d7a39c42-8f61-4b05-a2e9-63c714d80f52` |
| Parent | SIBOL-INT-001 |
| Prior handover | EMULATOR-001 (`c8f24a61-3d79-4e05-9b12-f6a730d84e25`) |
| Starting Git HEAD | `4513446` |
| Classification | COMPLETE — SEEDED AND VERIFIED |

## 1. Effective emulator configuration

| Service | Endpoint |
|---------|----------|
| Authentication | `127.0.0.1:9099` |
| Firestore | `127.0.0.1:8195` |
| Cloud Functions | `127.0.0.1:5001` |
| Emulator UI | `127.0.0.1:4000` |

Source: [`firebase.json`](../../firebase.json), [`shared/emulator/canonical_ports.json`](../../shared/emulator/canonical_ports.json).

## 2. Local environment correction

| Finding | Action |
|---------|--------|
| Shell exported stale `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` | Cleared for EA commands via `unset FIRESTORE_EMULATOR_HOST` (operator should unset or fix shell profile if persistent) |
| `.env.emulator.local` absent | Created from [`.env.emulator.example`](../../.env.emulator.example) with canonical hosts and **locally generated disposable passwords** (gitignored; not recorded in EDF) |
| `.env.emulator.example` | Already canonical (`8195`); no repo change |

## 3. Production isolation preflight

**Command:** `./shared/scripts/validate-int-001-emulator.sh` (after `unset FIRESTORE_EMULATOR_HOST`)

**Result:** **PASS** — ports 8195 / 9099 / 5001 open; `preflight-emulator-env.mjs` confirmed local canonical hosts and reachability.

## 4. Synthetic-data inspection (pre-seed)

Read-only Admin SDK probe against emulators:

- Organizations `barangay03`, `hospital01`: **missing**
- `demo-assist-inbox-001`: **missing**
- Auth users: **0**
- Memberships: **0**

**Seed script behavior** ([`emulator_seed.mjs`](../../shared/provisioning/src/emulator_seed.mjs)): idempotent **create-if-missing** for orgs, auth users, profiles (merge only null fields), memberships, and sample assistance request. **No** collection-wide delete or emulator reset.

**Conclusion:** Empty disposable emulator state; seed authorized.

## 5. Seed execution

**Command:** `./shared/scripts/seed-emulator-demo.sh`

**Result:** **PASS** — created orgs, seven fictional Auth users, memberships, `demo-assist-inbox-001`.

## 6. Seed verification

**Automated:** `npm run verify:emulator` (via seed wrapper) — **PASS**

- `barangay03` (barangay, Barangay Tres)
- `hospital01` (hospital, Misamis Oriental Provincial Hospital)
- Sample inbox `orgId=barangay03`

**Extended automated checks (EA, read-only):**

| Role | Email | Membership / routing |
|------|-------|---------------------|
| Central Administrator | `central.admin@sibol.local` | `isCentralAdmin=true` |
| Barangay Org Admin | `barangay.org.admin@sibol.local` | `mbr_barangay03__{uid}`, `org.manage_*` |
| Barangay staff | `barangay.demo@sibol.local` | `mbr_barangay03__{uid}`, case + coordination.barangay |
| Backup Barangay Org Admin | `backup.barangay.admin@sibol.local` | `mbr_barangay03__{uid}`, `org.manage_*` |
| MOPH Org Admin | `moph.org.admin@sibol.local` | `mbr_hospital01__{uid}`, `org.manage_*` |
| MOPH staff | `moph.demo@sibol.local` | `mbr_hospital01__{uid}`, `coordination.hospital` |
| Teen | `teen.demo@sibol.local` | `selectedBarangayOrgId=barangay03` |

Membership IDs follow `mbr_{orgId}__{accountUid}`.

## 7. Manual observation

Not in scope for this handover (no mobile E2E).

## 8. Blockers

None for demonstration dataset readiness on emulators.

## 9. Recommended next action

Operator mobile walkthrough per [runbook §6](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md) with `USE_FIREBASE_EMULATORS=true`; sign in using passwords from local `.env.emulator.local` only.
