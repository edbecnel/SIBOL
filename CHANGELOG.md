# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### Added

- SIBOL-REL-005: EDF release milestone documentation ([SIBOL_v0.5.0_RELEASE_MILESTONE.md](Docs/Development/SIBOL_v0.5.0_RELEASE_MILESTONE.md)).
- SIBOL-CASE-COORD-001 Increment A: case coordination Firestore rules, indexes, rules tests (59 scenarios), ADR-0005, referral callable contract (not implemented); **not deployed to Firebase**.

## [0.5.0] - 2026-10-22

**Android & iOS demonstration milestone** (not a production launch).  
GitHub: [v0.5.0](https://github.com/edbecnel/SIBOL/releases/tag/v0.5.0) @ `ba7c133`.  
EDF: [SIBOL_v0.5.0_RELEASE_MILESTONE.md](Docs/Development/SIBOL_v0.5.0_RELEASE_MILESTONE.md).

### Added

- DEMO-002–005 demonstration slices: teen assistance, barangay acknowledgment, MOPH aggregate reporting, barangay submission history/receipts (see milestone doc and linked MVRs).
- Physical-device milestone: Android backup device (Galaxy S9) workflow exercise; iOS release install and launch on physical iPhone (workflows on iOS not fully re-verified in EDF).
- EDF Core bootstrap (profile `core`) via Engineering Documentation Framework adoption scripts.
- Project identity documents, adoption tracking, and bootstrap report.
- Tranche 1 Flutter app (`sibol_app/`), Firebase config, shared functions stub, and fictional case/reporting specs (SIBOL-IMP-001).
- Tranche 1 acceptance and verification records; MVR-0001 role walkthrough (SIBOL-T1-CLOSE).
- Post-T1 corrective work items FB-001–FB-005 execution reports and work-item register (SIBOL-GOV-001 recovery).
- Tranche 2 plan, implementation gate, and delivered barangay case slices T2-1–T2-3 (SIBOL-IMP-002).
- Local Git baseline commit preserving Tranche 1 app, shared platform, Firebase source, and GOV-001 records (SIBOL-GOV-002).

### Published

- Tranche 1 and EDF governance baseline commit `fbba213` pushed to public GitHub `edbecnel/SIBOL` on `main` (SIBOL-GOV-002; authorization `e7c4192a-…`).

### Added

- SIBOL-IMP-002 T2-1: barangay read-only case detail navigation, screen, and tests (SIBOL-IMP-002).

### Changed

- SIBOL-IMP-002 T2-3: barangay case create/edit, write policy, and hardened `firestore.rules` with emulator tests (see execution report and Firebase deploy records).

### Added

- SIBOL-UI-001: official SIBOL launcher icon for Android (adaptive) and iOS via `flutter_launcher_icons`.
- SIBOL-DEMO-002: teen assistance request workflow (operator emulator pass; MVR-0003).
- SIBOL-DEMO-003: barangay incoming requests and acknowledgment; Firestore rules and `barangay`+`createdAt` index deployed to `sibol-286d0` (authorization `e8d2b614-…`; MVR-0004).

### Added

- SIBOL-DEMO-004: Barangay aggregate submit-to-MOPH UI, MOPH submitted-reports list/detail, rules-validated `reports` client create, and composite indexes (rules/indexes deployed to `sibol-286d0`, authorization `a9e4d271-…`).
- SIBOL-DEMO-004: fix MOPH/barangay report list queries to match `acceptedAt` security rules; composite indexes deployed (`e6a2f917-…`; rules unchanged).
- SIBOL-DEMO-004: operator live MOPH reporting verification Pass on emulator (`b82f6c41-…`; MVR-0005).
- SIBOL-DEMO-005: Barangay submitted-reports history, submission receipt screen, post-submit navigation (`a7c39e42-…`).
- SIBOL-DEMO-005: operator live verification Pass for history/receipt (`f4b29c61-…`; MVR-0006; post-submit nav not tested).

### Changed

- Tranche 1 execution report test evidence updated to 28/28; live Firebase `sibol-286d0` status documented.
- SIBOL-IMP-002 T2-2: read-only follow-up timeline on case detail (SIBOL-IMP-002).
- Cross-project architecture assessment (planning documentation only; not additional shipped app scope).
