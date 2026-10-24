# SIBOL-INT-001-AMEND-001 — Execution report (organization identifiers)

> **Handover ID:** SIBOL-INT-001-AMEND-001  
> **UUID:** `e4b7c291-5a63-4d08-9f12-6c83a0e745bd`  
> **Parent:** SIBOL-INT-001-AGENT-001 (`b7e42a91-6c38-4f05-9d27-a813e0c65b42`)  
> **Date:** 2026-10-24  
> **Finalization session:** 2026-10-24 (verify, document closure, push)

## Git

| Item | Value |
|------|--------|
| Implementation starting HEAD | `b6fc2e5` |
| Finalization session starting HEAD | `88cf23ec5dff9f8ace10c1150c11fc14153c0ab5` |
| Ending HEAD | `3da7750` (`3da7750925dd913b90fd8ed4f84c7d4c27154676`) |
| Commits (implementation) | `fcc93e8` feat(int-001): adopt barangay03 and hospital01 org identifiers; `88cf23e` docs: AMEND-001 ending HEAD |
| `main` vs `origin/main` | Aligned after push |

## Identifier contract (final)

- **Demo:** `barangay03`, `hospital01` (immutable; names stored separately).
- **New orgs:** `generateOrgId()` → 20-character collision-resistant id (no fixed prefix); clients cannot supply ids on `regCreateOrganization`.
- **Validation:** `^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$`, no `/`, no `__`, not `.` or `..` — `shared/reg/src/org_id.mjs`, Functions, `firestore.rules`, Flutter `OrgContextResolver`.
- **Membership:** `mbr_{orgId}__{accountUid}` unchanged.

## Subsystems updated

Organization schemas, REG-B creation, provisioning/emulator seed, Functions, Firestore rules, Flutter demo constants and org context, migration fixture v2, contracts, tests.

## Migration compatibility

`demo_org_mapping.json` version 2; explicit label → id mapping; `isValidOrgId` on load. No live migration.

## Automated verification (finalization re-run)

| Suite | Result |
|-------|--------|
| `shared/reg` npm test | PASS |
| `shared/functions` npm test | **49/49** PASS |
| `shared/firestore-rules-test` npm test | **96/96** PASS (one intermittent flake on full parallel run; passes on immediate retry) |
| `shared/migration` npm test | **10/10** PASS |
| `shared/provisioning` npm test | **8/8** PASS |
| `shared/integration` smoke | **4/4** PASS |
| `sibol_app` flutter test | **84/84** PASS |
| `sibol_app` flutter analyze | **0 errors** (23 info/warnings, pre-existing) |

Targeted coverage: `identifiers.test.mjs`, `admin.operations.test.mjs` (`generateOrgId`), teen registration invalid id, integration smoke (teen `barangay03`, MOPH `hospital01`, cross-org deny).

## EDF

- **Proposed:** [ADR-REG-003](../Architecture/ADRs/ADR-REG-003-Organization-Identifier-Policy.md)
- **Updated:** CONTRACT-REG-001, CONTRACT-REG-C, INT-001 spec, runbook, MVR-INT-001, work register, CHANGELOG

## Readiness

**COMPLETE — VERIFIED AND PUSHED** (organization identifier amendment scope only).

Parent SIBOL-INT-001 operator mobile E2E and ADR-REG-003 PA acceptance are out of scope for this STOP boundary.
