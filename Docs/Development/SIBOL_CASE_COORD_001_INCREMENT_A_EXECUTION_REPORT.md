# SIBOL-CASE-COORD-001 — Increment A execution report

> **Handover UUID:** `a2c8d471-9f36-4e0b-b751-6d23f8a94c10`  
> **Date:** 2026-10-24  
> **Increment:** A — Secure Coordination Foundation  
> **Firebase deployed:** **YES** — see [SIBOL_CASE_COORD_001_INCREMENT_A_FIREBASE_DEPLOY_EXECUTION_REPORT.md](SIBOL_CASE_COORD_001_INCREMENT_A_FIREBASE_DEPLOY_EXECUTION_REPORT.md) (handover `c6a8e231-…`, 2026-10-24)

## 1. PA authorization

Increment A: rules, indexes, rules tests, Dart path constants, EDF docs, callable **contract only**. No Functions implementation, no Flutter UI, no Firebase deploy.

## 2. Implementation summary

| Area | Result |
|------|--------|
| [`firestore.rules`](../../firestore.rules) | Coordination `match` blocks; **all client creates/updates denied** on coordination paths |
| [`firestore.indexes.json`](../../firestore.indexes.json) | Three composite indexes for MOPH/barangay coordination queries |
| [`firestore_paths.dart`](../../sibol_app/lib/core/constants/firestore_paths.dart) | Path constants |
| Rules tests | [`case_coordination.rules.test.mjs`](../../shared/firestore-rules-test/test/case_coordination.rules.test.mjs) — 23 scenarios |
| Callable | [`COORDINATION_REFERRAL_CONTRACT.md`](../../shared/docs/COORDINATION_REFERRAL_CONTRACT.md) — not implemented |
| ADR | [ADR-0005](../Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md) |

## 3. Security boundaries

- MOPH: read thread headers (valid `phase`) and `staffEvents`; **denied** `private/binding`, registry, teen assistance, teen progress links.
- Barangay: read threads/registry/binding in assigned barangay; **no** client writes.
- Teen: read own `teenCoordinationLinks` only; **denied** staff coordination paths.

## 4. Staff event / phase consistency (Increment A limitation)

Client writes for `staffEvents` and header `phase` are **denied**. Rules cannot yet enforce event+phase atomicity for clients. **Increment C** must add constrained create/update rules or callables; see plan § Increment C.

## 5. Registry uniqueness (v1)

Document id = `assistanceRequestId`. Callable contract rejects create when registry document already exists (including `active: false`) to prevent accidental duplicate referral on the same assistance request without deleting history.

## 6. Verification

```bash
cd shared/firestore-rules-test && npm test
```

| Result | Detail |
|--------|--------|
| **59/59** pass | 36 legacy + 23 coordination (2026-10-24) |
| `flutter analyze` | Run on `sibol_app` after path constant change (see §7) |

## 7. Flutter analyze

`cd sibol_app && flutter analyze` — path constants only; no feature code.

## 8. Deployment readiness

[SIBOL_CASE_COORD_001_INCREMENT_A_DEPLOY_READINESS.md](SIBOL_CASE_COORD_001_INCREMENT_A_DEPLOY_READINESS.md)

## 9. PA acceptance

Pending PA review. Increment B **not** started.

## 10. Git publication

Recorded after commit (handover §5).
