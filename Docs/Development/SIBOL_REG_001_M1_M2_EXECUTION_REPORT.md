# SIBOL-REG-001 — M1/M2 execution report

**Handovers:** M1/M2 AGENT-001, M1/M2 RELEASE-READY-001  
**Starting HEAD (release-ready):** `4812606de7029abc6d7c6dc09fb0d80ebbd69074`

## Verification summary (repository / emulator)

| Suite | Result | Notes |
|--------|--------|--------|
| `shared/migration` npm test | **10/10** | Plan, mapping, apply dry-run/idempotency/conflict |
| `shared/firestore-rules-test` npm test | **87/87** | Includes `org_scoped_security.rules.test.mjs` |
| `shared/functions` `npm test` | **24/24** | 6 authz unit + 18 integration (coordination) |
| `sibol_app` flutter test | **74/74** | Widget/unit |
| MVR-REG-001 production | **NOT RUN** | See [matrix](../Verification/Records/MVR-REG-001-M1-M2-Repository-Security-Matrix.md) |

## Functions regression isolation

- **Config:** `firebase.emulator-functions-test.json` (Firestore **8226**, hub **4421**, logging **4521**).
- **Runner:** `shared/functions/scripts/run-firestore-integration-tests.mjs` (invoked by `npm test`).
- **Conflict cause:** Rules suite uses `firebase.emulator-isolated.json` (8215/4410/4510); reusing hub or stale emulator data caused hub port failures and duplicate referral flakes.
- **Procedure:** Documented in `shared/functions/test/README.md`.

## Flutter / workflow compatibility (M2)

| Workflow | M2 dependency | Demo status |
|----------|----------------|-------------|
| Teen assistance create | `selectedBarangayOrgId` on user + `orgId` on request | Demo org constant on write; provisioning sets teen `selectedBarangayOrgId` for canonical barangay |
| Barangay case create | `orgId` + membership `case.write` | `DemoOrgConstants.barangayTresOrgId` on create |
| Barangay assistance inbox | Query by `barangay` string; rules enforce `orgId` | Demo label + org on documents |
| Aggregate report | `orgId` on submit | Demo org constant |
| Coordination referral | Callable org authz | Emulator-tested |
| MOPH inbox | `primaryOrgId` + `coordination.hospital` | Requires migration/provisioning of MOPH membership (not in seed script yet) |
| Case list query | No client `orgId` filter | Rules deny cross-org per document |

**Production gap (documented, not REG-B):** Full registration/membership provisioning and non-demo org resolution are out of scope; live cutover requires M1 + operator membership grants.

## Indexes

Verified against Flutter queries: `organizationMemberships` by `accountUid`; reports (MOPH + barangay lists); coordination phase/barangay lists; org-scoped composites added in M2. Single-field `accountUid` equality may use auto-index; composite retained for filtered membership listing.

## Deployment boundary

No `firebase deploy`, no live migration, no production exports executed under release-ready handover.

## EDF artifacts

- [M1/M2 implementation spec](SIBOL_REG_001_M1_M2_IMPLEMENTATION_SPEC.md)
- [M1 migration runbook](../Operations/REG-001-M1-Migration-Runbook.md)
- [M2 deployment/cutover runbook](../Operations/REG-001-M2-Deployment-Cutover-Runbook.md)
- [Repository security matrix](../Verification/Records/MVR-REG-001-M1-M2-Repository-Security-Matrix.md)
