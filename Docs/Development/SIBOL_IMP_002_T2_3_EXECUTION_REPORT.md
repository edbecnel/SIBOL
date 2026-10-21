# SIBOL-IMP-002 T2-3 — Execution report (case create/edit)

> **Implementation handover:** `b72d5c94-13f6-4a82-9e05-8c6f241da739`  
> **Security verification & publication handover:** `f3a7c219-6b48-4e91-8d35-20c6f74ab582`  
> **Rules deployment handover:** `a4e71d39-2c86-4b05-91f3-6d80a2e47c19`  
> **Phase:** T2-3 — case creation and editing  
> **Date:** 2026-10-21  
> **Firestore rules deploy:** **Executed** on `sibol-286d0` (rules only)  
> **Live Firestore writes (case create/edit QA):** **Not authorized**  
> **PA acceptance:** Pending

## 1. PA authorization

| Handover | Scope |
|----------|--------|
| `b72d5c94-…` | Local T2-3 implementation and emulator verification |
| `f3a7c219-…` | Security verification, EDF updates, conditional Git publication |
| `a4e71d39-…` | Controlled Firestore **rules** deploy + read-only verification; Android QA prep |

T2-4+ and **live case create/edit QA** require separate handover.

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

## 7. Firestore rules deployment (`a4e71d39-…`)

### Predeployment (2026-10-21)

| Check | Result |
|-------|--------|
| Active Firebase project | `sibol-286d0` (`firebase use sibol-286d0`) |
| Git HEAD | `f1f7c76`; working tree clean at deploy start |
| Rollback artifact | [`Docs/Verification/Artifacts/firestore.rules.pre-t2-3-deploy-2026-10-21.rules`](../Verification/Artifacts/firestore.rules.pre-t2-3-deploy-2026-10-21.rules) (ruleset `276bb8c1-a3ac-403f-82ed-2075519eaa77`, retrieved via Rules API — not assumed from Git) |
| Live vs proposed diff | Pre-deploy lacked `caseCoreFieldsValid` / case write constraints; proposed matches repo `firestore.rules` |
| Emulator parity | `shared/firestore-rules-test` reads repo `firestore.rules`; **14/14** pass immediately before deploy |
| Deploy scope | `--only firestore:rules` (no functions, indexes, auth, or data changes) |
| Demo cases readable (expectation) | Provisioned `demo-case-001`…`005` schema-compatible |

### Deploy

```bash
firebase deploy --only firestore:rules --project sibol-286d0
```

| Result | **Success** — `✔ firestore: released rules firestore.rules to cloud.firestore` |
| Post-deploy ruleset | `projects/sibol-286d0/rulesets/3f65a5f3-19c1-4134-98d3-d5e420864afc` |
| Content vs repo | **Byte-identical** to `firestore.rules` at `f1f7c76` |
| Metadata | [`firestore.rules.post-t2-3-deploy-2026-10-21.metadata.json`](../Verification/Artifacts/firestore.rules.post-t2-3-deploy-2026-10-21.metadata.json) |

### Post-deploy read-only verification

| Check | Method | Result |
|-------|--------|--------|
| Project | CLI / API | `sibol-286d0` |
| Deployed rules match reviewed file | Rules API body vs repo | **Match** |
| `demo-case-001`…`005` present | Firestore REST `GET` (Cloud IAM; **not** security-rules simulation) | **HTTP 200** each |
| Follow-ups on `demo-case-002` | REST list subcollection | **1** document |
| Barangay rules-enforced reads | Firebase Auth + client SDK | **Not run** — `SIBOL_DEMO_PASSWORD_*` not available in EA environment |
| Teen/MOPH deny (rules-enforced) | Client SDK | **Not run** (same constraint) |

No create, update, or delete operations were performed on live Firestore during this handover.

Rollback: [Artifacts README](../Verification/Artifacts/README.md).

Android manual QA (including live writes when authorized): [MVR-0002](../Verification/Records/MVR-0002-t2-3-android-case-writes.md).

## 8. Publication record

| Field | Value |
|-------|--------|
| Git commit | `41272a5` on `main` |
| Push | `origin/main` (handover `f3a7c219-…`) |
| Rules deploy | 2026-10-21 (`a4e71d39-…`) |

## 9. Traceability

- Plan: [SIBOL_IMP_002_T2_3_PLAN.md](SIBOL_IMP_002_T2_3_PLAN.md)  
- Assessment: [SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md](SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md)  
- ADR-0003 server reporting boundaries preserved  

## 10. PA disposition

Pending review.
