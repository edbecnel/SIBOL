# ADR-REG-003 — Organization identifier policy

> **Status:** Proposed (INT-001-AMEND-001) — **not self-approved**  
> **Handover UUID:** `e4b7c291-5a63-4d08-9f12-6c83a0e745bd`  
> **Supersedes:** Fixed `org` + 22-character identifier convention in ADR-REG-001 / REG-A implementation notes

## Context

Organization names and types change; authorization must not depend on display strings. Earlier repository conventions used a fixed-length `org` prefix identifier. Demonstration and operator clarity require short, stable demo identifiers while production organizations use server-generated Firestore document IDs.

## Decision

1. **Immutable `orgId`** — Stored as the Firestore `organizations/{orgId}` document id and on all scoped records. Names and types are separate fields.
2. **Validation** — Alphanumeric plus `_` and `-`; 1–128 characters; no `/`; no `__`; case-sensitive. Implemented in `shared/reg/src/org_id.mjs`, Cloud Functions, Firestore rules, and Flutter `OrgContextResolver`.
3. **Creation** — Central Administrator `runCreateOrganization` generates a collision-resistant 20-character id (`generateOrgId`). Clients cannot supply arbitrary org ids through privileged APIs.
4. **Demonstration** — Canonical ids: `barangay03` (Barangay Tres), `hospital01` (Misamis Oriental Provincial Hospital).
5. **Membership** — Unchanged: `mbr_{orgId}__{accountUid}` with the same `orgId` validation on the org segment.

## Consequences

- Migration mapping files must list explicit label → `orgId` pairs (no name inference).
- Historical EDF references to `^org[0-9A-Za-z]{22}$` describe the superseded REG-A convention; active code follows this ADR once accepted.

## Security

An organization id is not a credential. Access remains membership- and capability-based (REG-A/M2 invariants unchanged).
