# MVR-0008 — CASE-COORD-001 Increment B live referral (operator procedure)

> **Status:** **Pass** (steps 1–9, operator 2026-10-24)  
> **Prerequisite:** `createCoordinationReferral` deployed on `sibol-286d0` — **met** 2026-10-24 (`e9b43c72-…`)  
> **Handover:** `d8e3b7a1-…`, deploy retry `e9b43c72-…`, defect `e4c7a219-…`, acceptance `3c7e2a91-…`

## Accounts (fictional)

Use [shared/docs/DEMO_ACCOUNTS.md](../../../shared/docs/DEMO_ACCOUNTS.md). Do not record passwords in this MVR.

## Procedure

| Step | Actor | Action | Expected result | Record |
|------|-------|--------|-----------------|--------|
| 1 | Teen | Sign in; submit new assistance request (or use un-referred acknowledged request if available) | Request appears in **My Requests** | Request document id |
| 2 | Barangay | Sign in; open **Incoming requests**; select request | Detail shows **Submitted** status | Request id |
| 3 | Barangay | Tap **Acknowledge receipt** (if not already acknowledged) | Status **Acknowledged** | Timestamp |
| 4 | Barangay | Tap **Refer to MOPH coordination** | Referral form opens; privacy notice visible | — |
| 5 | Barangay | Enter fictional summary **without** teen name/contact; tap **Review before submit** | Preview shows category, barangay, summary only — **no** teen description from step 1 | Notes |
| 6 | Barangay | **Submit referral to MOPH** | Success dialog with `SIBOL-REF-…` reference | `displayRef`, time |
| 7 | Barangay | Return to same request detail | “Referral already submitted” (no second submit) | — |
| 8 | MOPH | Sign in; open dashboard **Individual case coordination** | New row: reference, barangay, category, phase **Referred** | Thread list entry |
| 9 | MOPH | Open referral detail | Shows reference, category, barangay summary, staff activity; **no** teen name, uid, or original teen text | Pass |
| 10 | Teen | Optional: progress link | Generic progress only if Increment D link present | — |

## Execution summary

| Field | Value |
|-------|--------|
| Result | **Pass** (steps 1–9) |
| Assistance request id | `3odtqzgOTgIalL8wuWue` |
| Referral submission | Pass |
| Duplicate prevention | Pass |
| MOPH inbox | Pass |
| MOPH referral detail | Pass; permitted fields only; no teen identity or original request narrative |
| Generated `displayRef` | **Not recorded** by operator |

## Defect note (resolved)

**MVR-0008 referral action missing (pre-`089ea44`):** Registry read denied when no `barangayCoordinationRegistry` document existed; UI hid the referral CTA. Fixed in app; operator retest **Pass**.

## Sign-off

| Role | Result | Date |
|------|--------|------|
| Operator | **Pass** | 2026-10-24 |
