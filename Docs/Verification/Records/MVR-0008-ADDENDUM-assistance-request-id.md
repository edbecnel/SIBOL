# MVR-0008 ADDENDUM — Assistance request document id correction

> **Status:** Factual correction (traceability) — **does not reopen** MVR-0008 acceptance  
> **Parent record:** [MVR-0008-case-coord-001-increment-b-referral-live.md](MVR-0008-case-coord-001-increment-b-referral-live.md)  
> **Date:** 2026-10-24  
> **Work stream:** SIBOL-CASE-COORD-001 (separate from SIBOL-REG-001)

## Purpose

Preserve historical MVR-0008 execution evidence while recording the **canonical** assistance request document id used in live Firebase and deploy verification.

## Correction

| Source | Document id value |
|--------|-------------------|
| MVR-0008 execution summary (operator entry) | `3odtqzgOTgIalL8wuWue` (typo: `l` vs `I` in segment) |
| Deploy execution report fixture / Admin SDK | `3odtqzgOTgIaIL8wuWue` |
| **Canonical id for traceability** | **`3odtqzgOTgIaIL8wuWue`** |

## Provenance

- Operator **Pass** for steps 1–9 (2026-10-24) remains valid; referral workflow outcome is unchanged.
- Typo identified in [SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_DEPLOY_EXECUTION_REPORT.md](../../Development/SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_DEPLOY_EXECUTION_REPORT.md) §8.
- **EA did not modify** the body of MVR-0008 per governance: historical records are not silently edited.

## Action for future references

Use canonical id `3odtqzgOTgIaIL8wuWue` in new documentation, fixtures, and operator procedures. Readers of MVR-0008 §Execution summary should consult this addendum.
