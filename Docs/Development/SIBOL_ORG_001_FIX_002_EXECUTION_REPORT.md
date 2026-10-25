# SIBOL-ORG-001-FIX-002 — Execution Report

**Work item:** SIBOL-ORG-001-FIX-002  
**Base HEAD:** `bdf8fdc`

## 1. Root-cause correction

Replaced the rules-incompatible collection query with a **canonical document snapshot** on:

`organizationMemberships/mbr_{primaryOrgId}__{auth.uid}`

Membership fields are validated in [`membership_document_validator.dart`](../../sibol_app/lib/features/org/domain/membership_document_validator.dart) (document id, `accountUid`, `orgId`, `membershipId` consistency). Capabilities are taken only from the membership document.

Firestore rules were **not** loosened.

## 2. Provider contract

[`accountMembershipsProvider`](../../sibol_app/lib/features/org/presentation/providers/org_context_providers.dart):

- Requires auth + profile.
- Teens: empty list (unchanged).
- Staff: if `primaryOrgId` missing/empty → empty list (no Firestore call).
- Else: `watchMembershipForOrg(orgId: primaryOrgId, accountUid: auth.uid)`.
- Auth/profile not yet loaded → `Stream.value([])` (avoids hung `Stream.empty()`).

## 3. Multi-organization compatibility

| Consumer | Prior behavior | Post FIX-002 |
|----------|----------------|--------------|
| `orgAdminManagedOrgIdsProvider` | All memberships from query (failed on client) | Primary-org membership only |
| `barangay*OrgIdProvider` / resolver | List input; fallback when **no** `primaryOrgId` and exactly one cap-bearing membership | Only primary-org membership in list |

**Finding:** The collection query **never succeeded** under current rules, so multi-membership discovery via list was already non-functional on device. Demo seed sets `primaryOrgId` for barangay/MOPH staff ([`emulator_seed.mjs`](../../shared/provisioning/src/emulator_seed.mjs)).

**Gap (documented, not implemented):** Accounts with **multiple** active org memberships and **no** `primaryOrgId` cannot use resolver single-membership fallback until a PA-approved model (e.g. profile org list or server callable) exists. No broad collection enumeration added.

## 4. Security invariants (DEC-ORG-001)

- Capabilities only from membership document.
- No collection-wide membership reads.
- No capability inference from role or `primaryOrgId` alone.
- Inactive/suspended/revoked memberships still parsed but resolver denies operational org ids.

## 5. Tests

| Suite | Result |
|-------|--------|
| Firestore rules (isolated emulator) | **100/100 PASS** — includes query deny, canonical get allow, malformed id deny |
| Flutter | **120/120 PASS** — validator, membership id, provider wiring, dashboard capability widget tests |

### Integration evidence

- **Verified:** Rules unit tests simulate Flutter query shape (`where accountUid`) → **denied**; canonical `get` → **allowed**.
- **Verified:** Repository uses `.doc(mbr_{org}__{uid}).snapshots()` (rules-compatible path).
- **Unverified:** On-device Flutter binary against PO live emulator session (not run; no emulator restart). PO should hot-restart and confirm administration card without `PERMISSION_DENIED` spam.

## 6. QA continuation (non-destructive)

1. Hot restart Flutter (`R` in `flutter run`) on existing `barangay.org.admin@sibol.local` session.
2. Expect **Organization administration** card and Staff administration entry.
3. Operational buttons remain disabled (management-only caps).
4. Do not reseed, sign out, or change memberships.

## 7. Files touched

- `sibol_app/lib/features/org/domain/membership_id.dart`
- `sibol_app/lib/features/org/domain/membership_document_validator.dart`
- `sibol_app/lib/features/org/data/repositories/organization_repository_impl.dart`
- `sibol_app/lib/features/org/presentation/providers/org_context_providers.dart`
- Tests under `sibol_app/test/` and `shared/firestore-rules-test/test/organizations_memberships.rules.test.mjs`
