# MVR-0009 — CASE-COORD-001 B-HISTORY Barangay submitted referrals (operator procedure)

> **Status:** Prepared — **not executed** by EA  
> **Prerequisite:** App build including B-HISTORY (`a4e9c2d7-…`); live `sibol-286d0`  
> **Handover:** `a4e9c2d7-6f31-4b85-9c20-1d7e53f8a642`

## Accounts (fictional)

Use [shared/docs/DEMO_ACCOUNTS.md](../../../shared/docs/DEMO_ACCOUNTS.md). Do not record passwords in this MVR.

## Procedure

| Step | Actor | Action | Expected result | Record |
|------|-------|--------|-----------------|--------|
| 1 | Barangay | Sign in; open dashboard **Submitted referrals** | List loads (or empty state) | Pass/Fail |
| 2 | Barangay | If list non-empty: note count and latest `displayRef` | Matches prior MVR-0008 referral if used | Reference(s) |
| 3 | Barangay | If list empty: confirm message explains no referrals yet | Clear empty state | Pass/Fail |
| 4 | Barangay | Open one referral from list | Detail shows reference, category, barangay, phase, summary, staff activity | Pass/Fail |
| 5 | Barangay | Confirm detail does **not** show teen name, uid, or original teen request text | Privacy boundary | Pass/Fail |
| 6 | Barangay | Force-stop app; relaunch; sign in; reopen **Submitted referrals** | Same referral(s) still visible | Pass/Fail |
| 7 | Optional | Second barangay demo account on another site | Does not see first site’s referrals | Pass/Fail |

## Sign-off

| Role | Result | Date |
|------|--------|------|
| Operator | Pending | |
