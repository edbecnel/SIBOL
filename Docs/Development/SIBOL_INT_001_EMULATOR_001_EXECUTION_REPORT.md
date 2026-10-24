# SIBOL-INT-001-EMULATOR-001 — Execution report

| Field | Value |
|-------|--------|
| Handover ID | SIBOL-INT-001-EMULATOR-001 |
| UUID | `c8f24a61-3d79-4e05-9b12-f6a730d84e25` |
| Parent | SIBOL-INT-001 |
| EA mode | AGENT |
| Starting Git HEAD | `591dc46` |
| Classification | COMPLETE — VERIFIED AND PUSHED (see ending HEAD in §9) |

## 1. Objective

Align Firebase emulator ports and seed/verify safety with the operator’s running stack (`firebase.json`: Firestore **8195**). Fail closed on non-local or non-canonical emulator endpoints. Do **not** seed the operator’s emulator during this handover.

## 2. Root cause

Demonstration scripts and Flutter defaulted Firestore to **8080** while `firebase.json` (and the operator CLI) use **8195**. `assertEmulatorEnvironment` did not enforce local hosts, canonical ports, or reachability before writes.

## 3. Corrected configuration

| Source | Role |
|--------|------|
| [`firebase.json`](../../firebase.json) | Authoritative operator emulator ports (Auth 9099, Firestore 8195, Functions 5001, UI 4000) |
| [`shared/emulator/canonical_ports.json`](../../shared/emulator/canonical_ports.json) | Machine-readable mirror for scripts and provisioning |
| [`shared/scripts/emulator-canonical.env.sh`](../../shared/scripts/emulator-canonical.env.sh) | Shell defaults for seed / validate / start wrappers |
| [`firebase.emulator-demo.json`](../../firebase.emulator-demo.json) | **Integration smoke only** (Auth 9199, Firestore 8215) |

## 4. Production isolation

- Seed and verify call `assertEmulatorEnvironment` with local-host checks, canonical port checks, project id `sibol-286d0`, and TCP reachability before writes / verify reads.
- Mismatched operator env (e.g. stale `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`) is rejected with an explicit diagnostic; not silently overridden.
- Operator seed was **not** executed in this handover.

## 5. Flutter

`EmulatorConfig` (`sibol_app/lib/config/emulator_config.dart`) sets Firestore **8195** when `USE_FIREBASE_EMULATORS=true`. Production mode unchanged.

## 6. Automated verification (EA)

Recorded during implementation:

| Suite | Command | Result |
|-------|---------|--------|
| Provisioning | `cd shared/provisioning && npm test` | Pass (guard + ports tests) |
| Flutter | `cd sibol_app && flutter test test/emulator_config_test.dart` | Pass |
| Integration smoke | `cd shared/integration && npm test` | Pass (isolated 9199/8215) |

## 7. Operator next step

With emulators already running on canonical ports:

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL
./shared/scripts/validate-int-001-emulator.sh
```

After PA authorization to seed, align `.env.emulator.local` with `.env.emulator.example` (Firestore **8195**), then:

```bash
./shared/scripts/seed-emulator-demo.sh
```

## 9. Git

Ending HEAD and push confirmation recorded in completion report to PA.

## 8. EDF updates

- [Emulator runbook](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md)
- [Implementation spec](./SIBOL_INT_001_IMPLEMENTATION_SPEC.md)
- [Verification matrix](../Verification/Records/MVR-INT-001-End-to-End-Verification-Matrix.md)
- [CHANGELOG](../../CHANGELOG.md)
