# P0 — Teen registration / sign-in failure (post REG-004)

**Handover context:** Galaxy S9 PO report after teen self-registration attempt  
**Git baseline:** `ba1071d`  
**Firebase:** `sibol-286d0` — **read-only** live check only; no account mutations

## Root cause

1. **Order of operations:** Registration calls `registerWithEmail` (Firebase Auth) **before** `regRegisterTeenAccount` (Firestore `users/{uid}` profile). If the callable fails, Auth user remains; profile is missing.

2. **Live evidence (read-only):** At investigation time, **1** Auth user had **no** `users/{uid}` document (masked email `ed***@gmail.com`, created 2026-10-27). This matches a partial registration.

3. **“Back to Register as Teen” / welcome:** After failure, the user could navigate to Welcome while still signed in with no profile. Router allowed Welcome with `profile == null`, so the flow looked like a reset without success or error.

4. **Sign-in “no response”:** `signIn` **does** invoke `signInWithEmail`. On success with **no profile**, `resolveAppRedirect` previously kept `onLogin` → **stay on login** with no error and no navigation — silent failure.

5. **Not caused by DOB formatter:** Submission still sends `YYYY-MM-DD` when validation passes; formatter does not skip the callable.

**Callable failure reason for the live orphan:** Not captured in device logs (empty). Typical causes: Barangay PSGC mapping, identity validation, age bounds (server 10–19 vs client 13–19), or network. PO can retry **Complete registration** after this fix.

## Client fixes (Flutter only)

| Change | Purpose |
|--------|---------|
| `app_redirect.dart` | Missing profile on **login/splash** → `accountNotProvisioned`; with teen intent → **teen register**; profile loading on login stays on login |
| `account_not_provisioned_screen.dart` | **Continue Teen registration** + clearer copy |
| `teen_registration_screen.dart` | Re-`markInProgress` on error so intent survives failure |

## Tests

- `app_redirect_test.dart` — **pass** (including new login / intent cases)
- `teen_registration_screen_test.dart`, `login_screen_test.dart` — **pass**

## APK

Release build + `adb install -r` on Galaxy S9 (data preserved). No live sign-in performed by engineering.

## PO manual verification

1. Sign in with the **existing** orphan account → should land **Account not ready** or **Teen registration** (with intent), not a dead login screen.
2. Tap **Continue Teen registration** → complete profile (callable must succeed).
3. New registration: if callable fails, error text on registration screen; sign-in should route to recovery screen above.

## Live data repair

Orphan Auth user remains until PO completes registration or separate approval to delete Auth record. **No live writes** in this hotfix.

## Classification

**PARTIAL** — Client routing/recovery fixed and APK delivered; **callable success** and end-to-end registration require PO manual test with authorized credentials.
