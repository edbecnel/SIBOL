# SIBOL-GOV-002 — Execution report (Git baseline preservation)

> **Handover UUID (baseline):** `7b4d92e1-5c38-4a60-8f21-d6a0e3947c52`  
> **Handover UUID (publication):** `e7c4192a-5b83-4d60-9a21-3f8b6c204e75`  
> **Handover UUID (publication records):** `2e8c5a71-6d40-4f93-9b27-a1e5c6038d42`  
> **Prior audit:** Read-only inventory under handover `9c2f7a64-1d83-4b50-a6e9-3f81c25d7b40`  
> **Date:** 2026-10-20 (baseline); publication records finalized 2026-10-21  
> **Repository:** https://github.com/edbecnel/SIBOL  
> **Parent baseline:** `ff35b8b` on `main`

## 1. PA authorization

Project Architect authorized baseline preparation, verification, EDF documentation, and **one local Git commit** on `main` without rewriting history (handover `7b4d92e1-…`). Subsequent authorization (`e7c4192a-…`) approved a **non-force push** of commit `fbba213` only. Firebase deploy and Tranche 2 implementation remain prohibited.

## 2. Work performed

| Action | Result |
|--------|--------|
| Preserved full working tree (Tranche 1 app, `shared/`, Firebase source, GOV-001 docs) | Baseline commit `fbba213` |
| Confirmed [`.gitignore`](../../.gitignore) excludes native Firebase JSON/plist, service accounts, node_modules, functions `lib/`, build caches | See §5 |
| Generated [`shared/functions/package-lock.json`](../../shared/functions/package-lock.json) | `npm install --package-lock-only` (no dependency upgrades) |
| Updated [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md), [CHANGELOG.md](../../CHANGELOG.md) | GOV-002 traceability |

Cross-references: [SIBOL_GOV_001_EXECUTION_REPORT.md](SIBOL_GOV_001_EXECUTION_REPORT.md), [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md), [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md).

## 3. Verification results (2026-10-20, baseline)

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
| **Commit SHA** | `fbba21363f383655c9f80718336f639f86487fa6` |

## 5. Sensitive-file staging audit (baseline)

Pre-commit checks (no secret values recorded):

| Check | Outcome |
|-------|---------|
| `google-services.json` / `GoogleService-Info.plist` | Present on disk; **not committed** (gitignore) |
| `**/service-account*.json` | None in tree |
| Demo passwords / `.env` | Not in published baseline |
| `node_modules/`, `sibol_app/build/`, `.dart_tool/`, `shared/functions/lib/` | **Not committed** (gitignore) |
| Client `firebase_options.dart` | **Committed** — intentional client config per [FIREBASE_SETUP.md](FIREBASE_SETUP.md) |
| Staged scan for `private_key` / `BEGIN PRIVATE` patterns | None in baseline commit |

## 6. GitHub publication (2026-10-20)

| Field | Value |
|-------|--------|
| **Authorization** | Handover `e7c4192a-5b83-4d60-9a21-3f8b6c204e75` |
| **Published commit** | `fbba21363f383655c9f80718336f639f86487fa6` only |
| **Push** | `git push origin main` — **success**, non-force (`ff35b8b..fbba213`) |
| **Pre-push verification** | Branch `main`; HEAD = approved SHA; clean tree; `origin/main` at `ff35b8b`; single outgoing commit; public repo; outgoing commit and history scanned for credentials (no blocking findings) |
| **Synchronization** | Local `main` and `origin/main` both at `fbba213` after push |
| **Firebase deployment** | **None** under this work item |

## 7. Outstanding nonblocking concerns

| Issue | Status |
|-------|--------|
| Firebase client API key restrictions in Console | Owner hygiene — keys are public in repo by design |
| Demo Auth password rotation (historical exposure note in FB-002 Phase A) | Owner/PA decision; not required to complete publication |
| iOS Xcode Device Hub pointer/keyboard (FB-004) | Open environment issue |
| Tranche 2 implementation | Blocked per [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md) |
| Post-clone native Firebase files | Owner must run FlutterFire locally (gitignored) |

## 8. PA disposition

**SIBOL-GOV-002 closed.** Baseline preserved locally and published to public GitHub at `fbba213`. Publication record finalized under handover `2e8c5a71-…`.
