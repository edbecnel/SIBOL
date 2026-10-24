# SIBOL-REG-001 — M1/M2 execution report

**Handover:** SIBOL-REG-001-M1-M2-AGENT-001  
**Starting HEAD:** `eff05cb41c0c228bd28be1cd26748793ef0255cb`  
**Ending HEAD:** `38d7677a5c1bb4196d6771bd34ebe9e9b0ae4a03`

## Git checkpoints (pushed `origin/main`)

| Commit | Summary |
|--------|---------|
| `ce75ac4` | M1 migration tooling |
| `12b1646` | M2 rules, indexes, Functions coordination authz, rules tests |
| `38d7677` | Flutter/provisioning `orgId`, EDF docs |

## Verification summary

| Suite | Result |
|--------|--------|
| `shared/migration` npm test | 3/3 pass |
| `shared/firestore-rules-test` npm test | 82/82 pass |
| `shared/functions` authz unit tests | 6/6 pass |
| `sibol_app` flutter test | 74/74 pass |
| `shared/functions` coordination (emulator) | Run via `firebase emulators:exec` on clean port; direct rerun against stale emulator may fail duplicate-referral assertions |

## REG-A obligations addressed

- `assertActiveOrganization` unit tests in `shared/functions/test/authz.test.mjs`.
- `organizationMemberships` `accountUid` + `status` composite index in `firestore.indexes.json`.
- Org-scoped report/coordination query indexes added.

## Deployment boundary

No `firebase deploy`, no live migration executed. PA authorization required for DEPLOY-R1, M1 live, M2 live.

## Security matrix (rules)

Covered in `shared/firestore-rules-test`: cross-barangay deny, forged `orgId`, missing `orgId`, org admin without case caps, immutable case `orgId`, assistance/coordination/report org scoping, MOPH hospital capability reads.
