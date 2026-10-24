# SIBOL-CASE-COORD-001 — Implementation plan

> **Handovers:** `4e9a6c82-…`, `b7d42e91-…`, **`a2c8d471-9f36-4e0b-b751-6d23f8a94c10`** (Increment A)  
> **Decision:** DEC-CASE-001 — minimum-information MOPH referral  
> **Architecture:** [ADR-0005](../Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md)

## Objective

Individual Teen assistance coordination between Barangay and MOPH while preserving v0.5.0 teen assistance, barangay cases, and immutable aggregate reports.

## Firestore paths

See ADR-0005 and [`firestore_paths.dart`](../../sibol_app/lib/core/constants/firestore_paths.dart).

## Phases

| Increment | Scope | Operational? |
|-----------|--------|----------------|
| **A** | Rules, indexes, rules tests, callable contract | **Read paths only** in production until deploy |
| **B** | `createCoordinationReferral` + Barangay/MOPH UI | **Implemented in repo** — Functions deploy pending |
| **C** | Staff events + phase transitions | Two-way coordination |
| **D** | Teen generic progress UI | Teen visibility |

## Workflow (durable phases)

`referred` → `awaitingBarangay` ↔ `awaitingMoph` → `closed`. Event history in `staffEvents` (append-only).

## Constraints (approved)

- Acknowledge before referral.
- One registry entry per `assistanceRequestId` (document retained; v1 no duplicate referral on same id).
- No MOPH access to teen assistance or private bindings.

## Callable

[COORDINATION_REFERRAL_CONTRACT.md](../../shared/docs/COORDINATION_REFERRAL_CONTRACT.md) — implementation in Increment B.

## Deployment

Rules/indexes changes are **local until PA authorizes Firebase deploy** — see [SIBOL_CASE_COORD_001_INCREMENT_A_DEPLOY_READINESS.md](SIBOL_CASE_COORD_001_INCREMENT_A_DEPLOY_READINESS.md).
