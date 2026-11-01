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
flutter test integration_test/emulator_auth_gates_device_test.dart -d emulator-5554 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_DEVICE_TEST_TEEN_PASSWORD="$SIBOL_EMULATOR_PASSWORD_TEEN" \
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF" \
  --dart-define=SIBOL_DEVICE_TEST_MOPH_PASSWORD="$SIBOL_EMULATOR_PASSWORD_MOPH_STAFF"

# Or use shared/scripts/run-consent-referral-device-test.sh (sources .env.emulator.local when present)
```

## Walkthrough steps

| Step | Actor | Action | Expected observation |
|------|-------|--------|-------------------|
| 1 | Teen | Submit assistance request | Request appears Barangay incoming list |
| 2 | Barangay | Acknowledge request | Status acknowledged |
| 3 | Barangay | Request disclosure (if identifying referral needed) | Authorization panel visible |
| 4 | Barangay | Submit MOPH referral from request | Referral visible under submitted referrals |
| 5 | MOPH | Mark received | Coordination status received |
| 6 | Barangay | Tap **Open Barangay case** on request detail | Snackbar success; navigates to case detail; status **open** |
| 7 | Barangay | Tap **Open Barangay case** again | “Already linked” / view case; same `caseId` |
| 8 | Barangay | **Start case work** | Status **inProgress**; teen receives generic case update |
| 9 | MOPH | Request information → Barangay responds | Status information provided |
| 10 | MOPH | Mark coordination complete | Terminal coordination status |
| 11 | Barangay | Confirm outcome for teenager | Teen timeline shows neutral outcome template |
| 12 | Barangay | Mark resolved → close case | Case **closed**; lifecycle timeline shows events |
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
| Auth Gates A–D (`emulator_auth_gates_device_test.dart`) | `emulator-5554`, emulators + `.env.emulator.local` | **PASS (2026-11-01)** | Teen / Barangay / MOPH dashboards; demo Firestore namespace |
| Integration test harness `case_lifecycle_emulator_device_test.dart` | Same stack | **NOT RE-RUN** | Role-home blocker cleared by auth remediation; lifecycle UI walkthrough still open |
| Consent device test `consent_referral_emulator_device_test.dart` | Same stack | **FAIL (2026-11-01)** | Barangay incoming list missing teen submission after UI submit (FAIL-CONSENT-001) |
| Server-side lifecycle path | `run-case-lifecycle-integration-tests.mjs` | **PASS** | 7/7 (see MVR V1–V5) |

**Blocker for UI closeout:** Consent/referral device E2E (Gate E) and manual operator steps 1–13 remain open. Role-home authentication is **verified** on device.

## Sign-off

Record operator name, date, emulator project id, and screenshots in PA acceptance record. **Do not** mark COMPLETE—VERIFIED until this table is executed and reviewed on a device session that reaches role home screens.
