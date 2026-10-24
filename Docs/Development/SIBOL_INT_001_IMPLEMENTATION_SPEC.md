# SIBOL-INT-001 — Implementation / integration specification

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
> **Handover ID:** SIBOL-INT-001-AGENT-001  
> **Status:** Repository integration complete (emulator-backed)

## Objective

Deliver a repeatable emulator-backed prototype integrating REG-A/B/C, M1/M2 org scope, teen assistance, Barangay acknowledgment, and MOPH referral read paths.

## Deliverables

| Area | Artifact |
|------|-----------|
| Emulator stack | [`firebase.emulator-demo.json`](../../firebase.emulator-demo.json) |
| Startup / seed | [`shared/scripts/start-demo-emulators.sh`](../../shared/scripts/start-demo-emulators.sh), [`seed-emulator-demo.sh`](../../shared/scripts/seed-emulator-demo.sh) |
| Emulator guard + seed | [`shared/provisioning/seed_emulator_demo.mjs`](../../shared/provisioning/seed_emulator_demo.mjs) |
| Flutter emulators | [`sibol_app/lib/main_common.dart`](../../sibol_app/lib/main_common.dart), [`emulator_hosts.dart`](../../sibol_app/lib/config/emulator_hosts.dart) |
| Integration smoke | [`shared/integration/test/prototype_journey.smoke.mjs`](../../shared/integration/test/prototype_journey.smoke.mjs) |
| Operator guide | [`Docs/Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md`](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md) |

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
