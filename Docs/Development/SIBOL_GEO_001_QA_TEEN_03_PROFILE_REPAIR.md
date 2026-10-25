# QA Teen 03 — `assignedBarangay` profile repair (PO approval required)

**Work item:** SIBOL-GEO-001-FIX-002  
**Purpose:** One-time emulator correction for teens registered before registration persisted `assignedBarangay`.  
**Do not run** until the Project Architect / Product Owner authorizes after FIX-002 code is loaded on the Functions emulator.

## Preconditions

- Teen account already exists with `role: teen`, `onboardingStatus: complete`.
- `selectedBarangayOrgId` is the intended Barangay organization (e.g. `barangay03`).
- Functions emulator runs FIX-002+ `registerTeenAccount` for **new** registrations only; this repair is for **existing** profiles.

## Verify (read-only)

Using Firebase Emulator UI or `firebase firestore:get` against the emulator:

1. `users/<QA_TEEN_03_UID>` — note `selectedBarangayOrgId`, confirm `assignedBarangay` is missing or empty.
2. `organizations/barangay03` — confirm `type: barangay`, `status: active`.

## Choose label value

| Option | Value | When to use |
|--------|--------|-------------|
| A — PSA geographic | `Barangay 3, Balingasag` | Matches PSGC `1004302022` official names in `psgc-psa-2025-2q` |
| B — Demo consistency | `Barangay Tres, Balingasag` | Aligns with seeded demo teen and `DEMO_ASSIGNED_BARANGAY` |

Product Owner selects A or B for emulator QA consistency with barangay staff views.

## Patch (single field)

Update **only** `assignedBarangay` on the teen user document. Do not change `selectedBarangayOrgId`, auth record, or assistance drafts in the app.

Example (replace `TEEN_UID` and label):

```javascript
// Run against Firestore emulator only (FIRESTORE_EMULATOR_HOST set).
const admin = require("firebase-admin");
admin.initializeApp({ projectId: "sibol-286d0" });
const db = admin.firestore();
await db.collection("users").doc("TEEN_UID").update({
  assignedBarangay: "Barangay 3, Balingasag", // or Option B
});
```

## After repair

1. **Hot-restart Flutter** or trigger profile refresh so `userProfileProvider` loads `assignedBarangay`.
2. Retry assistance submit on the existing in-app draft (PO action; not part of agent FIX-002).

## Out of scope

- Re-running teen registration (idempotent path does not backfill `assignedBarangay`).
- Production Firestore writes without a separate approved migration.
