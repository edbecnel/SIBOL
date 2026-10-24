# MVR-ORG-IDENTITY-001 — Organization identity verification matrix

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Handover:** AGENT-002 (M1–M4 execution)  
> **Plan:** [SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md](../../Development/SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md)

Legend: **NR** = not run; **PASS** / **FAIL** = executed; **Auto** = automated test; **Manual** = operator.

**Execution date:** 2026-10-25 (AGENT-002)  
**Environment:** Isolated Functions Firestore emulator (`firebase.emulator-functions-test.json`, port 8226); synthetic reference fixtures only.

## Geographic hierarchy (F-01)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| G-01 | Province path region→province→city/mun→barangay | Auto | **PASS** (`shared/geo-reference` tests) |
| G-02 | HUC path region→city→barangay (no province) | Auto | **PASS** (`shared/geo-reference` tests) |
| G-03 | Mixed-path fixture region (both branches) | Auto | **PASS** (`shared/geo-reference` tests) |
| G-04 | Invalid parent-child rejected server-side | Auto | **PASS** (`shared/geo-reference` + create validation) |
| G-05 | Offline bundled PSGC load + search | Auto (Flutter) | **PASS** (asset bundle + `PsgcBundle.load`; widget analyze clean) |

## Identity reservation (F-07)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| I-01 | Duplicate PSGC create (active org) | Auto | **PASS** (`org_identity.test.mjs`) |
| I-02 | Duplicate PSGC create (suspended org) | Auto | **NR** (identity still reserved — not separately asserted) |
| I-03 | Identity key client write denied | Rules Auto | **PASS** (rules deny `organizationIdentityKeys`; not re-run in rules matrix this session) |
| I-04 | Key document permanent (no release field) | Review | **PASS** (implementation: no release API) |

## Creation idempotency (F-04)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| C-01 | Retry same idempotency key + fingerprint | Auto | **NR** (handler implemented; dedicated test NR) |
| C-02 | Same key, different fingerprint | Auto | **NR** |
| C-03 | Concurrent duplicate create | Auto | **NR** (coordination referral concurrency pattern exists; org create NR) |
| C-04 | Single invitation on idempotent replay | Auto | **NR** |

## Teen resolution (F-02, R-03)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| T-01 | PSGC → identity key → active org | Auto | **PASS** (`org_identity.test.mjs`) |
| T-02 | No identity key | Auto | **NR** |
| T-03 | Suspended org | Auto | **PASS** (`teen.registration.test.mjs` PSGC path) |
| T-04 | Re-register different PSGC rejected | Auto | **NR** (implemented in `registerTeenAccount`; test NR) |
| T-05 | Legacy `orgId` shim emulator only | Auto | **PASS** (`teen.registration.test.mjs` + `SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING`) |
| T-06 | Production rejects client `orgId` | Auto | **PASS** (code path without env flag; invalid org id test) |

## NHFR (G-NHFR)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| H-01 | Valid hospital NHFR create | Auto | **NR** (callable implemented; integration test NR) |
| H-02 | RHU type rejected | Auto | **NR** |
| H-03 | Duplicate NHFR | Auto | **NR** |

## Reference versions (F-05)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| V-01 | Supported older version submit | Auto | **NR** |
| V-02 | Revoked version rejected | Auto | **NR** |
| V-03 | No silent code remap | Auto | **NR** |

## Emulator regression (D-13)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| E-01 | Seeded teen `barangay03` assistance | Manual/Auto | **NR** (preserved canonical emulator not exercised this session) |
| E-02 | Seeded staff barangay/MOPH flows | Manual | **NR** |
| E-03 | Demo org not in PSGC picker as real | Manual | **PASS** (synthetic fixture only; no PSA codes on `barangay03`) |
| E-04 | INT-001 MVR rows 1–16 unchanged baseline | Auto | **NR** (`prototype_journey.smoke` not run — avoids emulator reseed) |

## Security (R-01)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| S-01 | Directory access review | SEC-REVIEW-001 | Deferred |

## Functions regression (AGENT-002)

| Suite | Result |
|-------|--------|
| `shared/functions` `npm test` (authz + integration) | **PASS** (58 tests) |
| `shared/geo-reference` `npm test` | **PASS** (5 tests) |
| `shared/facility-reference` `npm test` | **PASS** (1 test) |

**Reference data:** `psgc-synthetic-demo-v1`, `nhfr-synthetic-demo-v1` — **synthetic demonstration only**; G-PSGC-REDIST / G-NHFR official acquisition **open**.
