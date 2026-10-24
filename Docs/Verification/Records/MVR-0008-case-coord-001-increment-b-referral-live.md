# MVR-0008 — CASE-COORD-001 Increment B live referral (operator procedure)

> **Status:** **Blocked on operator retest** — defect fix landed in app (handover `e4c7a219-…`); procedure unchanged  
> **Prerequisite:** `createCoordinationReferral` deployed on `sibol-286d0` — **met** 2026-10-24 (`e9b43c72-…`)  
> **Handover:** `d8e3b7a1-…`, deploy retry `e9b43c72-…`, defect `e4c7a219-…`

## Accounts (fictional)

Use [shared/docs/DEMO_ACCOUNTS.md](../../../shared/docs/DEMO_ACCOUNTS.md). Do not record passwords in this MVR.

## Procedure

| Step | Actor | Action | Expected result | Record immediately |
|------|-------|--------|-----------------|-------------------|
| 1 | Teen | Sign in; submit new assistance request (or use un-referred acknowledged request if available) | Request appears in **My Requests** | Request document id |
| 2 | Barangay | Sign in; open **Incoming requests**; select request | Detail shows **Submitted** status | Request id |
| 3 | Barangay | Tap **Acknowledge receipt** (if not already acknowledged) | Status **Acknowledged** | Timestamp |
| 4 | Barangay | Tap **Refer to MOPH coordination** | Referral form opens; privacy notice visible | — |
| 5 | Barangay | Enter fictional summary **without** teen name/contact; tap **Review before submit** | Preview shows category, barangay, summary only — **no** teen description from step 1 | Screenshot or notes |
| 6 | Barangay | **Submit referral to MOPH** | Success dialog with `SIBOL-REF-…` reference | `displayRef`, time |
| 7 | Barangay | Return to same request detail | “Referral already submitted” (no second submit) | — |
| 8 | MOPH | Sign in; open dashboard **Individual case coordination** | New row: reference, barangay, category, phase **Referred** | Thread list entry |
| 9 | MOPH | Open referral detail | Shows reference, category, barangay summary, staff activity; **no** teen name, uid, or original teen text | Pass/Fail |
| 10 | Teen | Optional: check request detail / progress link (if visible) | Generic progress only if Increment D link present | — |

## Negative checks (optional)

- Callable without auth → error (not exercised live by EA).
- Second referral same assistance id → blocked.

## Defect note (2026-10-24)

**MVR-0008 referral action missing:** Root cause was Firestore registry read denied when no `barangayCoordinationRegistry` document existed; UI hid the referral CTA on stream error. Fixed in app (`coordination_registry_referral_probe.dart`, `BarangayMophReferralAction`). Rebuild app from fixed `main` and re-run steps 4–7 below.

## Sign-off

| Role | Result | Date |
|------|--------|------|
| Operator | Pending (retest after app fix) | |
