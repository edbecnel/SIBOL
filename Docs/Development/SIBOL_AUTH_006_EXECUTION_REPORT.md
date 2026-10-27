# SIBOL-AUTH-006 — Teen email password recovery

**Handover UUID:** `d8b5a172-6f43-4c90-a218-9e37f05b624c`  
**Firebase:** `sibol-286d0`

## Root cause

Password recovery was **implemented** (`PasswordResetScreen` → `FirebaseAuth.sendPasswordResetEmail`) and reachable from **Forgot password?** on the login screen, but:

1. **`AuthController.sendPasswordResetEmail` toggled global `AsyncLoading` / `AsyncError`** used by the login screen. After a reset attempt, returning to sign-in could show a **stuck loading sign-in button** or a **misleading auth error** unrelated to sign-in.
2. **No client validation** for empty, malformed, or **`.local` demo emails** — confusing failures or attempts that cannot deliver mail.
3. **Weak success/error UX** on the reset screen (minimal copy, easy to miss confirmation).
4. **Signed-in users** were redirected away from `/password-reset` if opened while authenticated (edge case).

**Not missing:** Firebase API wiring or login navigation to `/password-reset`.

**Change password (signed in)** remains `ChangePasswordScreen` + `updatePassword` — separate from this flow.

## Implementation

| File | Change |
|------|--------|
| `password_recovery_email.dart` | Validation + `.local` demo blocking |
| `password_reset_screen.dart` | Clear copy, validation, success/error layout |
| `auth_providers.dart` | Reset email no longer mutates login `AsyncValue` |
| `app_redirect.dart` | Allow `/password-reset` while signed in |

## Tests

- `password_recovery_email_test.dart` — **pass**
- `password_reset_screen_test.dart` — **pass** (real email invokes repo; `.local` blocked)
- `login_screen_test.dart` — **pass** (Forgot password visible)
- `app_redirect_test.dart` — **pass**

## Firebase configuration

No project changes made. Real-email delivery depends on Firebase Auth email templates, spam filters, and inbox access — **PO manual verification required**.

## APK / device

Release APK built and `adb install -r` on Galaxy S9 (data preserved). **No live email test** performed by engineering.

## Classification

**PARTIAL** — Client correction shipped; **live inbox reset link** pending PO test.
