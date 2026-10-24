# MVR-ORG-IDENTITY-001 — Organization identity verification matrix

> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Handover:** AGENT-001 (M0 draft); implementation **NOT RUN**  
> **Plan:** [SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md](../../Development/SIBOL_ORG_IDENTITY_001_IMPLEMENTATION_PLAN.md)

Legend: **NR** = not run; **Auto** = automated test; **Manual** = operator.

## Geographic hierarchy (F-01)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| G-01 | Province path region→province→city/mun→barangay | Auto | NR |
| G-02 | HUC path region→city→barangay (no province) | Auto | NR |
| G-03 | Mixed-path fixture region (both branches) | Auto | NR |
| G-04 | Invalid parent-child rejected server-side | Auto | NR |
| G-05 | Offline bundled PSGC load + search | Auto (Flutter) | NR |

## Identity reservation (F-07)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| I-01 | Duplicate PSGC create (active org) | Auto | NR |
| I-02 | Duplicate PSGC create (suspended org) | Auto | NR |
| I-03 | Identity key client write denied | Rules Auto | NR |
| I-04 | Key document permanent (no release field) | Review | NR |

## Creation idempotency (F-04)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| C-01 | Retry same idempotency key + fingerprint | Auto | NR |
| C-02 | Same key, different fingerprint | Auto | NR |
| C-03 | Concurrent duplicate create | Auto | NR |
| C-04 | Single invitation on idempotent replay | Auto | NR |

## Teen resolution (F-02, R-03)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| T-01 | PSGC → identity key → active org | Auto | NR |
| T-02 | No identity key | Auto | NR |
| T-03 | Suspended org | Auto | NR |
| T-04 | Re-register different PSGC rejected | Auto | NR |
| T-05 | Legacy `orgId` shim emulator only | Auto | NR |
| T-06 | Production rejects client `orgId` | Auto | NR |

## NHFR (G-NHFR)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| H-01 | Valid hospital NHFR create | Auto | NR (blocked until G-NHFR) |
| H-02 | RHU type rejected | Auto | NR |
| H-03 | Duplicate NHFR | Auto | NR |

## Reference versions (F-05)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| V-01 | Supported older version submit | Auto | NR |
| V-02 | Revoked version rejected | Auto | NR |
| V-03 | No silent code remap | Auto | NR |

## Emulator regression (D-13)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| E-01 | Seeded teen `barangay03` assistance | Manual/Auto | NR |
| E-02 | Seeded staff barangay/MOPH flows | Manual | NR |
| E-03 | Demo org not in PSGC picker as real | Manual | NR |
| E-04 | INT-001 MVR rows 1–16 unchanged baseline | Auto | NR |

## Security (R-01)

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| S-01 | Directory access review | SEC-REVIEW-001 | Deferred |

**M0 status:** Matrix **prepared**; all execution cells **NR**.
