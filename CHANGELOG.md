# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### Added

- EDF Core bootstrap (profile `core`) via Engineering Documentation Framework adoption scripts.
- Project identity documents, adoption tracking, and bootstrap report.
- Tranche 1 Flutter app (`sibol_app/`), Firebase config, shared functions stub, and fictional case/reporting specs (SIBOL-IMP-001).
- Tranche 1 acceptance and verification records; MVR-0001 role walkthrough (SIBOL-T1-CLOSE).
- Post-T1 corrective work items FB-001–FB-005 execution reports and work-item register (SIBOL-GOV-001 recovery).
- Proposed Tranche 2 plan and implementation gate (SIBOL-IMP-002 — not authorized).
- Local Git baseline commit preserving Tranche 1 app, shared platform, Firebase source, and GOV-001 records (SIBOL-GOV-002).

### Published

- Tranche 1 and EDF governance baseline commit `fbba213` pushed to public GitHub `edbecnel/SIBOL` on `main` (SIBOL-GOV-002; authorization `e7c4192a-…`).

### Added

- SIBOL-IMP-002 T2-1: barangay read-only case detail navigation, screen, and tests (SIBOL-IMP-002).

### Changed

- SIBOL-IMP-002 T2-3: barangay case create/edit, write policy, hardened `firestore.rules`, emulator tests (local only; not committed/deployed per PA).

### Added

- SIBOL-UI-001: official SIBOL launcher icon for Android (adaptive) and iOS via `flutter_launcher_icons` (local; not committed per PA).

### Added

- SIBOL-DEMO-004: Barangay aggregate submit-to-MOPH UI, MOPH submitted-reports list/detail, rules-validated `reports` client create, and composite indexes (rules/indexes deployed to `sibol-286d0`, authorization `a9e4d271-…`).

### Changed

- SIBOL-DEMO-003: Firestore rules (barangay-scoped teen assistance + acknowledge) and `barangay`+`createdAt` index deployed to `sibol-286d0` (authorization `e8d2b614-…`; local repo not committed per PA).

### Changed

- Tranche 1 execution report test evidence updated to 28/28; live Firebase `sibol-286d0` status documented.
- SIBOL-IMP-002 T2-2: read-only follow-up timeline on case detail (SIBOL-IMP-002).
- T2-3 case create/edit plan and cross-project architecture assessment (planning only).
