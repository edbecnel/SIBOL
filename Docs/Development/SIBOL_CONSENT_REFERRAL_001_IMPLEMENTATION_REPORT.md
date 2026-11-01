# SIBOL-CONSENT-REFERRAL-001 — Implementation Report

**Implementation handover UUID:** `d4a8c261-7e35-4d92-9b60-f1c73a80e524`  
**Verification handover UUID:** `b8e2c64d-7a91-4c53-9f06-d325a80e71bc`  
**Auth remediation handover UUID:** `d9c4a721-5e83-4f16-a6b2-0e7d935c481a`  
**Starting HEAD (implementation):** `ea3fdd71581df49138e9cacb4db0f36b96be9c64`  
**Starting HEAD (verification):** `f12c808e010505660d2d6a743b1fbf4f49b29294`  
**Starting HEAD (auth remediation):** `de1e079e0224c1cead53f528eef119baf9df8c02`  
**Status:** **IMPLEMENTED — ACCEPTANCE PENDING**

## Summary

Integrated disclosure authorization, structured MOPH coordination payloads (PA corrections C1–C3), Flutter in-app flows (D7), and emulator-focused verification. Production Firebase and student demonstration phones were not touched.

## PA corrections

| ID | Implementation |
|----|----------------|
| C1 | Server rejects `barangayReferralSummary` / legacy narrative on new referrals |
| C2 | Minimum mode: purpose + need codes only; server-generated MOPH summary text |
| C3 | Authorized mode: structured templates + `authorizedDisclosure/profile`; no operator free text |

## Legal gate

Consent-dependent identifying disclosure requires `SIBOL_DISCLOSURE_LEGAL_GATE=true`. Default build/runtime is fail-closed. Flutter surfaces this via `DisclosureLegalPolicy.identifyingDisclosureActivated` (`--dart-define=SIBOL_DISCLOSURE_LEGAL_GATE=true` for legal-activated emulator demos only).

## Verification executed (post-implementation cycle)

| Suite | Result |
|-------|--------|
| `shared/functions/scripts/run-consent-referral-integration-tests.mjs` | **19/19 pass** |
| `test/createCoordinationReferral.authz.test.mjs` (isolated emulator) | **8/8 pass** |
| `shared/firestore-rules-test/test/disclosure_authorization.rules.test.mjs` | **8/8 pass** |
| Full `shared/firestore-rules-test` npm test | **138/139 pass** (pre-existing `reports.rules.test.mjs` failure unrelated to disclosure) |
| `sibol_app/test/offline_sync_service_test.dart` | **8/8 pass** (added structured referral queue cases) |

Extended consent integration coverage: cross-teen decision denial, expired/superseded authorization on authorized referral, legacy `responseSummary` rejection on MOPH information response.

## Remediation (verification cycle)

- Firestore rules tests for `disclosureAuthorizations` and `authorizedDisclosure/profile` (V9).
- Integration test sign-in helper: role-home polling and correct MOPH home title (`MOPH dashboard`).
- Offline unit tests for referral queue payload shape and sync callable shape.

## Remediation (Firebase emulator auth — 2026-11-01)

- **Root cause:** Android debug builds initialized Firebase with production `sibol-286d0` from `google-services.json` while Dart targeted mixed options → Firestore client requests hit wrong project namespace → **Account not ready** despite seeded profiles.
- **Fix:** `EmulatorFirebaseOptions` (synthetic app id + demo `projectId`); committed debug-only `android/app/src/debug/google-services.json`; `initializeSibolFirebase()` deletes wrong default app when `USE_FIREBASE_EMULATORS=true`; manifest disables Firebase auto-init; Settings sign-out uses `go(welcome)` when stack empty.
- **Device verification:** `integration_test/emulator_auth_gates_device_test.dart` **pass** on `emulator-5554` with `.env.emulator.local` passwords (auth export backup alone is insufficient for Barangay — see MVR FAIL-AUTH-004).
- **Gate E:** `consent_referral_emulator_device_test.dart` primary scenario **not pass** (Barangay inbox missing submitted request token — MVR FAIL-CONSENT-001).

## Acceptance pending

- Full consent/referral Flutter device walkthrough (handover §6 Gate E) — **attempted, not pass**.
- Flutter UI legal-gate walkthrough — **not executed** (Functions gate-off covered).
- Legal review of notice wording and category catalog before production activation.
- PO framework PDF committed as normative reference after revision verification (D8).

## Traceability

- Extends SIBOL-CASE-LIFECYCLE-001, SIBOL-CASE-COORD-001
- Plan: [SIBOL_CONSENT_REFERRAL_001_PLAN.md](SIBOL_CONSENT_REFERRAL_001_PLAN.md)
- MVR: [MVR-CONSENT-REFERRAL-001-Verification-Matrix.md](../Verification/Records/MVR-CONSENT-REFERRAL-001-Verification-Matrix.md)
