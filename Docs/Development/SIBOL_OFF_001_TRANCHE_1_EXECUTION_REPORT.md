# SIBOL-OFF-001 — Tranche 1 execution report

**Baseline:** `c459b0e`  
**Scope:** Acknowledgment idempotency (OFF-002), sign-out pending guard (OFF-001), sync classification, queue retention.

## Reliability defects corrected

| Defect | Fix |
|--------|-----|
| Barangay ack replay treated generic errors as retryable | Server idempotent `regAcknowledgeTeenAssistanceRequest`; client maps `acknowledgment-conflict` to terminal `conflict` |
| “Already acknowledged” string could imply success for a different pending op | Server distinguishes same idempotency key replay vs duplicate op vs other actor |
| Sync could run without matching authenticated UID | `OfflineSyncService` gates enqueue, `pendingForUser`, `syncForUser`, and `processOperation` on `FirebaseAuth.currentUser` |
| Sign-out with unsynced work had no warning | `confirmSignOutIfPendingOperations` on Settings, Unauthorized, Account not provisioned, Teen registration |
| Terminal pending records unbounded | `pruneTerminalPendingOperations` (max 25 terminal per user); unresolved always kept |

## Automated verification

| Suite | Result |
|-------|--------|
| `sibol_app` `flutter test` | **134/134 PASS** |
| `shared/functions` integration (isolated emulator **8226**) | **70/70 PASS** (includes `acknowledge_assistance.test.mjs`) |
| `shared/firestore-rules-test` | **Not re-run** (rules delta: deny client access to `assistanceAcknowledgmentIdempotency`; deploy not authorized) |

## Deployment

**Not authorized.** Callable `regAcknowledgeTeenAssistanceRequest` is implemented and tested locally only. Production/emulator QA stacks must deploy Functions + rules before the app uses the new ack path against those hosts.

## Remaining risks

- Online barangay ack now requires Functions emulator/deploy with the new export (same as teen submit).
- Device MVR O-03/O-06 still not operator-attested; behavior covered by unit/integration tests.
- `connectivity_plus` link-only “online” detection unchanged (out of tranche scope).

## Product Owner acceptance

**Not required** for this tranche if PO relies on automated regression and does not need to exercise offline ack on device. A **short** check is optional: sign out with a queued action → confirm warning → sign back in → retry sync (no full Teen→MOPH re-walk).

## Next prototype priority

Wire global `OfflineStatusBanner` and MVR-OFFLINE-001 device attestation when PO time allows; otherwise continue Tranche 2 reporting gate work per PA handover.
