# ADR-0004: Offline persistence and common-core boundaries

> **Status:** Accepted  
> **Date:** 2026-10-20

## Context

Weak connectivity is a stated community concern. A future application-neutral common core must not depend on SIBOL-specific models.

## Decision

- Use **Firestore offline persistence** as the initial offline layer (no secondary local DB in Tranche 1).
- Distinguish cache, pending writes, and server confirmation using **snapshot metadata**, not client-authoritative sync flags.
- Keep SIBOL domain models (`Case`, `FollowUp`, barangay/MOPH workflows) inside `sibol_app/features/`.
- Reusable, non-clinical modules (theme, widgets, generic errors, bootstrap) may live in `sibol_app/lib/core` and `shared/contracts` without pregnancy-specific terminology.
- Do **not** create a separate common-core repository or generalized platform during the prototype.

## Consequences

- Full offline UX and reporting pending states are primarily Tranche 2 work; Tranche 1 documents the model and enables persistence.

## Related

- [OFFLINE_SYNC_MODEL.md](../../../shared/docs/OFFLINE_SYNC_MODEL.md)
