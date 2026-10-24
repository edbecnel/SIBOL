# MVR-REG-001 — Registration and authorization verification plan

> **Status:** Plan only — **no procedures executed** in SIBOL-REG-001-ARCH-DOC-001  
> **Work item:** SIBOL-REG-001  
> **Spec:** [SPEC-REG-001](../../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md)  
> **Handover:** `SIBOL-REG-001-ARCH-DOC-001`

## 1. Objective

Verify registration, membership, organization isolation, administrative controls, and audit behavior after REG implementation and **before** production use with real sensitive information.

## 2. Prerequisites

- REG callables deployed per [CONTRACT-REG-001](../../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md).
- Firestore rules updated for org-scoped `cases/*` and related paths.
- `shared/firestore-rules-test` extended with REG suites (target: pass before deploy).
- Test organizations: at least Barangay A, Barangay B, MOPH hospital org.
- Fictional accounts only unless PO authorizes otherwise.

## 3. Security invariants under test

Cross-reference SPEC-REG-001 §4.2 (`INV-ORG-READ` through `INV-AUDIT`).

## 4. Procedures

| ID | Scenario | Method | Expected | Result |
|----|----------|--------|----------|--------|
| REG-01 | Teen self-registration with Barangay org selection | Manual + rules test | Account created; routing org stored; no staff approval required | **NOT RUN** |
| REG-02 | Teen cannot read `cases/*` | Rules emulator | Deny | **NOT RUN** |
| REG-03 | Staff invitation email → sign-up → pending membership | Manual | Membership `pending` until approval | **NOT RUN** |
| REG-04 | Org Admin approves staff | Callable + manual | Membership `active`; audit event | **NOT RUN** |
| REG-05 | Self-approval attempt | Callable | `permission-denied`; no audit approve | **NOT RUN** |
| REG-06 | Org Admin assigns disallowed role (e.g. `central_admin`) | Callable | Deny | **NOT RUN** |
| REG-07 | Barangay A staff reads Barangay A case | Rules + manual | Allow | **NOT RUN** |
| REG-08 | Barangay A staff reads Barangay B case (cross-barangay deny) | Rules + manual | **Deny** | **NOT RUN** |
| REG-09 | Hospital staff reads peer hospital artifact (if second hospital fixture exists) | Rules | **Deny** | **NOT RUN** |
| REG-10 | MOPH staff access scoped to hospital org | Manual | Per policy; no cross-hospital | **NOT RUN** |
| REG-11 | Suspended membership | Callable + rules | All org-scoped ops denied | **NOT RUN** |
| REG-12 | Suspended organization | Rules | Org data denied for active memberships | **NOT RUN** |
| REG-13 | Account suspension | Callable + rules | All memberships ineffective | **NOT RUN** |
| REG-14 | Multiple memberships — active org switch | Manual | Ops only apply to active `orgId` | **NOT RUN** |
| REG-15 | Remove last org admin without central recovery | Callable | Deny | **NOT RUN** |
| REG-16 | Central recovery appoints new org admin | Callable | Success; audit | **NOT RUN** |
| REG-17 | Org Admin without case role reads teen case | Rules | **Deny** (admin ≠ clinical) | **NOT RUN** |
| REG-18 | Client direct write to `users.role` or membership `status` | Rules emulator | Deny | **NOT RUN** |
| REG-19 | Audit record on org create | Admin read | Immutable audit doc present | **NOT RUN** |
| REG-20 | Revoked membership re-invite flow | Manual | Policy-compliant path only | **NOT RUN** |

## 5. Automated test alignment

| Suite | Location | Status |
|-------|----------|--------|
| Firestore rules REG scenarios | `shared/firestore-rules-test` (future) | **NOT RUN** |
| Callable unit tests | `shared/functions` (future) | **NOT RUN** |
| Flutter widget/integration | `sibol_app/test` (future) | **NOT RUN** |

## 6. Sign-off

| Role | Result | Date |
|------|--------|------|
| Operator | — | — |
| PA | — | — |

## 7. Related

- Demo-era evidence remains in MVR-0001–0009; this plan does not replace them.
- Registry rules v2 operator closure: [SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_OPERATOR_CLOSURE.md](../../Development/SIBOL_CASE_COORD_001_REGISTRY_RULES_V2_OPERATOR_CLOSURE.md) (separate work stream).
