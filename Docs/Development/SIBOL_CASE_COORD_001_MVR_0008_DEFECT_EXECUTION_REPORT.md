# SIBOL-CASE-COORD-001 — MVR-0008 defect execution report

> **Handover UUID:** `e4c7a219-8b63-4d91-a052-6f39c1e8d705`  
> **Date:** 2026-10-24  
> **Git baseline (start):** `6a3cc6043e0c819de181968e6a48ea4df0e3d274`  
> **Firebase deployment:** **NO**  
> **Increment C:** **NO**

## 1. Root cause

The referral action on `BarangayIncomingRequestDetailScreen` depends on `assistanceReferralExistsProvider`, which listens to `barangayCoordinationRegistry/{assistanceRequestId}`.

**Live Firestore rules (Increment A, deployed)** allowed registry **read** only when `resource.data.barangay` matched the barangay user. For a **non-existent** registry document (no referral yet), `resource` is null, the rule fails, and the client receives **`permission-denied`**.

The detail screen handled `loading` and `error` on that provider with `SizedBox.shrink()`, so the **Refer to MOPH coordination** button never appeared even when the request was **Acknowledged**.

| Layer | Reference |
|-------|-----------|
| UI (silent hide) | `sibol_app/lib/features/teenager/presentation/screens/barangay_incoming_request_detail_screen.dart` (pre-fix) |
| Provider | `sibol_app/lib/features/coordination/presentation/providers/coordination_providers.dart` |
| Repository listen | `sibol_app/lib/features/coordination/data/repositories/coordination_repository_impl.dart` |
| Rules | `firestore.rules` — `barangayCanReadCoordinationRegistry` (pre-fix) |

Acknowledgment status and routing were **correct**; the defect was not a wrong screen or status enum.

## 2. Corrective change

1. **Client (works on live rules without deploy):** Map registry snapshot `permission-denied` to “no referral yet” in `coordination_registry_referral_probe.dart`; repository uses this stream transformer. Duplicate referrals remain blocked by `createCoordinationReferral`.
2. **UI:** Extract `BarangayMophReferralAction` — show loading state on the button, surface eligibility errors via `AppErrorWidget` instead of hiding the action.
3. **Rules (repo only; deploy when PA authorizes):** Allow barangay registry read when the barangay owns the linked `teenAssistanceRequests/{id}` and either the registry doc is missing or `barangay` matches.

## 3. Tests added

| Test file | Coverage |
|-----------|----------|
| `test/coordination_registry_referral_probe_test.dart` | Stream mapping; permission-denied → false |
| `test/barangay_moph_referral_action_test.dart` | All five MVR-0008 Flutter scenarios |

## 4. Verification

| Command | Result |
|---------|--------|
| `cd sibol_app && flutter test` | **69/69** pass |
| `cd sibol_app && flutter analyze` | 0 errors |
| `shared/firestore-rules-test` (coordination suite on emulator) | **24/24** pass in coordination file; full suite **60/60** when port 8195 available |
| `cd shared/functions && npm test` | **9/9** pass (unchanged) |

## 5. MVR-0008

Operator live retest **not** performed by EA. [MVR-0008](../Verification/Records/MVR-0008-case-coord-001-increment-b-referral-live.md) remains **blocked** pending PA/operator sign-off.

## 6. PA acceptance

Pending review.
