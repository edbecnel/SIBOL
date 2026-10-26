# SIBOL-CASE-IDENTITY-001 — Execution report

**Handover UUID:** `e1c5f782-3a94-4b61-9f27-6d0e8b413ac5`  
**Reference baseline:** `8221fcf`  
**Starting HEAD:** `8221fcf`  
**Ending HEAD:** `d1b9599` (verification milestone pending below)  
**Firebase:** `sibol-286d0` (no production deploy)

## Summary

Implemented registered and unregistered teen identity for Barangay cases: date-of-birth–based age, contact validation, drafts vs active cases, verified registered-teen linkage via Cloud Functions, teen self-service profile fields, updated Firestore rules and contracts, and UI updates for list/detail/edit/follow-up context. Legacy QA cases (including **Maria Offline Test**) remain readable without fabricated DOB or contact data.

## Registered vs unregistered behavior

| Aspect | Registered | Unregistered |
|--------|------------|--------------|
| `subjectKind` | `registered` | `unregistered` |
| `teenUid` | Required for active case (verified online) | Must be absent |
| Identity source | Callable snapshot + teen profile | Manual entry on case |
| Account email | `linkedAccountEmail` from Auth after `regResolveRegisteredTeenForCase` | N/A |
| Offline registered link | Blocked until online verification | Draft/active manual entry allowed |

## Contact validation

- Active cases require at least one valid **email or phone** (shared `CaseContactValidation`).
- Teen profile updates require the same rule (Firestore `teenSelfProfileUpdate`).

## DOB and age

- `dateOfBirth` stored as `YYYY-MM-DD`; `effectiveAge` computed in app (`CaseDateOfBirth`).
- Historical age via `CaseRecord.ageOn(eventDate)`.
- Legacy age-only documents use `caseCompleteness: legacyIncomplete` (inferred when no extension fields).

## Teen profile editing

- **Settings → Edit my profile** (`/settings/profile`): name, DOB, barangay, contact fields, parent/guardian.
- Sign-in email change uses `verifyBeforeUpdateEmail` (verification required).

## Security

- Registered linkage: `regResolveRegisteredTeenForCase` + rules `teenAccountLinkedToOrg`.
- `teenUid` and `subjectKind` immutable after set on case updates.
- Teens still cannot read `cases/*`.

## Offline

- Cases/follow-ups continue to use Firestore local-first writes (no custom queue).
- Unregistered drafts and legacy edits remain offline-capable.
- Registered teen verification requires connectivity (by design).

## Automated verification

| Suite | Result |
|-------|--------|
| `cd sibol_app && flutter test` | **197/197 PASS** |
| `flutter analyze` | No errors (infos/warnings only) |
| `shared/functions npm run build` | **PASS** |
| Firestore `cases.rules.test.mjs` | Not re-run in this session (rules updated; run in emulator CI before deploy) |

## Android manual acceptance

**Not executed in this session** (no live emulator session preserved). Recommended: session-preserving ADB flow per PA protocol; PO `LOGIN COMPLETE` for Barangay demo; verify Maria Offline Test card/detail, draft save offline, reconnect sync.

## QA preservation

- **Maria Offline Test** (`fhcQrLxE0IhwPFzCPinH`): no seeded DOB/contact; UI shows legacy incomplete label; notes/follow-ups unchanged.
- No association with `maria.qa.staff@sibol.local`.

## Key files

- Domain: `sibol_app/lib/features/cases/domain/*` (DOB, contact, subject kind, completeness, validation).
- UI: `case_edit_screen.dart`, `case_detail_screen.dart`, `case_list_tile_subtitle.dart`, `teen_profile_edit_screen.dart`.
- Functions: `shared/functions/src/cases/*`, exports in `index.ts`.
- Rules/contract: `firestore.rules`, `shared/contracts/case_record.schema.json`.

## Final verification (2026-10-26, handover `8d3c7f21-…`)

### Security (Firestore rules emulator)

| Suite | Result |
|-------|--------|
| `shared/firestore-rules-test` full suite | **126/126 PASS** (includes 5 new case-identity cases) |

Verified themes: legacy case read, extended draft/active contact rules, registered `teenUid` org linkage denial, unregistered `teenUid` denial, teen/MOPH/cross-org denials (existing suites unchanged).

### Follow-up staff identity

New follow-ups store `createdByDisplayName` and `createdByStaffEmail` snapshots at write time; UI uses `FollowUpStaffIdentity` (name + email, UID fallback for legacy rows). `createdByUid` unchanged for audit.

### Registered teen profile → case contact sync

Callable `regSyncRegisteredTeenCasesFromProfile`:

- **Teen:** after profile save, syncs all registered cases for that teen in their org (contact fields + `teenProfileSyncedAt`).
- **Barangay:** **Refresh contact from teen profile** on registered case detail (requires online).

Does not alter follow-up history or `teenUid` / `linkedAccountEmail`. Offline case reads show cached-contact notice when applicable.

### Flutter / Functions

| Check | Result |
|-------|--------|
| `flutter test` | **199/199 PASS** |
| `flutter analyze` | No errors |
| `npm run build` (functions) | PASS |

### Android acceptance

| Item | Result |
|------|--------|
| Pre-install session | Barangay dashboard showed **Maria Offline Test** on case list (legacy build strings) |
| `flutter install -d emulator-5554` | Installed updated APK; **session cleared** (login required) |
| Post-install flows | **Blocked** pending PO `LOGIN COMPLETE` at Sign in (`barangay.demo@sibol.local`) |

Do not claim full table in §6 Android checklist as PASS until PO re-authenticates and Cursor completes ADB walkthrough on the new build.

### Android auth/connectivity recovery (2026-10-26, handover `2c71f9a4-…`)

| Check | Result |
|-------|--------|
| Starting HEAD | `6dbd558` |
| Auth emulator (`127.0.0.1:9099`) | Running; `barangay.demo@sibol.local` present (uid `6dCjs4T7E4Lk3bzyhHhHNKMXZF5h`) |
| Firestore emulator (`127.0.0.1:8195`) | Running; profile doc for barangay demo intact |
| Emulator → host TCP (`10.0.2.2:8195`, `10.0.2.2:9099`) | **Reachable** (`nc` from `emulator-5554`) |
| Prior `ENETUNREACH` in logs | **Transient** Android route to host (not Auth credential loss); distinct from PO “Invalid email or password” unless correlated on same attempt |
| Client Firebase target | Debug session: `USE_FIREBASE_EMULATORS=true`, `SIBOL_COORD_REGISTRY_RULES_V2=true` → Auth/Firestore/Functions on `10.0.2.2` |
| Login error persistence | **Fixed** — `authControllerProvider` error cleared on login screen open and when leaving via back; widget test added |
| `flutter test test/login_screen_test.dart` | **6/6 PASS** (includes stale-error clear) |
| Android CASE-IDENTITY walkthrough | **Pending** PO `LOGIN COMPLETE` after manual sign-in |

### Android acceptance (2026-10-26, handover `2c71f9a4-…` post-`LOGIN COMPLETE`)

**Environment:** `emulator-5554`, local Firebase emulators (`USE_FIREBASE_EMULATORS=true`), Barangay session `barangay.demo@sibol.local`. Session-preserving ADB + screencap evidence (Flutter semantics not exposed to UI Automator text dumps).

| Check | Result | Evidence |
|-------|--------|----------|
| Barangay dashboard after PO login | **PASS** | Dashboard loaded; case list visible |
| **Maria Offline Test** list identity | **PASS** | Manual record · Age 16; Active case; `Legacy record — complete contact and DOB when ready`; aggregate report line |
| **Maria** case detail | **PASS** | Case ID `fhcQrLxE0IhwPFzCPinH`; legacy incomplete copy; QA-OFFLINE notes preserved; Barangay 3, Balingasag |
| **Follow-ups** (legacy row) | **PASS** | `QA-OFFLINE-FOLLOWUP-001` visible; staff line uses **UID fallback** (`Recorded by staff (6dCjs4T7E4Lk3bzyhHhHNKMXZF5h)`) — no snapshots on seeded row (expected) |
| **Follow-ups** (new row staff name/email) | **Not exercised** | Would require new follow-up write; deferred to avoid extra QA mutations |
| **Maria edit offline** (O5 path) | **PASS** | Airplane mode on: Edit case form loads from cache — Full name, legacy age 16, QA notes, “No SIBOL account” |
| **Draft create offline** | **BLOCKED (ADB)** | `Save draft` requires Full name via Flutter `TextField`; `adb shell input text` / paste did not bind to the correct field (text landed in Notes). No new `cases` doc created (`DraftAccept001` query = 0). Covered by `case_edit_screen_offline_test` + prior O5 Maria notes sync |
| **Reconnect / session** | **PASS** | Airplane toggled off; `am start` resumed app on dashboard **without** re-login; Maria Firestore doc unchanged |
| Registered-teen picker / profile sync button | **Not exercised** | Requires registered case or teen account checkpoint |

**QA preservation:** `cases/fhcQrLxE0IhwPFzCPinH` notes and `demoName` unchanged after walkthrough.

### Case card contact display (2026-10-26, handover `8a4e6b92-…`)

**Defect:** Dashboard case cards hid contact email even when Case details showed it (e.g. Maria Offline Test after PO added `contactEmail`).

**Expected:** On list cards only — `Email: …` if nonblank email; else `Phone: …`; else `Contact: Not provided` (trimmed; email wins when both). Drafts keep “Contact details required before activation”. Detail screen unchanged.

**Implementation:** `CaseIdentityPresentation.listCardContactLine` replaces opaque `listContactHint`; `CaseListTileSubtitle` always includes the contact line.

**Verification:** `flutter test test/case_identity_presentation_test.dart` — **8/8 PASS**; `flutter analyze` on touched files — clean. **Android:** no hot-reload session attached to running debug app (`flutter attach` did not connect); device check deferred to next `flutter run` / PO refresh — logic covered by widget test using `maria.offline@test.org`.

### Teen registration identity completion (2026-10-26, handover `b7e2a03d-…`)

**Gap:** Teen self-registration UI collected only sign-in email and password; profile identity/contact fields existed on **Edit my profile** and Barangay cases but not at registration.

**Correction:** Single registration form collects full name, DOB (computed age shown), PSGC Barangay, contact email/phone (email-or-phone rule), then sign-in credentials. Identity is validated **before** `registerWithEmail`. `regRegisterTeenAccount` persists `displayName`, `dateOfBirth`, `contactEmail`/`contactPhone` on first profile create (`teenIdentityFields.ts`). Contact email prefills from sign-in email until manually edited.

**Verification:**

| Suite | Result |
|-------|--------|
| `test/teen_registration_validation_test.dart` | **11/11 PASS** |
| `test/teen_registration_screen_test.dart` | **1/1 PASS** |
| `shared/functions` `test/teen.registration.test.mjs` | **12/12 PASS** |
| `org_identity.test.mjs` (teen re-register seed) | updated identity payload |

**Android:** Not navigated to Teen registration on device to preserve active Barangay session; widget test confirms field labels.

## Limitations

- Legacy follow-ups without staff snapshots still show UID fallback.
- Profile sync requires online callable (teen save retries sync silently on failure).
- `teenProfileSyncedAt` is server-written; client displays when present after sync.

## Commits

- `a7f431c` — SIBOL-CASE-IDENTITY-001 implementation (pushed to `origin/main`)
- `d1b9599` — execution report HEAD reference
- `1e6fa99` — verification: staff follow-up identity, profile sync, rules tests (pushed)
- `1dd47ff` — login stale-error clear + Android auth recovery evidence
- `9afb274` — EDF recovery SHA; Android CASE-IDENTITY acceptance evidence (this section)
