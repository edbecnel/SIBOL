# SIBOL-CASE-COORD-001 — Increment B execution report

> **Handover UUID:** `f5c2a910-7d46-4e3b-8f21-c0a9e647d352`  
> **Date:** 2026-10-24  
> **Git baseline:** `be97478` → *(commit after publication)*  
> **Firebase:** `createCoordinationReferral` **deployed** 2026-10-24; registry rules v2 in repo **not deployed**  
> **MVR-0008:** [Pass](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) — [acceptance](SIBOL_CASE_COORD_001_INCREMENT_B_ACCEPTANCE_REPORT.md) (`3c7e2a91-…`)  
> **Defect fix:** [SIBOL_CASE_COORD_001_MVR_0008_DEFECT_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_MVR_0008_DEFECT_EXECUTION_REPORT.md) (`e4c7a219-…`)

## 1. Scope delivered

| Area | Summary |
|------|---------|
| Callable | `createCoordinationReferral` in [`shared/functions/src/coordination/createCoordinationReferral.ts`](../../shared/functions/src/coordination/createCoordinationReferral.ts) |
| Barangay UI | Referral action on acknowledged request; form, privacy copy, preview, callable submit |
| MOPH UI | Coordination section on dashboard; read-only detail with staff-event timeline |
| Tests | Functions emulator tests (10); Flutter +2 (60 total); rules suite unchanged (59) |

Increment C (clarification, follow-up, closure) **not** started.

## 2. Callable summary

- Auth: Firebase Auth uid → `users/{uid}` role `barangay`, `active`, `assignedBarangay`.
- Validates acknowledged `teenAssistanceRequests/{id}`; rejects duplicate `barangayCoordinationRegistry/{id}`.
- Admin transaction writes header, `private/binding`, registry, initial `staffEvents`, `teenCoordinationLinks`.
- Server-generated `displayRef` (`SIBOL-REF-{16 hex}`); category from assistance doc; summary 10–2000 chars.

## 3. Privacy

- MOPH UI shows header + staff events only (no teen uid, name, or original description).
- Barangay UI warns before submit; preview step shows MOPH-visible fields only.
- Rules do not detect identifying text inside free-text summary (ADR-0005).

## 4. Verification

| Command | Result |
|---------|--------|
| `cd shared/functions && npm test` | **10/10** pass |
| `cd shared/firestore-rules-test && npm test` | **63/63** pass (post registry security tests) |
| `cd sibol_app && flutter test` | **70/70** pass (post registry probe staging) |
| `cd sibol_app && flutter analyze` | 0 errors (pre-existing infos) |

## 5. Operational notes

- Callable **live** on `sibol-286d0` (see [deploy report](SIBOL_CASE_COORD_001_INCREMENT_B_FIREBASE_DEPLOY_EXECUTION_REPORT.md)).
- Coordination **read** rules on live project remain Increment A; registry absence probe in app until [registry rules deploy](SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md).

## 6. PA acceptance

**Accepted** — [SIBOL_CASE_COORD_001_INCREMENT_B_ACCEPTANCE_REPORT.md](SIBOL_CASE_COORD_001_INCREMENT_B_ACCEPTANCE_REPORT.md).
