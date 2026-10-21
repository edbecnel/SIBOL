# SIBOL-IMP-002 T2-3 — Execution report (case create/edit)

> **Implementation handover:** `b72d5c94-13f6-4a82-9e05-8c6f241da739`  
> **Security verification & publication handover:** `f3a7c219-6b48-4e91-8d35-20c6f74ab582`  
> **Phase:** T2-3 — case creation and editing  
> **Date:** 2026-10-21  
> **Firestore rules deploy:** **Not authorized** (Git publication authorized; deploy is separate)  
> **Live Firestore writes (T2-3 testing):** **Not authorized**  
> **PA acceptance:** Pending

## 1. PA authorization

| Handover | Scope |
|----------|--------|
| `b72d5c94-…` | Local T2-3 implementation and emulator verification |
| `f3a7c219-…` | Security verification, EDF updates, conditional Git publication |

T2-4+, **live Firebase deploy**, and live case writes require separate handover.

## 2. Implementation summary

- Extended `CaseRepository` with `createCase` / `updateCase`.
- `CaseWritePolicy` enforces `notSubmitted` on create and immutable `createdAt` / `reportStatus` on client update.
- `CaseEditScreen` for `/barangay/cases/new` and `/barangay/cases/:id/edit`.
- Barangay home FAB + case detail edit action; fictional-data banner preserved.
- **Hardened** [`firestore.rules`](../../firestore.rules) vs published baseline (`308d8c2`): field allow-list aligned with [`case_record.schema.json`](../../shared/contracts/case_record.schema.json), create requires `reportStatus == notSubmitted`, update preserves `createdAt` and `reportStatus`.
- Emulator rules tests in [`shared/firestore-rules-test/`](../../shared/firestore-rules-test/).

Follow-up create/edit: **deferred**.

## 3. Security boundary review (`f3a7c219-…`)

| Boundary | Finding |
|----------|---------|
| Rules vs client | Case writes validated in rules independently of Flutter (`caseCoreFieldsValid`, immutability checks). |
| Reports | `reports/*` client create/update/delete **denied**; MOPH read only when `acceptedAt` set and `reportStatus == submitted` (server/function path). |
| Report submission | Clients cannot set case `reportStatus` to `submitted` on create; cannot change `reportStatus` on update. |
| Roles | Teen: no case access. Barangay: case CRUD except delete. MOPH: no case access; reports read-only per existing rule. |
| Demo data | Provisioned fictional cases use `reportStatus: notSubmitted` and schema fields only — compatible with new rules. |
| Sensitive data | No new roles or collections; teen/MOPH case isolation unchanged. |
| Org isolation | **Not implemented.** All active barangay users share the demonstration `cases` namespace. **Production use with real sensitive records is prohibited** until organization-scoped authorization is designed, implemented, and verified. |

### Partial updates and field removal

Firestore merges updates into the stored document; rules validate the **post-write** document. Partial barangay updates to permitted fields do not clear `reportStatus` or `createdAt` (verified by emulator test). Updates that add disallowed keys or violate `hasOnly` are denied. Deletes of required keys via client update are not used by the app; a full-document replace that omitted required fields would be denied by `hasAll`.

## 4. Security test matrix (emulator)

| # | Scenario | Result |
|---|----------|--------|
| 1 | Barangay create valid fictional case | Pass |
| 2 | Barangay update permitted fields (full + partial) | Pass |
| 3 | Teen read/write denied | Pass |
| 4 | MOPH read/create/update on cases denied | Pass |
| 5 | Unauthenticated read/write denied | Pass |
| 6 | Create/update `reportStatus` to non-client states denied | Pass |
| 7 | `createdAt` change denied | Pass |
| 8 | Extra identity/org fields on create/update denied | Pass |
| 9 | Unexpected fields denied | Pass |
| 10 | Case delete denied | Pass |
| 11 | Invalid types, age bounds, `caseStatus` denied | Pass |
| 12 | Barangay read demo-shaped case + follow-up subcollection | Pass |
| — | Barangay/MOPH cannot create `reports` documents | Pass |

**14** automated rules tests (2026-10-21).

## 5. Verification commands and results

### Flutter (`sibol_app/`)

```bash
flutter analyze   # 0 errors, 11 info hints
flutter test      # 46 passed, 0 failed
```

### Firestore rules

```bash
cd shared/firestore-rules-test && npm ci && npm test
# 14 passed, 0 failed (firebase emulators:exec, firestore only)
```

**Live Firebase / Android manual T2-3 writes:** Not performed (not authorized).

## 6. Files changed (implementation + security)

| Area | Paths |
|------|--------|
| Domain | `case_write_policy.dart`, `case_repository.dart` |
| Data | `case_repository_impl.dart`, `case_record_model.dart` |
| UI | `case_edit_screen.dart`, `barangay_home_screen.dart`, `case_detail_screen.dart` |
| Router | `route_constants.dart`, `app_router.dart` |
| Security | `firestore.rules`, `firebase.json`, `shared/firestore-rules-test/*` |
| Tests | `case_write_policy_test.dart`, `case_edit_screen_test.dart`, `app_redirect_test.dart`, `fake_case_repository.dart`, `cases.rules.test.mjs` |
| Docs | This report, [FIRESTORE_RULES_T2_3.md](FIRESTORE_RULES_T2_3.md) |

## 7. Deployment readiness (analysis only — not executed)

See [FIRESTORE_RULES_T2_3.md](FIRESTORE_RULES_T2_3.md) § Deployment readiness.

## 8. Publication record

| Field | Value |
|-------|--------|
| Git commit | *(recorded after push in §9)* |
| Branch | `main` |
| Firebase deploy | **Not performed** |

## 9. Traceability

- Plan: [SIBOL_IMP_002_T2_3_PLAN.md](SIBOL_IMP_002_T2_3_PLAN.md)  
- Assessment: [SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md](SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md)  
- ADR-0003 server reporting boundaries preserved  

## 10. PA disposition

Pending review.
