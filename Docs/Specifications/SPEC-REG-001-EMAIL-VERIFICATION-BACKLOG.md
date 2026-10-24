# SPEC-REG-001 — Email verification (production backlog)

**Status:** Deferred (documented in SIBOL-QA-007)  
**Prototype:** Emulator / fictional emails — verification **not** required.

## Prototype / emulator (implemented)

- Fictional email addresses permitted.
- `TeenOnboardingPolicy.requireEmailVerificationBeforeProfile` and `requireEmailVerificationBeforeAssistance` are **false**.
- Teen registration completes without outbound email delivery.
- Flutter navigation alone does not grant protected access; Firestore rules and callables enforce server state.

## Production (required before live Teen self-registration)

1. Enable Firebase Authentication email verification for Teen sign-up.
2. Set client policy flags to require verification before profile completion and/or assistance (Product Owner gate).
3. **Backend enforcement:** `regRegisterTeenAccount` and Firestore rules must reject or gate teens with `emailVerified == false` (or equivalent server field). Client `dart-define` or UI flags must not be the sole control.
4. Block assistance and org-scoped operations until verification is recorded on the trusted user profile.

## Security note

Do not ship a client-only environment flag that disables verification in production builds.
