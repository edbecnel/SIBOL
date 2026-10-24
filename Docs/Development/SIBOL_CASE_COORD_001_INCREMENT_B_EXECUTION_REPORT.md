# SIBOL-CASE-COORD-001 — Increment B execution report

> **Handover UUID:** `f5c2a910-7d46-4e3b-8f21-c0a9e647d352`  
> **Date:** 2026-10-24  
> **Git baseline:** `be97478` → *(commit after publication)*  
> **Firebase / Functions deployed:** **NO** (local implementation and tests only)  
> **MVR-0008 defect fix:** [SIBOL_CASE_COORD_001_MVR_0008_DEFECT_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_MVR_0008_DEFECT_EXECUTION_REPORT.md) (handover `e4c7a219-…`)

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
| `cd shared/firestore-rules-test && npm test` | **59/59** pass |
| `cd sibol_app && flutter test` | **69/69** pass (post MVR-0008 defect fix) |
| `cd sibol_app && flutter analyze` | 0 errors (pre-existing infos) |

## 5. Operational note

Until Functions deploy is authorized, production `createCoordinationReferral` is **unavailable** on `sibol-286d0`; Barangay submit will fail against live project. Firestore coordination **read** rules are already live from Increment A.

## 6. PA acceptance

Pending review.
