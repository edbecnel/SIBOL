# SIBOL-INT-001 — Execution report

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
> **Handover ID:** SIBOL-INT-001-AGENT-001  
> **Date:** 2026-10-24

## 1. Git

| Item | Value |
|------|--------|
| Starting HEAD | `d5724c6` (note: handover cited `cb77dea`; `main` included UI password toggle) |
| Ending HEAD | `7e34cb3` |
| Branch | `main` aligned with `origin/main` after push |

## 2. Emulator environment

| Check | Result |
|-------|--------|
| `firebase.emulator-demo.json` (auth 9099, firestore 8080, functions 5001) | Delivered |
| Emulator-only seed guard | `assertEmulatorEnvironment` + `--confirm-emulator-demo` |
| Synthetic identities (7 roles) | `seed_emulator_demo.mjs` |
| Sample inbox request | `demo-assist-inbox-001` |

## 3. Verification summary

| Suite | Command | Result |
|-------|---------|--------|
| Functions | `cd shared/functions && npm test` | **48/48 PASS** |
| Firestore rules | `cd shared/firestore-rules-test && npm test` | **96/96 PASS** |
| Migration | `cd shared/migration && npm test` | **10/10 PASS** |
| Provisioning | `cd shared/provisioning && npm test` | **8/8 PASS** |
| Integration smoke | `cd shared/integration && npm test` | **4/4 PASS** |
| Flutter | `cd sibol_app && flutter test` | **84/84 PASS** |
| Flutter analyze | `flutter analyze` | **0 errors** (info/warnings only) |

## 4. Journey attestation

| Journey | Automated | Manual mobile |
|---------|-----------|---------------|
| Central administration | Partial (callables tests) | NR |
| Org staff administration | `admin.operations.test.mjs` | NR |
| Teen registration | `teen.registration.test.mjs` | NR |
| Assistance + Barangay ack + MOPH referral | `prototype_journey.smoke.mjs` | NR |
| Cross-role security | Rules + smoke | NR |

**Manual PASS** for full role-by-role UI sequence is documented in the [runbook](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md) for Product Owner / operator execution.

## 5. Platform

| Platform | Result |
|----------|--------|
| Android emulator | Device `emulator-5554` available; operator walkthrough **not attested** in this agent run |
| iOS Simulator | **BLOCKED** — no Simulator runtime in `flutter devices`; wireless physical iPhone present |

## 6. Defects / fixes in scope

- Flutter Functions emulator connection added (`useFunctionsEmulator`).
- Android emulator host `10.0.2.2` for Auth/Firestore/Functions.
- `createCoordinationReferral` timestamps use `Date` for cross-package Admin SDK compatibility in integration smoke.

## 7. Product Owner decisions (unchanged)

- Teen eligibility, legal consent, parental notification, production email policy.

## 8. Readiness

**COMPLETE WITH CONDITIONS**

- Repository and emulator automation verified.
- Operator-observed end-to-end mobile demonstration and PA review pending.
- No production Firebase deploy performed.
