# SIBOL-QA-007 — Execution Report

**Handover:** SIBOL-QA-007-AGENT-001  
**Base commit:** `3f7873f`  

## Root cause (confirmed)

After **Create sign-in**, Firebase Auth signed the user in immediately while `users/{uid}` was still absent. The router redirect ran with **`profileAsync.isLoading`**, but `resolveAppRedirect` only allowed splash and account-not-provisioned during profile load. **`/teen-register` was redirected to splash**; when the profile stream settled to `null`, splash redirected to **Account not ready**.

Hypothesis verified: premature global redirect during profile loading, not Firestore profile creation at auth step.

## Registration and routing changes

1. **Profile loading:** Stay on teen registration routes (and password reset) while profile loads.
2. **Teen self-registration intent:** Local secure-storage flag set when entering Teen registration; cleared on successful `registerTeenAccount` or sign-out. While set, authenticated users without a profile are routed to **`/teen-register`** from splash/account-not-provisioned (recovery after interrupt).
3. **Prototype email:** Skip optional `sendEmailVerification` when verification policy is false.

Staff without intent and without profile still land on **Account not ready** (no client-side role assignment).

## Incomplete accounts

- Auth-only Teen mid-flow: intent flag returns user to Teen registration after restart.
- No automatic deletion of partial Auth users.
- Duplicate email still handled by Auth emulator / mapped messages (QA-006).

## Email verification policy

Documented in [SPEC-REG-001-EMAIL-VERIFICATION-BACKLOG.md](../Specifications/SPEC-REG-001-EMAIL-VERIFICATION-BACKLOG.md): prototype off; production requires Firebase verification **and** backend enforcement (deferred).

## Security

Intent flag is **navigation-only**; `regRegisterTeenAccount` and Firestore rules unchanged. Staff cannot obtain Teen role without server provisioning.

## Tests

| Suite | Result |
|-------|--------|
| Flutter | **105/105 PASS** |
| Android debug build | **PASS** (`flutter build apk --debug`) |

## Android emulator (device UI)

Full Teen registration journey on `emulator-5554`: **NOT RUN** by agent.

## PA — resume QA

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL/sibol_app
flutter run -d emulator-5554 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Welcome → Register as Teen → Create sign-in → **profile/PSGC step** (not Account not ready) → complete → Teen home.

Use a new fictional email if an earlier QA account is partial; do not clear app data or delete emulator users without authorization.
