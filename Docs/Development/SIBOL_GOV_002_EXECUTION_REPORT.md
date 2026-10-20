# SIBOL-GOV-002 — Execution report (Git baseline preservation)

> **Handover UUID:** `7b4d92e1-5c38-4a60-8f21-d6a0e3947c52`  
> **Prior audit:** Read-only inventory under handover `9c2f7a64-1d83-4b50-a6e9-3f81c25d7b40`  
> **Date:** 2026-10-20  
> **Git push:** **Not authorized** — local commit only  
> **Parent baseline:** `ff35b8b` on `main`

## 1. PA authorization

Project Architect authorized baseline preparation, verification, EDF documentation, and **one local Git commit** on `main` without rewriting history. Push, Firebase deploy, and Tranche 2 implementation remain prohibited.

## 2. Work performed

| Action | Result |
|--------|--------|
| Preserved full working tree (Tranche 1 app, `shared/`, Firebase source, GOV-001 docs) | Staged for single baseline commit |
| Confirmed [`.gitignore`](../../.gitignore) excludes native Firebase JSON/plist, service accounts, node_modules, functions `lib/`, build caches | See §5 |
| Generated [`shared/functions/package-lock.json`](../../shared/functions/package-lock.json) | `npm install --package-lock-only` (no dependency upgrades) |
| Updated [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md), [CHANGELOG.md](../../CHANGELOG.md) | This work item |

Cross-references: [SIBOL_GOV_001_EXECUTION_REPORT.md](SIBOL_GOV_001_EXECUTION_REPORT.md), [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md), [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md).

## 3. Verification results (2026-10-20)

| Check | Command / context | Result |
|-------|-------------------|--------|
| Flutter analyze | `cd sibol_app && flutter analyze` | **No errors**; 8 **info** hints (`prefer_const_constructors`, deprecated `hasFlag` in tests). Exit code 1 (infos only). |
| Flutter test | `cd sibol_app && flutter test` | **28 passed**, 0 failed |
| Provisioning | `cd shared/provisioning && npm ci && npm test` | **5/5** tests passed; npm engine/audit warnings only |
| Cloud Functions | `cd shared/functions && npm ci && npm run build` | **tsc success**; Node engine warning (host v24 vs engines 20); npm audit warnings only |
| EDF validate | `adopt-edf.sh validate` | **Success** — overall 27%, structure 100% (report gitignored under `reports/conformance/`) |

No application code was changed to force passing checks.

## 4. Git baseline commit

| Field | Value |
|-------|--------|
| **Branch** | `main` |
| **Parent** | `ff35b8b` |
| **Message** | `baseline: preserve SIBOL Tranche 1 and EDF governance recovery` |
| **Commit SHA** | This file is part of the baseline commit; use `git log -1 --format=%H` on `main` after the commit that adds this report. |

**Publication:** GitHub push **not** performed. Publication gate remains open (§6).

## 5. Sensitive-file staging audit

Pre-commit checks (no secret values recorded):

| Check | Outcome |
|-------|---------|
| `google-services.json` / `GoogleService-Info.plist` | Present on disk; **not staged** (gitignore) |
| `**/service-account*.json` | None in tree |
| Demo passwords / `.env` | Not in staged sources |
| `node_modules/`, `sibol_app/build/`, `.dart_tool/`, `shared/functions/lib/` | **Not staged** (gitignore) |
| Client `firebase_options.dart` | **Staged** — intentional client config per [FIREBASE_SETUP.md](FIREBASE_SETUP.md) |
| Staged scan for `private_key` / `BEGIN PRIVATE` patterns | None in staged set |

## 6. Outstanding issues

| Issue | Status |
|-------|--------|
| GitHub publication | **Awaiting explicit PA push authorization** |
| Demo Auth password rotation (historical exposure note in FB-002 Phase A) | Owner/PA decision before public push |
| iOS Device Hub input (FB-004) | Open environment issue |
| Tranche 2 implementation | Blocked per [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md) |
| Post-clone native Firebase files | Owner must run FlutterFire locally (gitignored) |

## 7. PA disposition

Local baseline commit complete pending EA completion report with verified `git log -1` SHA to PA.
