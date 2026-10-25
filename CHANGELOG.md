# Changelog

All notable changes to this repository are documented here.

## [Unreleased]

### Added

- SIBOL-GEO-001: PSA PSGC bundle `psgc-psa-2025-2q` (43k nodes), hierarchy-aware Teen geo picker, demo PSGC shim for Barangay 3 → `barangay03` when demo identity enabled (`SIBOL-GEO-001-AGENT-001`).
- SIBOL-QA-007: Teen registration redirect during profile load; local self-registration intent for interrupted onboarding; prototype email-verification backlog spec (`SIBOL-QA-007-AGENT-001`).
- SIBOL-QA-006: Android debug/profile network security config for Firebase emulator cleartext to `10.0.2.2`, auth error message mapping and `userErrorMessage` for registration/sign-in (`SIBOL-QA-006-AGENT-001`).
- SIBOL-STARTUP-001: Welcome entry screen (Sign in / Register as Teen), role-aware redirect fixes, account-not-provisioned path for auth-without-profile, teen registration blank-step fix, membership query deferral for teens, membership rules `orgId` presence guard (`SIBOL-STARTUP-001-AGENT-001`).
- SIBOL-PROTOTYPE-VERIFY-001: isolated smoke emulator ports (9315/8325), INT-001 A–F automated PASS, teen assistance Firestore create lockdown, regression and Android/iOS debug builds (`SIBOL-PROTOTYPE-VERIFY-001`).
- SIBOL-INT-001 / SIBOL-OFFLINE-001 **AGENT-001:** extended org/assistance integration tests, identity rules tests, `regSubmitTeenAssistanceRequest` idempotency, Flutter offline pending-operation queue and sync (`SIBOL-INT-001-OFFLINE-001-AGENT-001`).
- SIBOL-ORG-IDENTITY-001 **AGENT-002 (M1–M3):** synthetic PSGC/NHFR reference packages, Functions geographic identity (barangay/hospital create, identity keys, idempotency, teen PSGC resolution), Flutter bundled geo picker and registration/admin flows, integration tests (`org_identity.test.mjs`), MVR partial execution — **no production deploy** (`SIBOL-ORG-IDENTITY-001-AGENT-002`).
- SIBOL-ORG-IDENTITY-001 **M0 (AGENT-001):** investigation and implementation plan publication, ADR-REG-003 acceptance package, proposed ADR-REG-004, draft contracts (GEO/NHFR/REG amendments/idempotency), proposed schemas, PSGC/NHFR acquisition docs, G-NHFR register, MVR-ORG-IDENTITY-001 (NR), SEC-REVIEW-001 deferred, roadmap — **no application code** (`SIBOL-ORG-IDENTITY-001-AGENT-001`).

### Accepted

- SIBOL-REG-001 **REG-A accepted with conditions** (implementation @ `4eafa5e`; closure `SIBOL-REG-001-REG-A-ACCEPT-CLOSE-001`). M1/M2 RC addresses `assertActiveOrganization` tests and membership query indexes in repo; full Functions `npm test` via isolated emulator still required before deploy; separate DEPLOY-R1/M1/M2 gates; MVR-REG-001 **NOT RUN**. **Not** Firebase deployment authorization.

### Added

- SIBOL-INT-001 **SEED-001:** operator emulator preflight PASS, synthetic demonstration dataset seeded and verified on canonical ports (`d7a39c42-8f61-4b05-a2e9-63c714d80f52`).
- SIBOL-INT-001 **EMULATOR-001:** canonical emulator ports (Firestore **8195**), shared `canonical_ports.json`, fail-closed seed/verify guard, Flutter `EmulatorConfig`, integration smoke on isolated 9199/8215 (`c8f24a61-3d79-4e05-9b12-f6a730d84e25`).
- SIBOL-INT-001 **AGENT-002:** emulator seed verification, pre-flight script, runbook scenarios A–F, rules test serial concurrency (`a6d2c941-7e35-4b80-9f26-c103e8d754ab`).
- SIBOL-INT-001 **AMEND-001:** organization identifiers `barangay03` / `hospital01`, revised validation contract, server-generated org ids, ADR-REG-003 proposed (`e4b7c291-5a63-4d08-9f12-6c83a0e745bd`).
- SIBOL-INT-001: emulator demonstration stack (`firebase.emulator-demo.json`), guarded emulator seed, Flutter Auth/Firestore/Functions emulator wiring, prototype journey smoke tests, operator runbook (`b7e42a91-6c38-4f05-9d27-a813e0c65b42`).
- SIBOL-REG-001 **REG-C:** teen registration callables, Barangay directory, Flutter onboarding flow, password reset, provisional policy gates (`c6f18a42-9e73-4b05-a2d8-61f0c9e735ab`).
- SIBOL-REG-001 **REG-B:** organization administration callables, staff invitation lifecycle, audit events, Flutter admin screens, emulator central-admin bootstrap (`SIBOL-REG-001-REG-B-AGENT-001`).
- SIBOL-REG-001 **M1/M2 final corrections:** org-scoped Flutter queries and `OrgContextResolver`, `firestore.rules.cutover-lockdown` + emulator tests, MOPH demo org/membership provisioning, composite indexes for org list queries, rules **94/94**, Flutter **81/81** (`SIBOL-REG-001-M1-M2-FINAL-CORRECTIONS-001`).
- SIBOL-REG-001 **M1/M2 release-ready:** isolated Functions emulator regression (ports 8226), coordination authz integration tests, migration apply/mapping tests (10), rules security matrix 87/87, deployment cutover runbook, teen `selectedBarangayOrgId` on demo provision (`SIBOL-REG-001-M1-M2-RELEASE-READY-001`).
- SIBOL-REG-001 **M1/M2 repository RC:** `shared/migration` (dry-run/idempotent plan), org-scoped Firestore rules for cases/assistance/reports/coordination, `createCoordinationReferral` org authz, Flutter `orgId` writes, composite indexes, rules tests 82/82 (`SIBOL-REG-001-M1-M2-AGENT-001`).
- SIBOL-REG-001 REG-A: organization/membership schemas, authz primitives, Firestore rules foundation (not deployed), rules tests (+11), Flutter read-only org repositories (`SIBOL-REG-001-REG-A-AGENT-001`).
- SIBOL-REG-001: Architecture documentation package — SPEC-REG-001, ADR-REG-001/002, CONTRACT-REG-001, MVR-REG-001 (verification **NOT RUN**); handover `SIBOL-REG-001-ARCH-DOC-001`.
- SIBOL-CASE-COORD-001: Registry rules v2 operator closure record (4/4 smoke attestation); MVR-0008 assistance-request-id addendum.

- SIBOL-CASE-COORD-001 registry rules v2: deploy/rollback procedure and isolated emulator test harness (`b6d2f814-…`); deployed 2026-10-24 (see deploy execution report).
- SIBOL-CASE-COORD-001 **B-HISTORY:** Barangay **Submitted referrals** list and detail (`a4e9c2d7-…`, `3e18c4b`).
- SIBOL-CASE-COORD-001 **B-HISTORY:** MVR-0009 operator **Pass (7/7)**; PA acceptance (`f2a7c619-…`).

- SIBOL-REL-005: EDF release milestone documentation ([SIBOL_v0.5.0_RELEASE_MILESTONE.md](Docs/Development/SIBOL_v0.5.0_RELEASE_MILESTONE.md)).
- SIBOL-CASE-COORD-001 Increment A: case coordination Firestore rules, indexes, rules tests (59 scenarios), ADR-0005, referral callable contract (not implemented); **deployed to `sibol-286d0`** 2026-10-24 (ruleset `d1bb212e…`).
- SIBOL-CASE-COORD-001 Increment B: `createCoordinationReferral` callable (repo), Barangay referral UI, MOPH coordination inbox/detail; Functions deploy **blocked** (Blaze plan required, 2026-10-24); Flutter tests 60/60.
- SIBOL-CASE-COORD-001 Increment B: `createCoordinationReferral` deployed to `sibol-286d0` (`us-central1`, nodejs20, 2026-10-24).
- SIBOL-CASE-COORD-001 Increment B: MVR-0008 operator **Pass** (2026-10-24); PA acceptance closure (`3c7e2a91-…`); registry rules v2 in repo, **not deployed**; staged Flutter probe via `SIBOL_COORD_REGISTRY_RULES_V2`.
- SIBOL-CASE-COORD-001: MVR-0008 defect fix — Barangay referral CTA when registry doc absent (`089ea44`).

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
