# SIBOL-INT-001-AMEND-001 — Execution report (organization identifiers)

> **Handover ID:** SIBOL-INT-001-AMEND-001  
> **UUID:** `e4b7c291-5a63-4d08-9f12-6c83a0e745bd`  
> **Parent:** SIBOL-INT-001-AGENT-001 (`b7e42a91-6c38-4f05-9d27-a813e0c65b42`)  
> **Date:** 2026-10-24

## Git

| Item | Value |
|------|--------|
| Starting HEAD | `b6fc2e5` |
| Ending HEAD | `fcc93e8` |

## Identifier contract (final)

- **Demo:** `barangay03`, `hospital01` (immutable; names stored separately).
- **New orgs:** `generateOrgId()` → 20-character collision-resistant id (no `org` prefix); clients cannot supply ids on `regCreateOrganization`.
- **Validation:** `^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$`, no `/`, no `__`, not `.` or `..`.
- **Membership:** `mbr_{orgId}__{accountUid}` unchanged.

## Subsystems updated

`shared/reg/src/org_id.mjs`, Functions `identifiers.ts` / `ids.ts`, `firestore.rules`, JSON schemas, migration fixture v2, provisioning/emulator seed, Flutter `DemoOrgConstants` + `OrgContextResolver`, rules/integration/functions tests.

## Migration compatibility

`demo_org_mapping.json` version 2 maps legacy barangay labels to `barangay03` and hospital name to `hospital01`. `loadOrgMapping` validates via `isValidOrgId`. No live migration executed.

## Automated verification

| Suite | Result |
|-------|--------|
| `shared/reg` | PASS |
| `shared/functions` npm test | **49/49** PASS |
| `shared/firestore-rules-test` | **96/96** PASS |
| `shared/migration` | **10/10** PASS |
| `shared/provisioning` | **8/8** PASS |
| `shared/integration` smoke | **4/4** PASS |
| `sibol_app` flutter test | **84/84** PASS |

## EDF

- **Added:** [ADR-REG-003](../Architecture/ADRs/ADR-REG-003-Organization-Identifier-Policy.md) (proposed, not self-approved).
- **Updated:** INT-001 implementation spec, emulator runbook, CHANGELOG, work-item register.

## Readiness

**COMPLETE WITH CONDITIONS** — ADR-REG-003 awaits PA acceptance; parent INT-001 operator mobile E2E still pending.
