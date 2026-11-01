# ADR-0007: COMM-ORD-1 strict workflow ordering (SIBOL-COMM-WORKFLOW-001)

> **Status:** Accepted  
> **Date:** 2026-11-01  
**Supersedes (partial):** PO decision **D1** in [SIBOL_CONSENT_REFERRAL_001_PLAN.md](../../Development/SIBOL_CONSENT_REFERRAL_001_PLAN.md) that allowed case opening after acknowledgment without MOPH `received`.

## Context

The infographic and Product Owner approval **COMM-ORD-1** require: assistance → acknowledgment → disclosure (when applicable) → referral → MOPH receipt → **then** formal case opening.

## Decision

1. **`regOpenBarangayCaseFromAssistance`** enforces: acknowledged assistance, existing `barangayCoordinationRegistry` entry, and coordination status in post-receipt states (not `submitted`).
2. **Legacy cases** opened before this rule remain valid via idempotent binding returns; no retroactive invalidation.
3. **UI** explains blocking reasons; server remains authoritative.

## Consequences

- Emulator walkthroughs and device tests follow infographic order 4a → 4b → 5.
- `cases.coordinationThreadId` and thread `caseId` link on successful open (COMM-LINK-1).

## Related

- [SIBOL-COMM-WORKFLOW-001 execution report](../../Development/SIBOL_COMM_WORKFLOW_001_EXECUTION_REPORT.md)
