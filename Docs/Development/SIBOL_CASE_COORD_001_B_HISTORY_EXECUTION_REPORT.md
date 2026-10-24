# SIBOL-CASE-COORD-001 — B-HISTORY execution report

> **Handover UUID:** `a4e9c2d7-6f31-4b85-9c20-1d7e53f8a642`  
> **Git baseline:** `9055f70` (docs) → `3e18c4b` (implementation)  
> **Acceptance:** [B-HISTORY acceptance report](SIBOL_CASE_COORD_001_B_HISTORY_ACCEPTANCE_REPORT.md) (`f2a7c619-…`)  
> **Firebase deploy:** **NO**

## 1. Delivered

| Area | Summary |
|------|---------|
| Dashboard | **Submitted referrals** entry on Barangay home |
| List | `BarangaySubmittedReferralsScreen` — all phases via `watchSubmittedReferralsForBarangay` |
| Detail | `BarangayCoordinationDetailScreen` + `CoordinationThreadDetailBody` |
| Rules tests | Barangay all-phase list query; teen/cross-site denial |
| Operator | [MVR-0009](../Verification/Records/MVR-0009-case-coord-001-b-history-barangay-referrals.md) **Pass (7/7)** |

## 2. Firestore compatibility

- **Rules:** No changes; uses existing barangay thread/staffEvent read paths.
- **Indexes:** Uses deployed composite `barangay` + `phase` + `lastStaffEventAt` with `phase` `whereIn` (4 values).

## 3. Verification

| Command | Result |
|---------|--------|
| `cd sibol_app && flutter test` | **72/72** pass |
| `cd sibol_app && flutter analyze` | 0 errors |
| `shared/firestore-rules-test` (`case_coordination.rules.test.mjs`) | **30/30** pass |
| Full `npm test` | Not run — port **8195** in use; run `npm test` when emulator port free |

## 4. PA acceptance

**Accepted** — operator MVR-0009 **Pass (7/7)**; see [acceptance report](SIBOL_CASE_COORD_001_B_HISTORY_ACCEPTANCE_REPORT.md).

## 5. Outstanding (not blocking B-HISTORY)

| Item | Status |
|------|--------|
| Registry rules v2 | Deploy **pending** |
| Increment C | **Not started** |
