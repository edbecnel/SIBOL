# Registered teen ↔ case callables (SIBOL-CASE-IDENTITY-001)

## Identity ownership

| Store | Maintainer | Notes |
|-------|------------|-------|
| `users/{teenUid}` | Registered teenager | Identity, contact, barangay assignment; Auth sign-in separate |
| `cases/{caseId}` | Authorized Barangay staff | Own identity/contact fields; may start from a one-time teen snapshot |

**Teen profile edits never automatically overwrite established Barangay case identity/contact information. Barangay case edits never overwrite teen site registration or authentication credentials.**

Linkage fields on the case (`teenUid`, `linkedAccountEmail`, `identityLinkedAt`) retain existing contracts. `linkedAccountEmail` is the Auth email snapshot at linkage time, not a live mirror.

## `regResolveRegisteredTeenForCase`

- **Caller:** Barangay staff with `case.write` on the case `orgId`.
- **When:** Online verification before activating or linking a registered case.
- **Effect:** Returns authoritative teen profile + Auth email for client to apply to the case document (one-time snapshot at linkage). Does not write to `users/{uid}`.

## `regSyncRegisteredTeenCasesFromProfile` (disabled)

- **Status:** Compatibility stub only (callable export unchanged).
- **Behavior:** Requires authentication; returns `failed-precondition` with an explanatory message; **no Firestore writes** (including no new `teenProfileSyncedAt`).
- **History:** Previously pushed teen profile contact fields onto linked cases and set `teenProfileSyncedAt`. That ongoing synchronization was removed per identity ownership correction. Existing `teenProfileSyncedAt` values on cases are historical markers only.

## Client surfaces removed

- Automatic invocation after teen **Edit my profile** save.
- Barangay case detail **Refresh contact from teen profile** action.
