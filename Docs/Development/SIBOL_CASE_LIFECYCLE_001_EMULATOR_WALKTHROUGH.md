# SIBOL-CASE-LIFECYCLE-001 — Emulator walkthrough (operator)

**Purpose:** Manual functional acceptance on local emulators only (no demonstration phones).  
**Canonical emulators:** `demo-sibol-emulator` on ports 9099 / 8195 / 5001  
**Status:** **Prepared — not executed in engineering session** (automated server integration covers V1–V5 in MVR).

## Prerequisites

1. `./shared/scripts/start-demo-emulators.sh`
2. Seed fictional demo users/data per INT-001 runbook **or** use synthetic documents created during development (no production import).
3. Flutter app with emulators enabled (`EnvConfig.useEmulators`).

## Walkthrough steps

| Step | Actor | Action | Expected observation |
|------|-------|--------|-------------------|
| 1 | Teen | Submit assistance request | Request appears Barangay incoming list |
| 2 | Barangay | Acknowledge request | Status acknowledged |
| 3 | Barangay | Tap **Open Barangay case** on request detail | Snackbar success; navigates to case detail; status **open** |
| 4 | Barangay | Tap **Open Barangay case** again | “Already linked” / view case; same `caseId` |
| 5 | Barangay | **Start case work** | Status **inProgress** |
| 6 | Barangay | Submit MOPH referral from request | Referral visible under submitted referrals |
| 7 | MOPH | Mark received → request information | Status awaiting Barangay |
| 8 | Barangay | **Provide information to hospital** on referral detail | Status information provided |
| 9 | MOPH | Mark coordination complete | Terminal coordination status |
| 10 | Barangay | Mark resolved → close case | Case **closed**; lifecycle timeline shows events |
| 11 | Negative | MOPH user at wrong hospital opens referral | Access denied / not visible |
| 12 | Negative | Edit lifecycle fields on case edit screen for linked case | Firestore rules reject (if attempted) |

## Offline follow-up check

| Step | Action | Expected |
|------|--------|----------|
| 13 | With connectivity off, add follow-up on existing case | Queued locally; not blocked by lifecycle panel messaging |

## Sign-off

Record operator name, date, emulator project id, and screenshots in PA acceptance record. **Do not** mark complete until this table is executed and reviewed.
