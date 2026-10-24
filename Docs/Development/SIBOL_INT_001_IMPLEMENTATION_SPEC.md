# SIBOL-INT-001 — Implementation / integration specification

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
> **Amendment UUID:** `e4b7c291-5a63-4d08-9f12-6c83a0e745bd` (organization identifiers)  
> **Continuation UUID:** `a6d2c941-7e35-4b80-9f26-c103e8d754ab` (AGENT-002 E2E continuation)  
> **Emulator correction UUID:** `c8f24a61-3d79-4e05-9b12-f6a730d84e25` (EMULATOR-001)  
> **Handover ID:** SIBOL-INT-001-AGENT-001  
> **Status:** Repository integration complete (emulator-backed)

## Objective

Deliver a repeatable emulator-backed prototype integrating REG-A/B/C, M1/M2 org scope, teen assistance, Barangay acknowledgment, and MOPH referral read paths.

## Deliverables

| Area | Artifact |
|------|-----------|
| Canonical emulator ports | [`firebase.json`](../../firebase.json), [`shared/emulator/canonical_ports.json`](../../shared/emulator/canonical_ports.json) |
| Integration-only emulator config | [`firebase.emulator-demo.json`](../../firebase.emulator-demo.json) (Auth 9199 / Firestore 8215) |
| Startup / seed | [`shared/scripts/start-demo-emulators.sh`](../../shared/scripts/start-demo-emulators.sh), [`seed-emulator-demo.sh`](../../shared/scripts/seed-emulator-demo.sh), [`emulator-canonical.env.sh`](../../shared/scripts/emulator-canonical.env.sh) |
| Emulator guard + seed | [`shared/provisioning/src/emulator_guard.mjs`](../../shared/provisioning/src/emulator_guard.mjs), [`seed_emulator_demo.mjs`](../../shared/provisioning/seed_emulator_demo.mjs) |
| Flutter emulators | [`main_common.dart`](../../sibol_app/lib/main_common.dart), [`emulator_config.dart`](../../sibol_app/lib/config/emulator_config.dart), [`emulator_hosts.dart`](../../sibol_app/lib/config/emulator_hosts.dart) |
| Integration smoke | [`shared/integration/test/prototype_journey.smoke.mjs`](../../shared/integration/test/prototype_journey.smoke.mjs) |
| Operator guide | [`Docs/Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md`](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md) |

## Demonstration organization identifiers

| Organization | `orgId` | `name` |
|--------------|---------|--------|
| Barangay Tres | `barangay03` | Barangay Tres |
| MOPH | `hospital01` | Misamis Oriental Provincial Hospital |

Validation and server-side generation: [ADR-REG-003](../Architecture/ADRs/ADR-REG-003-Organization-Identifier-Policy.md), `shared/reg/src/org_id.mjs`.

## Security invariants preserved

- Organization-scoped Firestore access (M2).
- Administrative capabilities do not imply `case.read` (DEC-008).
- Central Administrator does not receive case capability via seed.
- Emulator seed blocked without explicit emulator host configuration.
- No production credentials in repository.

## References

- [SPEC-REG-001](../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md)
- [CONTRACT-REG-C](../../shared/docs/CONTRACT-REG-C-Teen-Registration.md)
- [MVR-INT-001](../Verification/Records/MVR-INT-001-End-to-End-Verification-Matrix.md)
