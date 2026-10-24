# SIBOL-STARTUP-001 — Execution Report

**Handover:** SIBOL-STARTUP-001-AGENT-001  
**Base commit:** `35f52ef`  
**Status:** Complete (automated verification); manual Android attestation delegated to PA  

## 1. Root cause — incorrect startup navigation

1. **`resolveAppRedirect`** treated **authenticated users with no Firestore `users/{uid}` profile** as incomplete teen onboarding and sent them to `Routes.teenRegister`. Stale or staff Firebase sessions without a matching profile therefore opened Teen registration on cold start instead of a neutral entry screen.
2. **Teen registration UI** only rendered step 1 (email/password) when `authUser == null`. After **Continue** with a persisted auth session, `_step` became `1` while `authUser != null`, producing an **empty body** until step 2.
3. **`accountMembershipsProvider`** subscribed to `organizationMemberships` for **every** signed-in user as soon as auth was known, **before** profile role was loaded. Teens and profile-less sessions triggered list queries; rules evaluating `resource.data.orgId` on malformed or non-matching docs surfaced **`PERMISSION_DENIED` / orgId undefined** during startup.

## 2. Startup and authentication changes

| Area | Change |
|------|--------|
| Welcome | New `WelcomeScreen`: Sign in, Register as Teen; no auto-registration |
| Signed-out routing | Splash and protected routes → `Routes.welcome` (not login) |
| Missing profile | Authenticated, `profile == null` → `AccountNotProvisionedScreen` (sign out / back to Welcome); teen register remains available for self-registration |
| Role homes | `homeForProfile()`: central admin → Settings; others unchanged |
| Login | Back to Welcome; removed inline teen self-register link |
| Teen registration | Back to Welcome; Continue skips empty auth step when already signed in; signed-in-without-profile messaging |
| Membership stream | Defer until `userProfile` loaded; **no query for `SibolRole.teen`** |

Offline behavior unchanged: Firebase Auth persistence + Firestore offline cache; explicit sign-out clears session (existing contracts).

## 3. Firestore membership error disposition

**Cause (client):** Premature membership list for users who should not use org membership resolution (teens) or before profile load.  
**Cause (rules):** List evaluation on documents missing `orgId` threw undefined-property errors.  
**Fix:** Client guard (above). Rules read rule now requires `resource.data.keys().hasAll(['accountUid', 'orgId'])` before `isValidOrgId` — **deny malformed docs; not a weakening**.  
**Regression:** Firestore rules tests **98/98 PASS**.

## 4. Files changed

- `sibol_app/lib/core/constants/route_constants.dart`
- `sibol_app/lib/core/router/app_redirect.dart`
- `sibol_app/lib/core/router/app_router.dart`
- `sibol_app/lib/features/auth/presentation/screens/welcome_screen.dart` (new)
- `sibol_app/lib/features/auth/presentation/screens/account_not_provisioned_screen.dart` (new)
- `sibol_app/lib/features/auth/presentation/screens/login_screen.dart`
- `sibol_app/lib/features/org/presentation/providers/org_context_providers.dart`
- `sibol_app/lib/features/teen_registration/presentation/screens/teen_registration_screen.dart`
- `sibol_app/test/app_redirect_test.dart`
- `sibol_app/test/startup_navigation_test.dart`
- `firestore.rules`
- `CHANGELOG.md`
- `Docs/Verification/TRANCHE_1_VERIFICATION.md`

## 5. Automated test results

| Suite | Result |
|-------|--------|
| Flutter `flutter test` | **91/91 PASS** |
| Cloud Functions `npm test` (shared/functions) | **PASS** (60 scenarios) |
| Firestore rules `npm test` (shared/firestore-rules-test) | **98/98 PASS** |

Widget coverage includes: signed-out → Welcome, Sign in navigation, Register as Teen navigation, back to Welcome, redirect matrix (welcome, account not provisioned, central admin → settings).

**Not automated in this handover:** per-role session restoration on device, offline reopen, sign-out-then-offline-sign-in (existing offline queue tests remain in `pending_operation_test.dart`).

## 6. Manual Android verification

**Device:** `emulator-5554` detected via `flutter devices`.  
**Agent run:** Full interactive `flutter run` journey not recorded in this report; PA should execute §7 of the handover:

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL/sibol_app
flutter run -d emulator-5554 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Expected signed-out: Welcome → Sign in / Register as Teen, back navigation, no blank screens.

## 7. Offline session restoration

No code change to offline persistence model. Previously authenticated users retain Auth + Firestore cache per existing startup; sign-out clears Auth session.

## 8. Remaining defects

- Device-level role restoration and offline sign-in UX not attested by agent in this report.
- Any emulator data with **malformed** `organizationMemberships` documents remain unreadable (by design); data repair is operational, not client.

## 9. Git

Commit SHA and push: see completion message after `git push origin main`.

## 10. Resume hands-on QA

1. Ensure canonical or demo emulators per runbook; do not reset seeded data without authorization.
2. Cold start signed out → confirm Welcome.
3. Exercise each demo role sign-in (teen, barangay03, hospital01, central admin) for home routing.
4. Teen registration end-to-end with PSGC picker.
5. Sign out → confirm Welcome; optional offline reopen with prior session if testing OFFLINE-001.
