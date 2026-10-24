# CONTRACT-REG-C — Teen registration and onboarding (repository)

**Handover UUID:** `c6f18a42-9e73-4b05-a2d8-61f0c9e735ab`  
**Status:** Implemented in repository; **not deployed**

## `regListBarangayDirectory`

**Auth:** Optional (unauthenticated allowed).

**Effects:** Returns active `type: barangay` organizations with `orgId`, `name`, optional `legacyBarangayLabel`.

**Does not** expose memberships or administrative fields.

## `regRegisterTeenAccount`

**Auth:** Required.

**Input:**

```json
{
  "selectedBarangayOrgId": "org…",
  "displayName": "optional",
  "privacyConsentAcknowledged": true
}
```

**Effects:** Creates `users/{uid}` with `role: teen`, `selectedBarangayOrgId`, provisional privacy fields, `onboardingStatus`. No organization memberships.

**Errors:** Staff account conflict, suspended org/account, invalid org, missing consent.

**Audit:** `teen_registered` on first create.

## Client Firebase Auth

- Email/password sign-up, verification, password reset via Firebase Auth SDK.
- Profile creation **only** through `regRegisterTeenAccount`.

## Policy

See `shared/functions/src/teen/onboardingPolicy.ts` and `TeenOnboardingPolicy` in Flutter. Email-verification gates default **off** for demo compatibility.
