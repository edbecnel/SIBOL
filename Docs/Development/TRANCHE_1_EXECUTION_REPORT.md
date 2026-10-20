# Tranche 1 execution report — SIBOL-IMP-001

> **Handover UUID:** `c7e4a926-3f81-4d5b-9a20-6b83e1f74c09`  
> **Date:** 2026-10-20  
> **Agent mode:** AGENT (Tranche 1 only)  
> **Git commit/push:** Not performed (not authorized)

## 1. Summary

Tranche 1 delivered the SIBOL native Flutter application scaffold, EDF software-discipline updates, deny-by-default Firestore rules, three-role authentication routing, provisional fictional case/follow-up/reporting models, seed tooling, Cloud Functions stub for server-authoritative reporting, and documentation for Firebase setup pending coordinator approval.

**Post-delivery:** Live Firebase project `sibol-286d0` and owner E2E verification completed after Tranche 1 delivery (see §6–7, [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md)).

## 2. Files created or modified (high level)

| Area | Paths |
|------|--------|
| Flutter app | `sibol_app/` (lib, test, assets, android, ios) |
| Firebase deploy config | `firebase.json`, `firestore.rules`, `firestore.indexes.json` |
| Shared backend/docs | `shared/functions/`, `shared/scripts/seed_tranche1_demo.mjs`, `shared/docs/*`, `shared/contracts/` |
| Web placeholder | `sibol_web/README.md` |
| EDF / specs | `edf-project-context.yaml`, `Docs/Development/*`, `Docs/Specifications/*`, ADR-0002–0004, `ARCHITECTURE_DECISIONS.md` |
| Repo hygiene | `.gitignore` (Firebase secret patterns) |

SpeakUp Connect: **no changes** (read-only reference).

## 3. EDF documentation updates

- `edf-project-context.yaml`: discipline `software`, `development` activity, `sibol_app/` extension.
- `Docs/Development/README.md`, `FIREBASE_SETUP.md`, this report.
- `Docs/Specifications/CASE_AND_REPORTING_MODEL.md`, `README.md`.
- ADRs: [ADR-0002](../Architecture/ADRs/ADR-0002-Mobile-Stack-and-Firebase.md), [ADR-0003](../Architecture/ADRs/ADR-0003-Authorization-and-Server-Reporting.md), [ADR-0004](../Architecture/ADRs/ADR-0004-Offline-Sync-and-Common-Core-Boundaries.md).

**EDF validation** (2026-10-20):

```bash
/Users/edbecnel/Development/GitHub/Engineering-Documentation-Framework/scripts/adopt-edf.sh validate "/Users/edbecnel/Development/GitHub/SIBOL"
```

Result: completed successfully; overall compliance **35%** (structure **100%**; governance/AI gaps expected for Core profile).

## 4. Architecture decisions recorded

See ADR-0002, ADR-0003, ADR-0004 and index in [ARCHITECTURE_DECISIONS.md](../../ARCHITECTURE_DECISIONS.md).

## 5. Flutter scaffold status

| Item | Status |
|------|--------|
| `sibol_app/` Android + iOS | Done |
| Riverpod + go_router | Done |
| Branding (`assets/images/sibol_logo.png`) | Done |
| Theme + shared widgets (adapted from SpeakUp patterns) | Done |
| Feature folders: auth, cases, reporting (domain), teenager, moph, settings | Done |
| Flutter Web | Not configured (prohibited) |

## 6. Firebase configuration status

| Check | Result |
|-------|--------|
| Pre-existing SIBOL Firebase in repo | **None** |
| SpeakUp project reuse | **Not used** |
| `firebase_options.dart` | **Placeholder** — replace via FlutterFire after coordinator approves project creation |
| `google-services.json` / `GoogleService-Info.plist` | **Not added** (gitignored when present) |

**Action required (coordinator):** Approve creation of a new Firebase project, then follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

### Follow-up — SIBOL-FB-001 (2026-10-20)

After Tranche 1, the coordinator created Firebase project **`sibol-286d0`**, added native config files locally, and ran FlutterFire (default output `lib/firebase_options.dart`). The app still imported Tranche 1 **placeholder** options from `lib/config/firebase_options.dart`, which caused iOS startup failure `[core/duplicate-app]` when native iOS auto-initialized from `GoogleService-Info.plist`.

**Corrective action (authorized):** Consolidate real FlutterFire options into `sibol_app/lib/config/firebase_options.dart`, remove duplicate `lib/firebase_options.dart`, align `sibol_app/firebase.json`. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

Tranche 1 §6 table above remains an accurate record of **delivery-time** state; live Firebase integration was completed in this follow-up, not in the original Tranche 1 commit window.

## 7. Authentication implementation status

- Email/password sign-in via `AuthRepositoryImpl` (no student-ID callable).
- `authStateChangesProvider`, `userProfileProvider`, `AuthController` (sign-in/out).
- Login, splash, unauthorized, settings (logout) screens.
- **Runtime sign-in (current):** Verified on **Android** against `sibol-286d0` with demonstration accounts (see [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md)). Startup/profile loading fix: [SIBOL_FB_003_EXECUTION_REPORT.md](SIBOL_FB_003_EXECUTION_REPORT.md).

## 8. Role authorization and security rules

- Profile model: `users/{uid}` with `role`, `displayName`, `active`, `createdAt`.
- Users may not create profiles or change `role` (`firestore.rules`).
- Teen: no `cases` access; barangay: case CRUD; MOPH: `reports` read only when server-submitted fields set.
- Flutter router redirects by role (UI only; rules are authoritative).

## 9. Fictional case model and seed data

- Domain: `CaseRecord`, `FollowUp`, enums for case/report/follow-up status.
- Validation: ages 13–19, non-empty demo names (`case_validation.dart`).
- Spec: [CASE_AND_REPORTING_MODEL.md](../Specifications/CASE_AND_REPORTING_MODEL.md).
- Seed: `shared/scripts/seed_tranche1_demo.mjs` (5 cases + follow-ups, 3 users) with `--confirm-project=` guard.
- Demo credentials: [shared/docs/DEMO_ACCOUNTS.md](../../shared/docs/DEMO_ACCOUNTS.md).

## 10. Android build results

```bash
cd sibol_app && flutter build apk --debug
```

**Result:** Success — `build/app/outputs/flutter-apk/app-debug.apk` (Gradle warnings on KGP; non-blocking).

## 11. iOS build results

```bash
cd sibol_app && flutter build ios --debug --no-codesign
```

**Result:** Success — `build/ios/iphoneos/Runner.app` (device codesign still required for physical device deploy).

## 12. Automated test results

```bash
cd sibol_app && flutter test
```

**Result (2026-10-20):** **28 tests passed** — `case_validation_test`, `sibol_role_test`, `widget_test`, `login_screen_test` (including FB-004 interaction tests), `app_redirect_test`, `auth_profile_provider_test`, `startup_navigation_test`.

```bash
cd sibol_app && flutter analyze
```

**Result:** No errors; minor `prefer_const` info hints only.

**Not executed:** Firestore rules unit tests (Firebase Rules emulator). Live auth exercised manually on Android (see [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md)).

## 13. Known defects and limitations

- Placeholder Firebase options (Tranche 1) — **addressed in SIBOL-FB-001 follow-up**; runtime still depends on local native config files and optional seed accounts.
- Barangay case list UI is read-only stream (create/edit UI = Tranche 2 Day 4).
- MOPH dashboard is explanatory placeholder (reports list = Tranche 2).
- `submitReport` Cloud Function throws `failed-precondition` until Tranche 2.
- Offline pending UX not implemented (documented in `OFFLINE_SYNC_MODEL.md`).
- EDF governance/AI compliance scores remain low until optional EDF tiers adopted.

## 14. Reusable modules (common-core candidates)

| Module | Location | SIBOL-specific? |
|--------|----------|-----------------|
| App bootstrap | `main_common.dart`, `env_config.dart` | No |
| Theme / colors | `core/theme/` | No (rebrand only) |
| Shared widgets | `shared/widgets/` | No |
| Errors | `core/errors/` | No |
| Auth repository pattern | `features/auth/` | Role enum is SIBOL; swap for generic profile later |
| Case/report domain | `features/cases`, `features/reporting` | **Yes** — stay in vertical app |

## 15. Recommended Tranche 2 scope

1. Coordinator-approved Firebase + FlutterFire + rules deploy + seed run.
2. Barangay case create/edit/detail + follow-up timeline UI.
3. Implement `submitReport` callable per [REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md).
4. MOPH accepted-reports dashboard.
5. Offline pending submit UX (`hasPendingWrites`, `pendingSubmit`).
6. Teen assistance request stub (optional P1).
7. Search/filter on case list.
8. Integration tests with emulators.

## 16. Remaining schedule estimate

| Day (plan) | Status after Tranche 1 |
|------------|-------------------------|
| 1 (EDF + scaffold + Firebase prep) | **Complete** except live Firebase project |
| 2 Auth + navigation | **Code complete**; verify with Firebase |
| 3 Schema + rules + seed | **Complete** (seed awaits project) |
| 4–10 | **Not started** (Tranche 2 authorization required) |

**Adjusted note:** ~13 calendar days remain; Tranche 1 aligns with planned Day 1–3 engineering. Firebase approval delay is the primary schedule risk.

## 17. Tranche 1 completion status

| Milestone | Status | Record |
|-----------|--------|--------|
| Engineering delivery (SIBOL-IMP-001) | Complete | This report |
| Functional acceptance | **Accepted** | [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md) (PA handover `f71b8c62-…`) |
| Verification index | Complete | [TRANCHE_1_VERIFICATION.md](../Verification/TRANCHE_1_VERIFICATION.md) |
| Work-item traceability | Recovered | [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md) |
| Tranche 2 implementation | **Not authorized** | [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md), [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md) |

---

**STOP:** Tranche 2 implementation not authorized. Await explicit PA handover for SIBOL-IMP-002.
