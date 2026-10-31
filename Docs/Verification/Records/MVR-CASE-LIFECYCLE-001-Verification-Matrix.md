# MVR-CASE-LIFECYCLE-001 — Verification matrix

**Work item:** SIBOL-CASE-LIFECYCLE-001  
**Acceptance handover UUID:** `e5b74a19-3c86-4f20-a91d-6b728c05e493`  
**Execution date:** 2026-11-01

## Automated (Functions)

| ID | Requirement | Method | Environment | Result | Evidence |
|----|-------------|--------|-------------|--------|----------|
| V1 | Open case from acknowledged assistance | `openBarangayCaseFromAssistance.test.mjs` | `demo-sibol-coord-fn` isolated exec | **Pass** | `run-case-lifecycle-integration-tests.mjs` |
| V2 | Idempotent / concurrent open → one case | Same + concurrent test | Same | **Pass** | Same runner |
| V3 | Close blocked with active referral | `transitionBarangayCaseStatus.test.mjs` | Same | **Pass** | Same runner |
| V4 | Full coordination + resolve/close + audit | `case_lifecycle_flow.test.mjs` | Same | **Pass** | Same runner |
| V5 | Cross-hospital MOPH denied | `case_lifecycle_flow.test.mjs` | Same | **Pass** | Same runner |

**Runner:** `cd shared/functions && node scripts/run-case-lifecycle-integration-tests.mjs`  
**Last run:** 7/7 pass (post-acceptance rules remediation).

## Firestore security (focused rules harness)

| ID | Requirement | Method | Environment | Result | Evidence |
|----|-------------|--------|-------------|--------|----------|
| V8 | Client lifecycle field writes blocked; lifecycleEvents denied; linked-case follow-ups allowed | `cases.rules.test.mjs` (+ coordination/registry tests) | `demo-sibol-rules` isolated Firestore exec | **Pass** | 80/80 focused: `cases`, `case_coordination`, `assistance_requests` |
| V8a | MOPH coordination list queries constrained to `targetHospitalOrgId` | `case_coordination.rules.test.mjs` | Same | **Pass** | Updated query helper matches production repository query |

## Flutter UI / wiring

| ID | Requirement | Method | Environment | Result | Evidence |
|----|-------------|--------|-------------|--------|----------|
| V6 | Flutter open-case UI wired | Code inspection + prior `dart analyze` | Repo | **Pass** | Unchanged |
| V7 | Barangay coordination response panel wired | Code inspection | Repo | **Pass** | Unchanged |
| V10 | Manual / device emulator UI walkthrough | [Walkthrough](../Development/SIBOL_CASE_LIFECYCLE_001_EMULATOR_WALKTHROUGH.md) + `case_lifecycle_emulator_device_test.dart` | Canonical emulators + seed + `emulator-5554` | **FAIL** (harness) / **NOT EXECUTED** (manual) | Device test fails before step 1 UI assertions; manual steps not signed off |

## Offline regression

| ID | Requirement | Method | Environment | Result | Evidence |
|----|-------------|--------|-------------|--------|----------|
| V9 | Offline follow-ups unchanged | Device workflow (walkthrough step 13) | Isolated emulator device | **NOT EXECUTED** | Blocked by same device harness issue as V10 |

## Defect remediation (acceptance tranche)

| Defect | Correction | Re-verification |
|--------|------------|-----------------|
| Rules unit tests: MOPH coordination reads hit expression budget / missing hospital scope on fixtures | Reduced membership rule evaluations (`let` bindings); single-get coordination thread reads; test threads include `targetHospitalOrgId`; MOPH list query matches app filter | Focused rules 80/80 pass |
| V8 not previously executed | Added lifecycle-linked case rules tests in `cases.rules.test.mjs` | Included in 80/80 pass |

## Classification

**IMPLEMENTED — ACCEPTANCE PENDING** (server verification complete; device UI walkthrough and offline regression not verified in this environment).
