# SIBOL-CASE-LIFECYCLE-001 — Emulator walkthrough (operator)

**Purpose:** Manual functional acceptance on local emulators only (no demonstration phones).  
**Canonical emulators:** `demo-sibol-emulator` on ports 9099 / 8195 / 5001  
**Handover UUID (acceptance tranche):** `e5b74a19-3c86-4f20-a91d-6b728c05e493`

## Prerequisites

1. `./shared/scripts/start-demo-emulators.sh`
2. Seed fictional demo users/data: `./shared/scripts/seed-emulator-demo.sh` (requires `.env.emulator.local` and running emulators).
3. Flutter app with emulators enabled (`EnvConfig.useEmulators` / development debug build).
4. Isolated Android emulator (`Medium_Phone_API_37.0` or equivalent) — **not** a student demonstration phone.

## Automated UI harness (optional)

```bash
cd sibol_app
source ../.env.emulator.local
flutter test integration_test/case_lifecycle_emulator_device_test.dart -d emulator-5554 \
  --dart-define=SIBOL_DEVICE_TEST_TEEN_PASSWORD="$SIBOL_EMULATOR_PASSWORD_TEEN" \
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF" \
  --dart-define=SIBOL_DEVICE_TEST_MOPH_PASSWORD="$SIBOL_EMULATOR_PASSWORD_MOPH_STAFF"
```

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

## Acceptance execution log (2026-11-01)

| Item | Environment | Result | Evidence |
|------|-------------|--------|----------|
| Operator manual walkthrough (steps 1–13) | Canonical emulators + seeded demo | **NOT EXECUTED** | — |
| Integration test harness `case_lifecycle_emulator_device_test.dart` | `emulator-5554`, emulators + seed | **FAIL** | Auth sign-in completes; app does not reach role home (`Teenager dashboard` / `Barangay dashboard` not observed within test timeouts). Same failure mode as existing `barangay_incoming_request_cards_device_test.dart` on this workstation. Likely Firestore profile load / redirect to **Account not provisioned** after Auth. |
| Server-side lifecycle path | `run-case-lifecycle-integration-tests.mjs` | **PASS** | 7/7 (see MVR V1–V5) |

**Blocker for UI closeout:** Device/integration Flutter harness cannot complete sign-in → profile → role home on the isolated Android emulator in this environment. Manual operator walkthrough on the same stack is recommended once device Firestore connectivity is confirmed (Emulator UI shows `users/{uid}` reads after app sign-in).

## Sign-off

Record operator name, date, emulator project id, and screenshots in PA acceptance record. **Do not** mark COMPLETE—VERIFIED until this table is executed and reviewed on a device session that reaches role home screens.
