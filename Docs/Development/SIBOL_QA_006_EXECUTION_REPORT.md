# SIBOL-QA-006 — Execution Report

**Handover:** SIBOL-QA-006-AGENT-001  
**Base commit:** `b21c767`  
**Related:** SIBOL-STARTUP-001, SIBOL-QA-001  

## Observed failure (QA-06)

On **Create sign-in** during Teen registration on Android API 37 emulator:

- UI: `Instance of 'AuthException'`
- Log: `Cleartext HTTP traffic to 10.0.2.2 not permitted` during `RecaptchaCallWrapper` / `signUpPassword`

## Root cause

1. **Android network security:** Debug builds had no `networkSecurityConfig`. Firebase Auth Android SDK talks to the Auth emulator at `http://10.0.2.2:9099` (host loopback from the emulator). Android 9+ blocks cleartext HTTP by default, so sign-up failed before credentials reached the emulator.
2. **Error display:** `AuthException` did not override `toString()`, and Teen registration used `e.toString()` for non-`Failure` errors, surfacing the Dart type name instead of `toFailure().message`.

reCAPTCHA in the log is a wrapper on the Auth SDK path; the blocking condition was cleartext policy, not production reCAPTCHA configuration.

The same `10.0.2.2` cleartext allowance applies to Firestore (`8195`) and Functions (`5001`) emulators when using HTTP from the Android emulator.

## Corrective action

| Item | Change |
|------|--------|
| Debug NSC | `android/app/src/debug/res/xml/network_security_config.xml` — cleartext permitted **only** for `10.0.2.2` |
| Profile NSC | Same file under `profile/` for non-release profile builds |
| Manifests | Debug/profile `AndroidManifest.xml` set `android:networkSecurityConfig` on `<application>` |
| Release | `main/AndroidManifest.xml` unchanged — no cleartext, no NSC reference |
| Auth UX | `AppException.toString()` → message; expanded `AuthException` code map; `userErrorMessage()`; Teen registration / login / password reset use it |
| Diagnostics | `developer.log` on auth repository failures (no passwords) |

## Debug / release separation

- **Merged debug manifest** includes `@xml/network_security_config`.
- **Merged release manifest** has no `networkSecurityConfig` or `usesCleartextTraffic` (verified after `flutter build apk --release`).

## Test evidence

| Check | Result |
|-------|--------|
| Flutter `flutter test` | **100/100 PASS** (incl. `auth_exception_test`, `android_network_security_test`) |
| `flutter build apk --debug` | **PASS** |
| `flutter build apk --release` | **PASS** |
| Auth emulator REST sign-up (host) | **PASS** (`teen.qa006.agent@example.com` created for agent verification only) |
| Android emulator Create sign-in (device UI) | **NOT RUN** by agent — PA to re-run QA-06 after install |

## PA — resume QA-06

1. Keep canonical emulators running (9099 / 8195 / 5001); do not reset data.
2. Rebuild and run:

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL/sibol_app
flutter run -d emulator-5554 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

3. Welcome → Register as Teen → Create sign-in with a **new** fictional email (or sign in if `teen.qa001@example.com` was partially created).
4. Confirm step 2 (profile / PSGC) appears; duplicate email shows readable message.
5. Sign in with a provisioned demo account — routing unchanged.

## Remaining limitations

- Cleartext is limited to `10.0.2.2` in debug/profile only; physical devices hitting emulators on LAN IP need a separate NSC entry (out of scope).
- `teen.qa006.agent@example.com` was added on the Auth emulator during agent verification; do not delete without authorization.
