# MVR-CONSENT-REFERRAL-001 — Verification matrix

**Work item:** SIBOL-CONSENT-REFERRAL-001  
**Verification handover UUID:** `b8e2c64d-7a91-4c53-9f06-d325a80e71bc`  
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
| V10 | Flutter emulator E2E consent + lifecycle walkthrough | `case_lifecycle_emulator_device_test.dart` / manual | **NOT EXECUTED** | `adb` unavailable on verification workstation; integration harness remediated (`_signIn` role-home wait, MOPH dashboard title) but device run not performed this session |
| V11 | Legal gate off + UI authorized path | Manual / device with gate define | **NOT EXECUTED** | Functions gate-off covered in V5; Flutter UI path requires V10 device session |

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
```

## Offline regression (handover §9)

| Check | Result |
|-------|--------|
| Assistance / ack queue behavior preserved | **Pass** (existing offline tests) |
| Structured referral intent queued without profile fields | **Pass** (`queued referral payload excludes identifying profile fields`) |
| Sync uses `createCoordinationReferral` structured callable only | **Pass** (mock assertion) |
| Expired/withdrawn auth on sync → retryable failure | **Pass** (`failed-precondition` → `failedRetryable`) |
| Duplicate sync idempotency | **Not re-tested** (server duplicate rejection covered in Functions tests) |

## Role-home blocker (CASE-LIFECYCLE-001 V10 dependency)

| Item | Status |
|------|--------|
| Root cause hypothesis | Auth succeeds; Firestore `users/{uid}` profile or org membership missing → **Account not provisioned**, or streams prevent `pumpAndSettle` from completing |
| Remediation applied | Integration `_signIn` polls up to 45s for role dashboards; fails fast with seed instruction |
| Verified on device this session | **No** — environment lacks Android tooling |

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

- Flutter device/integration consent walkthrough (teen / Barangay / MOPH steps in handover §6).
- Flutter UI legal-gate positive path with `--dart-define=SIBOL_DISCLOSURE_LEGAL_GATE=true`.
- Manual operator CASE-LIFECYCLE walkthrough table (steps 1–13) on device.

**Classification:** **IMPLEMENTED — ACCEPTANCE PENDING** (V10/V11 and manual walkthrough remain open).
