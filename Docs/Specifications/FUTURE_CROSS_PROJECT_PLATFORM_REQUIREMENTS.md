# Future cross-project platform requirements (tracked — not authorized)

> **Status:** Requirements traceability only  
> **Last updated:** 2026-10-21  
> **Introduced:** SIBOL-IMP-002 T2-2 handover `b6f7e29a-4d13-4d8c-9e25-7c1a08d5f632`  
> **Implementation:** **Not authorized** in current tranches

This document records architectural objectives for SIBOL and SpeakUp Connect. It does **not** authorize implementation, SpeakUp Connect changes, or shared-library extraction.

## A. Administrator-configurable approval workflows

- Organization-scoped configuration.
- Configurable reviewer authority (provisional default: MOPH reviews Barangay submissions — subject to product-owner confirmation before live deployment).
- Server-enforced authorization.
- Acceptance and rejection handling; mandatory rejection explanations.
- Auditable approval and configuration changes.
- Administrative UI without code redeploy for policy changes.

**Traceability:** ADR-0003, [REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md), [SIBOL_IMP_002_PLAN.md](../Development/SIBOL_IMP_002_PLAN.md).

## B. Emergency escalation (safeguarding)

- Configurable emergency classifications and routing.
- Escalation independent of routine administrative approval.
- Authorized responder designation.
- Priority notifications and acknowledgment tracking.
- Backup escalation when acknowledgment is not received.
- Least-privilege information disclosure.
- Auditable escalation history.
- Safe handling of notification failures.

**Gate:** Detailed procedures require safeguarding stakeholder confirmation before deployment.

## C. Cross-project organizational reporting architecture

Reusable foundation goals (future extraction):

- Multiple organization types and relationships (municipality, barangay, university, DepEd, school).
- Multiple report categories.
- Organization-scoped permissions and policies.
- Configurable approval and escalation workflows.
- Specialized confidentiality controls for minor-related sensitive data.
- Subsequent SpeakUp Connect adoption without duplicating incompatible infrastructure.

## D. Future architecture assessment gate (pre T2-3+)

Before case create/edit (T2-3) or reporting workflow phases, PA review of a focused **SIBOL vs SpeakUp Connect** comparison:

- Existing models, services, permissions, reporting workflows.
- Reusable functionality vs gaps.
- Risks of duplicating incompatible infrastructure.

**Not permission** to modify SpeakUp Connect.

## Related

- [CASE_AND_REPORTING_MODEL.md](CASE_AND_REPORTING_MODEL.md)
- [OFFLINE_SYNC_MODEL.md](../../shared/docs/OFFLINE_SYNC_MODEL.md)
- [SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md](../Development/SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md)
- [SIBOL_IMP_002_T2_3_PLAN.md](../Development/SIBOL_IMP_002_T2_3_PLAN.md)
