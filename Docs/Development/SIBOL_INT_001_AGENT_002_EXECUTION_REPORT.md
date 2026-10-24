# SIBOL-INT-001-AGENT-002 — Execution report (E2E continuation)

> **Handover ID:** SIBOL-INT-001-AGENT-002  
> **UUID:** `a6d2c941-7e35-4b80-9f26-c103e8d754ab`  
> **Parent:** SIBOL-INT-001-AGENT-001 (`b7e42a91-6c38-4f05-9d27-a813e0c65b42`)  
> **Date:** 2026-10-25

## Git

| Item | Value |
|------|--------|
| Starting HEAD | `efb5c28` |
| Ending HEAD | *(set at push)* |

## Emulator preparation

| Step | Result |
|------|--------|
| `start-demo-emulators.sh` (auth/firestore/functions) | **PASS** — ports 8080/9099/5001 |
| `seed-emulator-demo.sh` (disposable local passwords, not committed) | **PASS** — `barangay03`, `hospital01`, 7 users, inbox sample |
| `npm run verify:emulator` | **PASS** |
| `validate-int-001-emulator.sh` | **PASS** (warns if `.env.emulator.local` missing) |
| Production safety | Seed guard requires emulator hosts + `sibol-286d0` |

Operator note: create `.env.emulator.local` from `.env.emulator.example` for repeatable manual passwords (not stored in git).

## Scenarios A–F

| Scenario | Automated evidence | Manual mobile (operator) |
|----------|-------------------|---------------------------|
| **A** Central Admin | `admin.operations.test.mjs` (create org, deny non-central) | **NOT RUN** — no ADB-attached Android this session |
| **B** Org Admin | `admin.operations.test.mjs` (invite, capabilities, last admin) | **NOT RUN** |
| **C** Teen | `teen.registration.test.mjs`, integration smoke | **NOT RUN** |
| **D** Barangay | Integration smoke (ack + referral) | **NOT RUN** |
| **E** MOPH | Integration smoke (thread read) | **NOT RUN** |
| **F** Security | Rules suite + smoke (cross-org, central no case, teen isolation) | **NOT RUN** |

Automated surrogate: **PASS** for integrated paths covered by tests. Operator-attested UI walkthrough: **pending** (runbook §6).

## Android verification

| Check | Result |
|-------|--------|
| `flutter build apk --debug` with emulator dart-defines | **PASS** |
| `flutter run` on emulator | **BLOCKED** — `adb`/emulator device not listed after launch (SDK `platform-tools` not on PATH in agent shell; wireless iPhone only) |
| Prior session terminal logs | Suggest manual login UI exercised on emulator previously |

## iOS verification

| Check | Result |
|-------|--------|
| iOS Simulator (`apple_ios_simulator`) | **NOT RUN** — not booted/attached for Flutter in this session |
| Physical iPhone (wireless) | **NOT RUN** — emulator host not configured for device LAN demo |

## Automated tests (this session)

| Command | Result |
|---------|--------|
| `shared/reg` npm test | PASS |
| `shared/functions` npm test | **49/49** PASS |
| `shared/firestore-rules-test` npm test | **95/95** PASS (3 consecutive runs; `--test-concurrency=1` added) |
| `shared/migration` npm test | **10/10** PASS |
| `shared/provisioning` npm test | **8/8** PASS |
| `shared/integration` npm test | **4/4** PASS |
| `sibol_app` flutter test | **84/84** PASS |
| `sibol_app` flutter analyze | **0 errors** (23 info/warnings) |

**MOPH list-query flake:** Not reproduced in three full rules runs after `test-concurrency=1`. Treat as mitigated, not proven absent under all CI parallelism.

## Defects corrected

| Issue | Fix |
|-------|-----|
| No post-seed verification | `provisioning/src/verify_emulator_seed.mjs` + hook in `seed-emulator-demo.sh` |
| Rules parallel flake (historical) | `node --test-concurrency=1` in rules `package.json` |
| Operator pre-flight | `validate-int-001-emulator.sh` |

No Firestore rules or authorization policy weakened.

## EDF updated

Runbook (scenarios A–F), this report, MVR-INT-001 matrix, work register, CHANGELOG, INT-001 implementation spec.

## Blockers / approvals

- **ADR-REG-003** — Proposed (unchanged).
- **Manual E2E** — Requires operator `.env.emulator.local`, emulators running, Flutter with `USE_FIREBASE_EMULATORS=true`.
- **Android/iOS device attach** — Environment/tooling for automated UI drive not available in agent session.

## Recommended next action

1. Operator: copy `.env.emulator.example` → `.env.emulator.local`, start emulators, seed, run Flutter on Android with both dart-defines, complete runbook §6 checklist.
2. Engineering: optional `integration` job in CI with emulators (already runnable locally via `npm test`).

## Readiness

**COMPLETE WITH CONDITIONS** — repository and emulator automation verified; operator mobile demonstration not attested in this session.
