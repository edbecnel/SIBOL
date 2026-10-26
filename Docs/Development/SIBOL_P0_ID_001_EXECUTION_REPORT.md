# SIBOL-P0-ID-001 — Teenager request identity (execution report)

**Handover:** `e9b73c14-5d62-4a81-9f20-c638b2d70451`  
**Work item:** SIBOL-P0-ID-001  
**Status:** Implemented — **manual QA NOT RUN** (pending PA)  
**Baseline:** `main` @ implementation commit (see Git section)

## Problem

Barangay assistance request detail showed routing metadata but not the submitting teenager’s display name or account email, although each request already stored a server-trusted `teenUid`.

## Architectural decision (PO-approved)

Hybrid identity retrieval:

1. **Offline-readable snapshot** on `teenAssistanceRequests`: `submitterDisplayName`, `submitterAccountEmail` (server-written only).
2. **Online refresh** via callable `regResolveAssistanceRequestSubmitter` when authorized Barangay staff open a request; updates snapshot when authoritative values differ.
3. No widening of `users/{uid}` read rules; no teen identity on MOPH referral documents.

## Backend

| Component | Behavior |
|-----------|----------|
| `runSubmitTeenAssistanceRequest` | Resolves identity from `users/{teenUid}` + Firebase Auth email; stores optional snapshot fields on create. |
| `runResolveAssistanceRequestSubmitter` | Barangay + `coordination.barangay` on request `orgId`; derives `teenUid` from request; returns identity; updates snapshot fields only when changed. |
| `regResolveAssistanceRequestSubmitter` | Callable export in `shared/functions/src/index.ts`. |

Shared helpers: `shared/functions/src/teen/submitterIdentity.ts`.

## Firestore rules

`assistanceRequestAcknowledgeUpdate` extended so client acknowledge updates cannot add or change `submitterDisplayName` / `submitterAccountEmail`. Assistance document **create** remains server-only.

## Flutter

- Model/entity parse snapshot fields.
- [`barangay_incoming_request_detail_screen.dart`](../../sibol_app/lib/features/teenager/presentation/screens/barangay_incoming_request_detail_screen.dart): shows **Submitted by** and **Account email** from cache; schedules a single online refresh per screen open (no rebuild loop).
- Inbox list unchanged.

Display helpers: `assistance_request_submitter_identity.dart`.

## Legacy / demo data

No bulk backfill or emulator reseed. Opening a legacy request online runs the resolve callable, which populates missing snapshot fields when authorized.

## Offline and privacy

- Identity rides existing Firestore persistence on the assistance document.
- **Limitation:** Cached request documents on a disconnected device are not automatically revoked when server authorization changes (documented in [TEEN_ASSISTANCE_IDENTITY_CONTRACT.md](../../shared/docs/TEEN_ASSISTANCE_IDENTITY_CONTRACT.md)).

## Automated verification

| Suite | Command | Result |
|-------|---------|--------|
| Functions | `cd shared/functions && npm test` | **87** integration + **6** authz unit — pass |
| Firestore rules | `cd shared/firestore-rules-test && npm test` | **121** — pass |
| Flutter | `cd sibol_app && flutter test` | **189** — pass |

Gate B: No live emulator mutation of accepted QA seed data during automated tests (isolated emulator projects only).

## Manual QA (pending PA)

1. Sign in as Barangay staff with `coordination.barangay` on demo org; open **Incoming requests** → detail for `demo-assist-inbox-001` (or any legacy request) **online**.  
   **Expected:** After brief load, **Submitted by** and **Account email** populate (via refresh); not raw UID.
2. Repeat **offline** after step 1 succeeded once.  
   **Expected:** Cached identity still shown; ack/referral still available.
3. Teen submits **new** assistance request online; Barangay opens detail.  
   **Expected:** Identity visible from snapshot without requiring refresh (refresh may still run harmlessly).
4. Sign in as MOPH-only user — confirm no assistance inbox / no resolve path (unchanged product surface).

## Git

Recorded at commit time in handover completion message.

## Related

- [TEEN_ASSISTANCE_IDENTITY_CONTRACT.md](../../shared/docs/TEEN_ASSISTANCE_IDENTITY_CONTRACT.md)
- [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md)
