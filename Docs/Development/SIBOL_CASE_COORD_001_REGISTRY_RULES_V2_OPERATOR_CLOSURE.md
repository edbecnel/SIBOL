# SIBOL-CASE-COORD-001 — Registry rules v2 operator closure (EDF record)

> **Status:** Closure inventory — **separate** from SIBOL-REG-001 architecture  
> **Last updated:** 2026-10-24  
> **Handover context:** SIBOL-REG-001-ARCH-DOC-001 §7

## Purpose

Record operator-reported Registry Rules v2 closure items with provenance. This document does **not** authorize Firebase deploy, feature-flag changes, or REG implementation.

## 1. Operator smoke test (readiness §5.4–5.5)

| Item | Record |
|------|--------|
| **Reported result** | **4/4 PASS** (operator attestation relayed to PA/EA via product-owner coordination) |
| **EA independent execution** | **No** — EA did not run live client-signed registry reads in deploy execution report |
| **Procedure basis** | [SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md](SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md) §5.4–5.5 |
| **Rules deploy** | Registry rules v2 **deployed** 2026-10-24 per [deploy execution report](SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_DEPLOY_EXECUTION_REPORT.md) |

**Provenance note:** The literal string `4/4` does not appear in prior repository commits; this closure document is the **authoritative EDF record** of the operator-reported outcome as of ARCH-DOC-001.

## 2. MVR-0008 assistance request id

| Item | Record |
|------|--------|
| Discrepancy | MVR-0008 lists `3odtqzgOTgIalL8wuWue`; canonical live id `3odtqzgOTgIaIL8wuWue` |
| Correction | [MVR-0008-ADDENDUM-assistance-request-id.md](../Verification/Records/MVR-0008-ADDENDUM-assistance-request-id.md) |
| MVR-0008 acceptance | **Not reopened** |

## 3. Flutter `SIBOL_COORD_REGISTRY_RULES_V2`

| Item | Record |
|------|--------|
| Default in repo | `false` ([`env_config.dart`](../../sibol_app/lib/config/env_config.dart)) |
| ARCH-DOC-001 action | **No change** — flag not enabled in documentation handover |
| Stage 2 builds | Optional when PA approves client rollout ([readiness §7](SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md)) |

## 4. Live negative authorization tests

| Item | Record |
|------|--------|
| Client-signed deny scenarios (teen/MOPH/cross-barangay registry) | **Outstanding** — not run in EA deploy verification |
| Emulator coverage | **66/66** rules tests at deploy time (includes registry negatives in emulator) |
| Recommended follow-up | Operator or PA-authorized live negative matrix when audit trail required |

## 5. Related documents (unchanged acceptance)

- [MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) — Pass steps 1–9
- [MVR-0009](../Verification/Records/MVR-0009-case-coord-001-b-history-barangay-referrals.md) — Pass 7/7
