# SIBOL-FB-005 — Investigation report

> **Handover UUID:** `e8f19b63-4c72-45e1-a83d-927b6c05f142`  
> **Date:** 2026-10-20  
> **Authorization:** Read-only investigation only — no implementation

## 1. Observed behavior

Barangay dashboard lists five fictional cases; tapping a row (e.g. Bea Demo Santos) produces no navigation on Android or iOS.

## 2. Finding

**Not a Tranche 1 defect.** Tranche 1 delivered a **read-only** case stream without `ListTile.onTap`, case-detail route, or detail screen.

Evidence:

- `sibol_app/lib/features/cases/presentation/screens/barangay_home_screen.dart` — list tiles without `onTap`.
- [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) §13 — create/edit UI deferred to Tranche 2.

## 3. Classification

Functionality **intentionally deferred** to SIBOL-IMP-002 (see [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md) phase T2-1).

## 4. Verification

Read-only code and documentation review; no automated test required for “no handler” behavior.

## 5. PA disposition

PA confirmed non-defect for T1 scope in handover `f71b8c62-…`; filed in [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md) §4.
