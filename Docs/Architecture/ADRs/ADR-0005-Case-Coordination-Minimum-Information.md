# ADR-0005: Case coordination minimum-information boundary (DEC-CASE-001)

> **Status:** Accepted  
> **Date:** 2026-10-24  
> **Work item:** SIBOL-CASE-COORD-001 Increment A  
> **Handover:** `a2c8d471-9f36-4e0b-b751-6d23f8a94c10`

## Context

Barangay and MOPH must coordinate on individual adolescent assistance cases without granting MOPH unrestricted access to Teen profiles, Firebase Auth identifiers, or original Teen assistance narratives. Firestore Security Rules grant **document-level** read access; field-level redaction is not reliable.

## Decision

1. **Document-path separation** for coordination data:
   - `caseCoordinationThreads/{threadId}` — MOPH-visible header (category, barangay-prepared summary, opaque `displayRef`, phase, timestamps). **No** `teenUid`, teen name, contact, or teen `description`.
   - `caseCoordinationThreads/{threadId}/private/binding` — `teenUid` and `assistanceRequestId`; **barangay read only**; MOPH denied.
   - `caseCoordinationThreads/{threadId}/staffEvents/{eventId}` — staff coordination messages; teen denied; MOPH and barangay read (scoped).
   - `barangayCoordinationRegistry/{assistanceRequestId}` — one registry row per assistance request id (history retained; `active` flag); barangay only.
   - `teenCoordinationLinks/{teenUid}/links/{assistanceRequestId}` — generic teen-visible progress; teen read own path only.

2. **Referral creation** is **not** client-writable; `createCoordinationReferral` callable (Increment B) performs atomic creation with Admin SDK.

3. **Staff events and phase transitions** are **not** client-writable in Increment A; Increment C will add constrained rules or callables.

4. **De-identification limit:** Rules enforce **schema** boundaries, not semantic review of free text. Operators must not place identifying information in MOPH-visible fields; PO authorization required for any expanded sharing.

## Consequences

- New composite indexes and rules tests in repository; **not deployed** until PA authorizes Firebase deploy.
- Teen assistance and aggregate reporting paths unchanged.

## Related

- [COORDINATION_REFERRAL_CONTRACT.md](../../../shared/docs/COORDINATION_REFERRAL_CONTRACT.md)
- [SIBOL_CASE_COORD_001_PLAN.md](../../Development/SIBOL_CASE_COORD_001_PLAN.md)
- [`firestore.rules`](../../../firestore.rules)
