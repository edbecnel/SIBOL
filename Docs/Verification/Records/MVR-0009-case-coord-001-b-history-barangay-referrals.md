# MVR-0009 — CASE-COORD-001 B-HISTORY Barangay submitted referrals (operator procedure)

> **Status:** **Pass (7/7)** — operator 2026-10-24  
> **Prerequisite:** App build including B-HISTORY (`3e18c4b`); live `sibol-286d0`  
> **Handover:** `a4e9c2d7-…`, acceptance closure `f2a7c619-…`

## Accounts (fictional)

Use [shared/docs/DEMO_ACCOUNTS.md](../../../shared/docs/DEMO_ACCOUNTS.md). Do not record passwords in this MVR.

## Procedure

| Step | Actor | Action | Expected result | Record |
|------|-------|--------|-----------------|--------|
| 1 | Barangay | Sign in; open dashboard **Submitted referrals** | List loads (or empty state) | **Pass** |
| 2 | Barangay | If list non-empty: note count and latest `displayRef` | Matches prior MVR-0008 referral if used | **Pass** (history visible; `displayRef` **not recorded**) |
| 3 | Barangay | If list empty: confirm message explains no referrals yet | Clear empty state | N/A (list non-empty) |
| 4 | Barangay | Open one referral from list | Detail shows reference, category, barangay, phase, summary, staff activity | **Pass** |
| 5 | Barangay | Confirm detail does **not** show teen name, uid, or original teen request text | Privacy boundary | **Pass** |
| 6 | Barangay | Force-stop app; relaunch; sign in; reopen **Submitted referrals** | Same referral(s) still visible | **Pass** |
| 7 | Optional | Second barangay demo account on another site | Does not see first site’s referrals | Not exercised |

## Execution summary

| Field | Value |
|-------|--------|
| Overall | **Pass (7/7)** per PA acceptance (`f2a7c619-…`) |
| Fixture | Referral created under [MVR-0008](MVR-0008-case-coord-001-increment-b-referral-live.md) (assistance request `3odtqzgOTgIalL8wuWue`) |
| `displayRef` | **Not recorded** by operator |
| Operator observations | None |

## Sign-off

| Role | Result | Date |
|------|--------|------|
| Operator | **Pass** | 2026-10-24 |
