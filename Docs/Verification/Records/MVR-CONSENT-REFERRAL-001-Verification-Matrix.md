# MVR-CONSENT-REFERRAL-001 — Verification matrix

**Work item:** SIBOL-CONSENT-REFERRAL-001  
**Verification handover UUID:** `b8e2c64d-7a91-4c53-9f06-d325a80e71bc`  
**Auth remediation handover UUID:** `d9c4a721-5e83-4f16-a6b2-0e7d935c481a`  
**Starting HEAD:** `f12c808e010505660d2d6a743b1fbf4f49b29294`  
**Emulator isolation:** `demo-sibol-coord-fn` (Functions integration, ports 8226/8227 via `firebase.emulator-functions-test.json`); `demo-sibol-rules` (rules unit tests via `firebase.emulator-isolated.json`). Production project `sibol-286d0` not accessed.

| ID | Criterion | Method | Result | Evidence |
|----|-----------|--------|--------|----------|
| V1 | Legacy free-text referral rejected | `consent_referral.test.mjs` | **Pass** | Included in consent suite |
| V2 | Minimum structured referral | Functions integration | **Pass** | Included in consent suite |
| V3 | Authorization approve + authorized referral (gate on) | Functions integration | **Pass** | `SIBOL_DISCLOSURE_LEGAL_GATE=true` in runner |
| V4 | Decline + minimum referral | Functions integration | **Pass** | Included in consent suite |
| V5 | Legal gate off blocks authorized referral | Functions integration | **Pass** | Gate toggled in-test |
| V6 | Withdrawal blocks authorized use | Functions integration | **Pass** | Included in consent suite |
| V7 | Case lifecycle + structured response | `case_lifecycle_flow.test.mjs` | **Pass** | Included in consent suite |
| V8 | Authz regression structured payload | `createCoordinationReferral.authz.test.mjs` + extended consent cases | **Pass** | Authz **8/8**; consent suite **19/19** (teen cross-approve, expired/superseded auth, legacy `responseSummary` rejection) |
| V9 | Firestore rules disclosure paths | `disclosure_authorization.rules.test.mjs` + full rules npm suite | **Pass (disclosure)** | Disclosure file **8/8**; full suite **138/139** — one pre-existing failure in `reports.rules.test.mjs` (unrelated) |
| V10 | Flutter emulator E2E consent + lifecycle walkthrough | `emulator_auth_gates_device_test.dart` + `consent_referral_emulator_device_test.dart` | **PARTIAL** | **Gates A–D pass** on `emulator-5554` (2026-11-01): demo project + three role dashboards. Full consent/referral device walkthrough **not pass** (Barangay incoming list missing seeded teen submission in test session). |
| V11 | Legal gate off + UI authorized path | Manual / device with gate define | **NOT EXECUTED** | Functions gate-off covered in V5; Flutter UI path requires passing V10 consent device session |

## Commands executed (2026-11-01)

```bash
cd shared/functions && node scripts/run-consent-referral-integration-tests.mjs
# 19 pass (consent + createCoordinationReferral + case_lifecycle_flow)

cd shared/functions && firebase emulators:exec --config ../../firebase.emulator-functions-test.json \
  --only firestore,auth --project demo-sibol-coord-fn \
  "node --test test/createCoordinationReferral.authz.test.mjs"
# 8 pass

cd shared/firestore-rules-test && firebase emulators:exec --config ../../firebase.emulator-isolated.json \
  --only firestore --project demo-sibol-rules \
  "node --test test/disclosure_authorization.rules.test.mjs"
# 8 pass

cd shared/firestore-rules-test && npm test
# 138/139 pass; 1 pre-existing failure in `reports.rules.test.mjs` (MOPH production list) unrelated to disclosure paths

cd sibol_app && flutter test test/offline_sync_service_test.dart
# 8 pass (includes structured referral queue + sync stubs)

cd sibol_app && flutter test test/emulator_config_test.dart
# 2 pass (demo project isolation)

cd sibol_app && source ../.env.emulator.local && flutter test integration_test/emulator_auth_gates_device_test.dart -d emulator-5554 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_DEVICE_TEST_TEEN_PASSWORD="$SIBOL_EMULATOR_PASSWORD_TEEN" \
  --dart-define=SIBOL_DEVICE_TEST_BARANGAY_PASSWORD="$SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF" \
  --dart-define=SIBOL_DEVICE_TEST_MOPH_PASSWORD="$SIBOL_EMULATOR_PASSWORD_MOPH_STAFF"
# 1 pass (Gates A–D)
```

## Offline regression (handover §9)

| Check | Result |
|-------|--------|
| Assistance / ack queue behavior preserved | **Pass** (existing offline tests) |
| Structured referral intent queued without profile fields | **Pass** (`queued referral payload excludes identifying profile fields`) |
| Sync uses `createCoordinationReferral` structured callable only | **Pass** (mock assertion) |
| Expired/withdrawn auth on sync → retryable failure | **Pass** (`failed-precondition` → `failedRetryable`) |
| Duplicate sync idempotency | **Not re-tested** (server duplicate rejection covered in Functions tests) |

## Engineering failure records (auth remediation 2026-11-01)

| Failure ID | Operation | Root cause | Correction | Verification | Disposition |
|------------|-----------|------------|------------|--------------|-------------|
| FAIL-AUTH-001 | Teen sign-in → profile read | Flutter/Android Firebase app used production namespace `sibol-286d0` (native `google-services` + mixed `FirebaseOptions`) while Firestore emulator serves `demo-sibol-emulator` | Synthetic `EmulatorFirebaseOptions`; debug `src/debug/google-services.json`; delete/re-init wrong default app in `initializeSibolFirebase()`; `firebase_core_auto_init_enabled=false` | Gates A–D device test; Firestore log quiet after ~07:45 UTC (no new `286d0` warnings during pass) | **Resolved** |
| FAIL-AUTH-002 | Integration bootstrap | Duplicate `[core/duplicate-app]` / `[core/no-app]` from conflicting init | Single `EmulatorIntegrationBootstrap.launchAppOnce`; `prepareEmulatorIntegrationSession` alias | Gates A–D | **Resolved** |
| FAIL-AUTH-003 | Gate A project guard | Native pre-init before Dart | Same as FAIL-AUTH-001 | `values.xml` `project_id=demo-sibol-emulator` on debug build | **Resolved** |
| FAIL-AUTH-004 | Gate C barangay sign-in | Auth export backup password ≠ live emulator seed (`INVALID_PASSWORD` on Auth emulator for `barangay.demo@sibol.local`) | Device scripts use `.env.emulator.local` (`SIBOL_EMULATOR_PASSWORD_*`) with export fallback | Auth emulator HTTP sign-in + Gates A–D | **Resolved** |
| FAIL-CONSENT-001 | Gate E `consent_referral_emulator_device_test.dart` | Barangay **Incoming requests** missing teen submission token after UI submit | **Fixed (code):** incoming list shows description preview; device test reordered for COMM-ORD-1 | Inbox card + test harness update 2026-11-01 | **Re-verify on device** |

## Role-home blocker (CASE-LIFECYCLE-001 V10 dependency)

| Item | Status |
|------|--------|
| Confirmed root cause | Firebase **project namespace mismatch** on client (not missing seed credentials) |
| Remediation applied | Emulator-only Firebase options + debug `google-services` + init guard/delete |
| Verified on device (2026-11-01) | **Yes** — `integration_test/emulator_auth_gates_device_test.dart` **pass** (teen / Barangay / MOPH dashboards) |

## Minimum-information referral safeguard (§8)

| Check | Result |
|-------|--------|
| Minimum mode payload: purpose + need codes only (client) | **Pass** (Functions + offline payload test) |
| Server rejects legacy `barangayReferralSummary` on create | **Pass** (V1) |
| No teen profile attached in minimum mode | **Pass** (integration creates thread without `authorizedDisclosure/profile`) |
| Legal gate required for identifying authorized mode | **Pass** (V5) |
| Production default gate off | **Confirmed** (no production deploy; runner sets gate only in isolated tests) |

## Legal dependencies (unchanged)

- PO notice wording and category catalog legal review before production activation.
- Normative PO framework PDF/DOCX commit (D8) pending revision source confirmation.
- Statutory/emergency bypass remains disabled.

## Tests not executed

- Full Flutter device consent/referral walkthrough (`consent_referral_emulator_device_test.dart` primary scenario) — **attempted, failed** (FAIL-CONSENT-001).
- Flutter UI legal-gate positive path with `--dart-define=SIBOL_DISCLOSURE_LEGAL_GATE=true`.
- Manual operator CASE-LIFECYCLE walkthrough table (steps 1–13) on device.
- Consent offline device test (`SIBOL_RUN_CONSENT_OFFLINE_DEVICE_TEST=1`).

**Classification:** **IMPLEMENTED — ACCEPTANCE PENDING** (V10 partial: auth gates pass; consent device E2E and V11 remain open).
