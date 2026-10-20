# Tranche 1 functional acceptance report

> **Work items:** SIBOL-IMP-001, SIBOL-T1-CLOSE  
> **Handover UUID (PA acceptance):** `f71b8c62-2e49-4d03-a615-9c7e82b4d390`  
> **Date:** 2026-10-20  
> **Firebase project:** `sibol-286d0`  
> **Git commit/push:** Not performed as part of this record

## 1. PA decision

The Project Architect granted **functional acceptance** of verified SIBOL Tranche 1 capabilities per handover `f71b8c62-2e49-4d03-a615-9c7e82b4d390`.

Tranche 2 implementation remains **not authorized** until separately approved.

## 2. Acceptance evidence (project owner)

| ID | Criterion | Result | Notes |
|----|-----------|--------|-------|
| ACC-01 | Teen demo account → Teenager dashboard | **Pass** | Android emulator, live Firebase Auth |
| ACC-02 | Barangay demo account → five fictional cases listed | **Pass** | Includes “Bea Demo Santos” and four other seed cases |
| ACC-03 | MOPH demo account → placeholder MOPH dashboard | **Pass** | Explanatory Tranche 1 UI |
| ACC-04 | Role-based routing (three roles) | **Pass** | Confirmed on Android; automated redirect tests in repo |
| ACC-05 | Fictional-data warnings on dashboards | **Pass** | `FictionalDataBanner` on role homes |
| ACC-06 | Demo provisioning | **Pass** | Three Auth users, three `users/{uid}` profiles, five `cases`, five `followUps` (owner-confirmed) |
| ACC-07 | Automated test suite | **Pass** | 28/28 `flutter test` (see [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md)) |

## 3. Post–Tranche 1 corrective work (accepted scope)

| Work item | Summary | Primary record |
|-----------|---------|----------------|
| SIBOL-FB-001 | Firebase options consolidation (`sibol-286d0`) | [SIBOL_FB_001_EXECUTION_REPORT.md](SIBOL_FB_001_EXECUTION_REPORT.md) |
| SIBOL-FB-002 | Provisioning tooling + demo seed | [SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md](SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md), [SIBOL_FB_002_EXECUTION_REPORT.md](SIBOL_FB_002_EXECUTION_REPORT.md) |
| SIBOL-FB-003 | Startup routing / profile provider fix | [SIBOL_FB_003_EXECUTION_REPORT.md](SIBOL_FB_003_EXECUTION_REPORT.md) |
| SIBOL-FB-004 | Login widget interaction tests (Phase A) | [SIBOL_FB_004_EXECUTION_REPORT.md](SIBOL_FB_004_EXECUTION_REPORT.md) |
| SIBOL-FB-005 | Case list tap investigation (no T1 defect) | [SIBOL_FB_005_EXECUTION_REPORT.md](SIBOL_FB_005_EXECUTION_REPORT.md) |

## 4. Intentionally deferred (not Tranche 1 defects)

| Item | Disposition |
|------|-------------|
| Barangay case **selection / detail** navigation | Tranche 2 — read-only list in T1 ([TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) §13; FB-005) |
| MOPH accepted-reports list | Tranche 2 |
| `submitReport` Cloud Function | Tranche 2 stub |
| Offline pending submit UX | Tranche 2+ per [OFFLINE_SYNC_MODEL.md](../../shared/docs/OFFLINE_SYNC_MODEL.md) |

## 5. Outstanding issues

| Issue | Classification | Action |
|-------|----------------|--------|
| iOS Xcode Device Hub pointer/keyboard unreliable | Environment / testing | Use `flutter run` on simulator; no app workaround without defect evidence (FB-004) |
| Repository not yet committed | Process | Await owner/PA git authorization |
| EDF Verification MVR optional | Governance | See [MVR-0001-tranche1-role-walkthrough.md](../Verification/Records/MVR-0001-tranche1-role-walkthrough.md) |

## 6. Traceability

- Engineering delivery: [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) (SIBOL-IMP-001)  
- Verification summary: [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md)  
- Work-item index: [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md)  
- Architecture: [ARCHITECTURE_DECISIONS.md](../../ARCHITECTURE_DECISIONS.md) ADR-0002–0004  

## 7. Closure status

**Tranche 1:** Functionally **accepted** for the scope in §2–4.  
**Tranche 2:** **Not started** — see [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md).
