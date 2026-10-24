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
| [SIBOL_REG_001_ARCH_DOC_EXECUTION_REPORT.md](SIBOL_REG_001_ARCH_DOC_EXECUTION_REPORT.md) | SIBOL-REG-001 architecture documentation (handover ARCH-DOC-001) |
| [SIBOL_REG_001_REG_A_IMPLEMENTATION_SPEC.md](SIBOL_REG_001_REG_A_IMPLEMENTATION_SPEC.md) | REG-A implementation baseline |
| [SIBOL_REG_001_REG_A_EXECUTION_REPORT.md](SIBOL_REG_001_REG_A_EXECUTION_REPORT.md) | REG-A foundation delivery |
| [SIBOL_CASE_COORD_001_PLAN.md](SIBOL_CASE_COORD_001_PLAN.md) | Barangay–MOPH case coordination |
| [SIBOL_CASE_COORD_001_INCREMENT_B_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_INCREMENT_B_EXECUTION_REPORT.md) | Increment B — referral + MOPH review (local) |
| [SIBOL_v0.5.0_RELEASE_MILESTONE.md](SIBOL_v0.5.0_RELEASE_MILESTONE.md) | **v0.5.0** Android & iOS demonstration milestone (published 2026-10-22) |
| [WORK_ITEM_DOCUMENTATION_PROCEDURE.md](WORK_ITEM_DOCUMENTATION_PROCEDURE.md) | EDF-aligned work-item doc discipline |
| [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) | SIBOL-IMP-001 engineering delivery |
| [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md) | Tranche 1 functional acceptance |
| [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md) | Tranche 1 verification summary |
| [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md) | Tranche 2 plan |
| [SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md) | T2-1 read-only case detail (accepted, published) |
| [SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md) | T2-2 follow-up timeline (accepted) |
| [SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md](SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md) | SpeakUp / platform assessment (planning) |
| [SIBOL_IMP_002_T2_3_PLAN.md](SIBOL_IMP_002_T2_3_PLAN.md) | T2-3 plan |
| [SIBOL_IMP_002_T2_3_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_3_EXECUTION_REPORT.md) | T2-3 case create/edit (pending acceptance) |
| [FIRESTORE_RULES_T2_3.md](FIRESTORE_RULES_T2_3.md) | T2-3 rules hardening (deployed 2026-10-21) |
| [SIBOL_UI_001_EXECUTION_REPORT.md](SIBOL_UI_001_EXECUTION_REPORT.md) | Launcher icon (Android/iOS) |
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
| [shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md](../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md) | REG proposed callables (not implemented) |

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
