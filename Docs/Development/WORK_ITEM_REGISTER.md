# SIBOL work-item register

> **Last updated:** 2026-10-24 (SIBOL-CASE-COORD-001 Increment A)  
> **Procedure:** [WORK_ITEM_DOCUMENTATION_PROCEDURE.md](WORK_ITEM_DOCUMENTATION_PROCEDURE.md)

| ID | Title | Status | Primary record |
|----|-------|--------|----------------|
| SIBOL-IMP-001 | Tranche 1 mobile prototype | **Closed (accepted)** | [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) |
| SIBOL-T1-CLOSE | Tranche 1 acceptance and verification | **Closed** | [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md), [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md) |
| SIBOL-FB-001 | Firebase options / iOS duplicate-app | **Closed** | [SIBOL_FB_001_EXECUTION_REPORT.md](SIBOL_FB_001_EXECUTION_REPORT.md) |
| SIBOL-FB-002 | Demo provisioning and seed | **Closed (ops)** | [SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md](SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md), [SIBOL_FB_002_EXECUTION_REPORT.md](SIBOL_FB_002_EXECUTION_REPORT.md) |
| SIBOL-FB-003 | Startup / profile loading | **Closed** | [SIBOL_FB_003_EXECUTION_REPORT.md](SIBOL_FB_003_EXECUTION_REPORT.md) |
| SIBOL-FB-004 | Sign-in input (widget tests Phase A) | **Closed (Phase A)** | [SIBOL_FB_004_EXECUTION_REPORT.md](SIBOL_FB_004_EXECUTION_REPORT.md) |
| SIBOL-FB-005 | Case list tap investigation | **Closed (deferred T2)** | [SIBOL_FB_005_EXECUTION_REPORT.md](SIBOL_FB_005_EXECUTION_REPORT.md) |
| SIBOL-GOV-001 | EDF governance traceability audit | **Closed (recovery)** | [SIBOL_GOV_001_EXECUTION_REPORT.md](SIBOL_GOV_001_EXECUTION_REPORT.md) |
| SIBOL-GOV-002 | Git baseline preservation and publication | **Closed** | [SIBOL_GOV_002_EXECUTION_REPORT.md](SIBOL_GOV_002_EXECUTION_REPORT.md) |
| SIBOL-IMP-002 / T2-1 | Read-only case detail | **Closed (published `8480c1a`)** | [SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md) |
| SIBOL-IMP-002 / T2-2 | Follow-up timeline | **Closed (published)** | [SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md) |
| SIBOL-IMP-002 / T2-3 | Case create/edit | **Rules deployed; Git published; Android write QA pending PA** | [SIBOL_IMP_002_T2_3_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_3_EXECUTION_REPORT.md) |
| SIBOL-UI-001 | Official launcher icon (Android/iOS) | **Delivered locally — pending PA acceptance** | [SIBOL_UI_001_EXECUTION_REPORT.md](SIBOL_UI_001_EXECUTION_REPORT.md) |
| SIBOL-DEMO-001 | Physical Android demo; Teen inspection and PO requirements | **In progress** (device install; Barangay/MOPH demo) | [SIBOL_DEMO_001_EXECUTION_REPORT.md](SIBOL_DEMO_001_EXECUTION_REPORT.md) |
| SIBOL-DEMO-002 | Teen assistance request workflow (demo) | **Live emulator QA pass (MVR-0003); PO phone install pending** | [SIBOL_DEMO_002_EXECUTION_REPORT.md](SIBOL_DEMO_002_EXECUTION_REPORT.md), [MVR-0003](../Verification/Records/MVR-0003-demo-002-teen-assistance-emulator.md) |
| SIBOL-DEMO-003 | Barangay incoming + acknowledge teen requests | **Baseline tagged** `sibol-demo-003-working-baseline` @ `c06fd2b` (see execution report §12) | [SIBOL_DEMO_003_EXECUTION_REPORT.md](SIBOL_DEMO_003_EXECUTION_REPORT.md) |
| SIBOL-DEMO-004 | Barangay-to-MOPH aggregate reporting (demo) | **MOPH live verification Pass (MVR-0005)** | [SIBOL_DEMO_004_EXECUTION_REPORT.md](SIBOL_DEMO_004_EXECUTION_REPORT.md) |
| SIBOL-DEMO-005 | Barangay submission receipt and report history | **Operator Pass (MVR-0006); post-submit nav untested** | [SIBOL_DEMO_005_EXECUTION_REPORT.md](SIBOL_DEMO_005_EXECUTION_REPORT.md) |
| SIBOL-REL-005 | EDF documentation — v0.5.0 demo milestone | **Published** (handover `0f3e8b29-…`) | [SIBOL_REL_005_EXECUTION_REPORT.md](SIBOL_REL_005_EXECUTION_REPORT.md), [SIBOL_v0.5.0_RELEASE_MILESTONE.md](SIBOL_v0.5.0_RELEASE_MILESTONE.md) |
| SIBOL-CASE-COORD-001 | Individual teen case coordination (Barangay–MOPH) | **Increment B code complete**; Callable deploy **blocked (Blaze)**; A rules live | [SIBOL_CASE_COORD_001_INCREMENT_B_FIREBASE_DEPLOY_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_INCREMENT_B_FIREBASE_DEPLOY_EXECUTION_REPORT.md), [MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) |

## Tranche 2 implementation gate

**Tranche 2 code, Firebase deploy, and rules changes remain blocked** until:

1. P0 + P1 governance recovery is complete (this register, acceptance, verification, FB retrospectives).
2. Project Architect issues a **separate** Tranche 2 implementation handover.

See [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md).

## Open environment / process issues

| Issue | Work item | Status |
|-------|-----------|--------|
| iOS Xcode Device Hub pointer/keyboard | FB-004 | Open — environment; widget tests pass |
