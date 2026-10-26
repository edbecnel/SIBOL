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

## Limitations

- Legacy follow-ups without staff snapshots still show UID fallback.
- Profile sync requires online callable (teen save retries sync silently on failure).
- `teenProfileSyncedAt` is server-written; client displays when present after sync.

## Commits

- `a7f431c` — SIBOL-CASE-IDENTITY-001 implementation (pushed to `origin/main`)
- `d1b9599` — execution report HEAD reference
- `1e6fa99` — verification: staff follow-up identity, profile sync, rules tests (pushed)
