# SIBOL-OFFLINE-REQ-001 — Deferred offline submission cancellation

**Work item:** SIBOL-OFFLINE-REQ-001  
**Status:** **NOT AUTHORIZED** (implementation)  
**Product Owner approval:** **NOT APPROVED**  
**Recorded:** 2026-10-26 (SIBOL-OFFLINE-QA-CLOSE-001)

## Summary

A future enhancement to let staff **cancel a pending offline submission** before it transmits when connectivity returns, while **keeping the work as a draft** for later review or resubmission.

The current prototype already supports seamless offline capture and **automatic transmission on reconnection** for queued Firestore writes (assistance, coordination, cases, follow-ups, aggregate reports).

## Current behavior (accepted prototype)

| Area | Behavior |
|------|----------|
| Offline capture | Firestore persistence + pending-write metadata; UI shows pending / awaiting confirmation where implemented |
| Reconnection | SDK retries queued writes; status transitions when server accepts (e.g. report `submitted`) |
| Cancellation | **Not offered** — user cannot retract a queued write before sync |
| Draft retention after cancel | **Not implemented** |

## Proposed enhancement (requirements only)

1. **Cancel before transmit:** User can cancel a pending offline submission while still offline or before the server confirms it.
2. **Draft preservation:** Cancelled content remains available as a **draft** (editable, not submitted), subject to PA/PO approval of exact UX.
3. **Accurate states:** Distinct, user-visible **queued**, **cancelled**, **confirmed (submitted)**, and **failed** states — no false success.
4. **Urgent referrals:** Coordination / referral paths require **separate safety rules** (e.g. stricter confirm-or-cancel, audit trail) — not the same as aggregate reports or case notes.

## Technical implications (design notes)

| Topic | Implication |
|-------|-------------|
| Firestore queued writes | Pending operations live in the local persistence layer; **retracting** may require `terminate()` / disabling network / explicit write reconciliation — not a single “delete doc” for all flows |
| Idempotency | Assistance and report flows use stable ids (`operationId`, `reportId`); cancellation must not orphan duplicates on retry |
| Callable vs direct write | W1 acknowledgment and some coordination steps use **callables**; cancellation semantics differ from direct `set()` on `cases` or `reports` |
| Rules | Server may reject or accept after local queue; UI must not claim “cancelled on server” without confirmation |
| Draft storage | May need explicit draft documents or local state machine — **not specified** in this record |

## Governance

| Decision | Status |
|----------|--------|
| PO approval to build | **NOT APPROVED** |
| EA implementation handover | **NOT AUTHORIZED** |
| Production deployment | Out of scope |

## Draft Product Owner communication (do not send)

> **Subject:** Optional future improvement — cancel pending offline submissions  
>
> When barangay or teen staff work offline, SIBOL today saves their entries safely and sends them automatically when the connection returns. That behavior passed our offline testing.
>
> We are **not** building this next, but we are recording an idea for later: before an offline submission goes out, staff could **cancel** it if they change their mind, and the app would **keep their work as a draft** so nothing is lost. The screen would clearly show whether something is still waiting to send, cancelled, successfully sent, or failed.
>
> Urgent referrals would need extra care so cancellation cannot hide time-sensitive coordination by mistake.
>
> This would need your explicit approval and a separate agreement before any development after the prototype demonstration period.

**Do not send** this message or contact the PO as part of automated agent work.

## Related

- [SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md](SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md) — O1–O8 acceptance and closure checkpoint  
- [OFFLINE_SYNC_MODEL.md](../../shared/docs/OFFLINE_SYNC_MODEL.md)  
- [ADR-0004](../Architecture/ADRs/ADR-0004-Offline-Sync-and-Common-Core-Boundaries.md)
