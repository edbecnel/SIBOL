# Development

> **Documentation path:** [Project Index](../../PROJECT_INDEX.md) → Development

> **Status:** Active (software discipline adopted Tranche 1)  
> **Last Reviewed:** 2026-10-20

## Purpose

Engineering practices, tooling, and environment setup for the SIBOL software deliverable.

## Authoritative documents

| Document | Description |
|----------|-------------|
| [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md) | Index of engineering work items |
| [WORK_ITEM_DOCUMENTATION_PROCEDURE.md](WORK_ITEM_DOCUMENTATION_PROCEDURE.md) | EDF-aligned work-item doc discipline |
| [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) | SIBOL-IMP-001 engineering delivery |
| [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md) | Tranche 1 functional acceptance |
| [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md) | Tranche 1 verification summary |
| [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md) | Tranche 2 plan |
| [SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md) | T2-1 read-only case detail (accepted) |
| [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md) | T2 implementation gate |
| [FIREBASE_SETUP.md](FIREBASE_SETUP.md) | SIBOL Firebase project setup |
| [SIBOL_FB_001_EXECUTION_REPORT.md](SIBOL_FB_001_EXECUTION_REPORT.md) | Firebase options fix |
| [SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md](SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md) | Provisioning infrastructure |
| [SIBOL_FB_002_EXECUTION_REPORT.md](SIBOL_FB_002_EXECUTION_REPORT.md) | Live seed addendum |
| [SIBOL_FB_003_EXECUTION_REPORT.md](SIBOL_FB_003_EXECUTION_REPORT.md) | Startup / profile loading |
| [SIBOL_FB_004_EXECUTION_REPORT.md](SIBOL_FB_004_EXECUTION_REPORT.md) | Login widget tests |
| [SIBOL_FB_005_EXECUTION_REPORT.md](SIBOL_FB_005_EXECUTION_REPORT.md) | Case tap investigation |
| [SIBOL_GOV_001_EXECUTION_REPORT.md](SIBOL_GOV_001_EXECUTION_REPORT.md) | Governance recovery |
| [shared/docs/DEMO_ACCOUNTS.md](../../shared/docs/DEMO_ACCOUNTS.md) | Fictional demonstration accounts |
| [shared/docs/PROVISIONING.md](../../shared/docs/PROVISIONING.md) | Demo seed procedure |
| [shared/docs/OFFLINE_SYNC_MODEL.md](../../shared/docs/OFFLINE_SYNC_MODEL.md) | Offline/sync design |
| [shared/docs/REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md) | Server reporting contract (Tranche 2) |

## Application

- Flutter app: [`sibol_app/`](../../sibol_app/)
- Run: `cd sibol_app && flutter pub get && flutter run`
- Analyze: `cd sibol_app && flutter analyze`
- Test: `cd sibol_app && flutter test`

## EDF validation

```bash
/Users/edbecnel/Development/GitHub/Engineering-Documentation-Framework/scripts/adopt-edf.sh validate "/Users/edbecnel/Development/GitHub/SIBOL"
```

## Navigation

- [Project Index](../../PROJECT_INDEX.md)
- [Specifications](../Specifications/CASE_AND_REPORTING_MODEL.md)
