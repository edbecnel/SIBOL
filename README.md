# SIBOL

Engineering project repository for **SIBOL**, organized with the [Engineering Documentation Framework](ENGINEERING_DOCUMENTATION_FRAMEWORK.md) (EDF).

## Documentation

Start at **[PROJECT_INDEX.md](PROJECT_INDEX.md)** — the primary navigation hub for humans and AI assistants.

| Document | Purpose |
|----------|---------|
| [Project Charter](PROJECT_CHARTER.md) | Mission, scope, stakeholders, constraints |
| [Architecture Decisions](ARCHITECTURE_DECISIONS.md) | Index of significant technical decisions |
| [Adoption Status](ADOPTION_STATUS.md) | EDF bootstrap and conformance tracking |
| [EDF Bootstrap Report](EDF_BOOTSTRAP_REPORT.md) | Record of initial EDF adoption |

## Application (Tranche 1)

Native **Android/iOS** Flutter app: [`sibol_app/`](sibol_app/). Product-owner proposal: [`Docs/Reference/SIBOL.docx`](Docs/Reference/SIBOL.docx).

**Tranche 1** is functionally **accepted** (see closure docs). **Tranche 2** is planned but **not authorized** for implementation.

| Document | Purpose |
|----------|---------|
| [Tranche 1 acceptance](Docs/Development/TRANCHE_1_ACCEPTANCE_REPORT.md) | PA functional acceptance and evidence |
| [Tranche 1 verification](Docs/Verification/TRANCHE_1_VERIFICATION.md) | Automated and manual verification |
| [Tranche 1 execution report](Docs/Development/TRANCHE_1_EXECUTION_REPORT.md) | SIBOL-IMP-001 engineering delivery |
| [Work-item register](Docs/Development/WORK_ITEM_REGISTER.md) | FB items and IMP-002 status |
| [Tranche 2 plan](Docs/Development/SIBOL_IMP_002_PLAN.md) | Proposed scope (gated) |
| [Firebase setup](Docs/Development/FIREBASE_SETUP.md) | FlutterFire and provisioning pointers |

```bash
cd sibol_app && flutter pub get && flutter test
```

## Reference imagery

Pre-bootstrap reference photographs live under [docs/Reference/](docs/Reference/README.md) (repository path `Docs/Reference/` on disk).
