# ADR-0003: Three-role authorization and server-authoritative reporting

> **Status:** Accepted  
> **Date:** 2026-10-20

## Context

The prototype has three roles (`teen`, `barangay`, `moph`). MOPH must not see unsubmitted barangay data. Users must not self-elevate privileges.

## Decision

- Store roles in `users/{uid}` with fields `role`, `displayName`, `active`, `createdAt`.
- Provision roles via **trusted Admin SDK seed** (or future admin tooling), not self-registration.
- Enforce **deny-by-default** Firestore Security Rules independent of Flutter routing.
- **Teen:** no access to `cases/*`.
- **Barangay:** CRUD on `cases/*` and `followUps/*`.
- **MOPH:** read only `reports/*` where server set `reportStatus == submitted` and `acceptedAt` is present.
- **Reporting acceptance** is performed by a **callable Cloud Function** (Tranche 2); clients cannot mark reports as received by MOPH.

## Consequences

- `submitReport` stub documented in Tranche 1; implementation deferred to Tranche 2.

## Related

- [`firestore.rules`](../../../firestore.rules)
- [REPORTING_CONTRACT.md](../../../shared/docs/REPORTING_CONTRACT.md)

## Successor architecture (not yet implemented)

Registration and organization-scoped authorization are specified in [SPEC-REG-001](../../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md) and [ADR-REG-001](ADR-REG-001-Organization-Identity-and-Membership.md) / [ADR-REG-002](ADR-REG-002-Administrative-Authorization-and-Provisioning.md). **This ADR remains authoritative for current demo behavior** on `sibol-286d0` until REG rules and services are deployed and verified (MVR-REG-001).
