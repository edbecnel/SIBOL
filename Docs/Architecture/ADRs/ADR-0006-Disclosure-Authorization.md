# ADR-0006: Disclosure authorization for MOPH coordination (SIBOL-CONSENT-REFERRAL-001)

> **Status:** Accepted (implementation)  
> **Date:** 2026-11-01  
**Extends:** [ADR-0005](ADR-0005-Case-Coordination-Minimum-Information.md), SIBOL-CASE-LIFECYCLE-001, SIBOL-CASE-COORD-001

## Context

Barangay–MOPH coordination requires explicit teenager authorization before identifying information is disclosed, while preserving minimum-information referrals and existing coordination threads.

## Decision

1. **`disclosureAuthorizations/{authorizationId}`** — server-written authorization state machine; client read-only under rules.
2. **Structured referral and response payloads** — reject legacy free-text fields (`barangayReferralSummary`, `responseSummary`, `administrativeNote`) on new submissions (PA corrections C1–C3).
3. **`authorizedDisclosure/profile`** subdocument on coordination threads — server-populated category fields only when `disclosureMode == authorized`.
4. **Legal activation gate** — `SIBOL_DISCLOSURE_LEGAL_GATE=true` required for consent-dependent identifying disclosure; default fail-closed.
5. **No general Barangay statutory override** — deferred until separate legal authorization (D5).

## Consequences

- New callables: `regRequestMophDisclosureAuthorization`, `regRecordTeenDisclosureDecision`, `regWithdrawDisclosureAuthorization`.
- Extended `createCoordinationReferral` and `regBarangayRespondToMophInformationRequest`.
- Legacy threads retain historical free-text fields; no silent migration.

## Related

- [CONTRACT-DISCLOSURE-001-Moph-Authorization.md](../../../shared/docs/CONTRACT-DISCLOSURE-001-Moph-Authorization.md)
- [SIBOL_CONSENT_REFERRAL_001_PLAN.md](../../Development/SIBOL_CONSENT_REFERRAL_001_PLAN.md)
