# SIBOL-CASE-LIFECYCLE-001 — Implementation specification

**Handover UUID:** `4d81b2f0-6e93-45a7-8c21-f59d0b374e62`  
**Status:** Implemented (emulator scope); functional acceptance requires PA manual walkthrough  
**Plan reference:** `case_lifecycle_001_55c207e8.plan.md`  
**Isolation:** `demo-sibol-emulator` (canonical) / `demo-sibol-coord-fn` (isolated Functions test harness)

## Objective

Deliver an auditable Barangay case lifecycle bound to acknowledged teen assistance requests, hospital-scoped MOPH coordination status, Barangay responses to information requests, append-only lifecycle audit, and fail-closed local emulator isolation—without production Firebase contact.

## PA decisions (D1–D5)

| ID | Requirement |
|----|-------------|
| D1 | Referral destination fixed `hospital01` at create |
| D2 | Reopen `closed` → `inProgress` with mandatory `reopenReason` + audit |
| D3 | Close blocked while linked referral has non-terminal `coordinationStatus` |
| D4 | Terminal referral status does not auto-close Barangay case |
| D5 | Offline follow-ups preserved; lifecycle/coordination callables online-only in UI |

## Data contracts

| Path | Writer | Purpose |
|------|--------|---------|
| `assistanceCaseBindings/{assistanceRequestId}` | Admin SDK | Atomic one-case-per-assistance lock |
| `cases/{caseId}` | Admin SDK + rules-limited client fields | Case record with `assistanceRequestId`, lifecycle status |
| `cases/{caseId}/lifecycleEvents/{eventId}` | Admin SDK only | Append-only audit |
| `caseCoordinationThreads/{threadId}` | Admin SDK | `targetHospitalOrgId`, `coordinationStatus` |
| `caseOpenIdempotency/...` | Admin SDK | Per-user open-case idempotency |

## Callable surface

| Callable | Role |
|----------|------|
| `regOpenBarangayCaseFromAssistance` | Barangay — open case from acknowledged assistance |
| `regTransitionBarangayCaseStatus` | Barangay — lifecycle transitions |
| `regUpdateMophCoordinationStatus` | MOPH — hospital-scoped status |
| `regBarangayRespondToMophInformationRequest` | Barangay — respond when information requested |
| `createCoordinationReferral` | Barangay — referral (extended with coordination fields) |

## Flutter surfaces

| Surface | Path |
|---------|------|
| Open case from incoming request | `BarangayIncomingRequestDetailScreen` + `BarangayOpenCaseFromAssistanceAction` |
| Lifecycle actions | `CaseLifecyclePanel` on assistance-linked case detail |
| MOPH status | `MophCoordinationStatusPanel` |
| Barangay info response | `BarangayCoordinationResponsePanel` on submitted referral detail |

## Verification artifacts

| Artifact | Location |
|----------|----------|
| Integration tests | `shared/functions/test/openBarangayCaseFromAssistance.test.mjs`, `transitionBarangayCaseStatus.test.mjs`, `case_lifecycle_flow.test.mjs` |
| Test runner | `shared/functions/scripts/run-case-lifecycle-integration-tests.mjs` |
| Verification matrix | [MVR-CASE-LIFECYCLE-001](../Verification/Records/MVR-CASE-LIFECYCLE-001-Verification-Matrix.md) |
| Emulator walkthrough | [SIBOL_CASE_LIFECYCLE_001_EMULATOR_WALKTHROUGH.md](./SIBOL_CASE_LIFECYCLE_001_EMULATOR_WALKTHROUGH.md) |
| Implementation log | [SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md](./SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md) |

## Out of scope (this work item)

- Production deploy to `sibol-286d0`
- Demonstration phone installs
- Multi-hospital picker (D1 deferral)
- Force-close override (D3)
