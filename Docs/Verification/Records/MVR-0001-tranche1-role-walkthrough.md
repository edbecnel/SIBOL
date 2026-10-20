# MVR-0001 — Tranche 1 three-role manual walkthrough

> **EDF:** Manual Verification Record (lightweight; Bootstrap tier)  
> **Work items:** SIBOL-IMP-001, SIBOL-T1-CLOSE  
> **Firebase project:** `sibol-286d0`  
> **Human execution status:** Complete (per project owner report to PA, 2026-10-20)

## 1. Objective

Verify that fictional demonstration accounts can sign in and reach the correct role home on a **live** Firebase backend.

## 2. Prerequisites

- `sibol_app` built and run against `sibol-286d0` (local `google-services.json` / `GoogleService-Info.plist`).
- Demonstration users and Firestore seed present (see [PROVISIONING.md](../../../shared/docs/PROVISIONING.md)).
- Demonstration passwords available locally (not stored in this record).

## 3. Procedure

### 3.1 Barangay health worker

1. Launch app; sign out if already signed in.
2. Sign in with `barangay.demo@sibol.local`.
3. Confirm **Barangay dashboard** and fictional-data banner.
4. Confirm **five** case rows (fictional demo names).
5. Open **Settings**; confirm role label; sign out.

### 3.2 Teen

1. Sign in with `teen.demo@sibol.local`.
2. Confirm **Teenager dashboard** and resource cards.
3. Sign out.

### 3.3 MOPH

1. Sign in with `moph.demo@sibol.local`.
2. Confirm **MOPH dashboard** placeholder text (no reports list in Tranche 1).
3. Sign out.

## 4. Execution record

| Field | Value |
|-------|--------|
| **Executor** | Project owner (human) |
| **Date** | 2026-10-20 (reported to PA handover `f71b8c62-…`) |
| **Platform** | Android emulator (API 37); iOS also used for launch/data display |
| **Outcome** | **Pass** for §3.1–3.3 on Android per PA acceptance evidence |
| **Deviations** | Case row tap produces no navigation (expected T1; see FB-005) |
| **Evidence in repo** | [TRANCHE_1_ACCEPTANCE_REPORT.md](../../Development/TRANCHE_1_ACCEPTANCE_REPORT.md) ACC-01–ACC-06 |

## 5. Related automated checks

`flutter test` — 28/28 passed (2026-10-20). See [TRANCHE_1_VERIFICATION.md](../TRANCHE_1_VERIFICATION.md).
