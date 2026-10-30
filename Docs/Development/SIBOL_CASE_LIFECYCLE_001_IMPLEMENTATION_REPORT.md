# SIBOL-CASE-LIFECYCLE-001 — Implementation & Verification Record

**Work item:** SIBOL-CASE-LIFECYCLE-001  
**Handover UUID (resumption):** `d82a7f31-4c69-45e0-9b13-6f72c5e408ad`  
**Branch:** `main`  
**Isolation baseline:** SIBOL-FIREBASE-ISOLATION-001 **COMPLETE—VERIFIED** (closeout `9ef6f69`)  
**Classification:** **IN PROGRESS — FUNCTIONAL ACCEPTANCE NOT CLAIMED**

## Preconditions satisfied

| Gate | Result |
|------|--------|
| Isolation closeout (startup + health script) | Committed `9ef6f69` |
| Runtime isolation gate | Pass (`validate-local-firebase-isolation.sh`, INT-001 preflight, ports/callables; QA anchors excluded per PA) |
| Conditional CASE-LIFECYCLE hold release | **Granted** for local implementation + emulator-only focused tests |

## Work packages (plan traceability)

| WP | Status | Notes |
|----|--------|-------|
| WP-A / A6 | Partial | Contracts in code + rules; full SPEC/WORK_ITEM_REGISTER docs pending |
| WP-B | Done (uncommitted) | MOPH inbox index; binding collection rules |
| WP-C | Done (uncommitted) | Open case, transition, MOPH status, Barangay info response callables |
| WP-D | Done (uncommitted) | Client deny lifecycle/linkage; lifecycleEvents server-only; hospital-scoped MOPH reads |
| WP-E/F | Partial | Data layer + lifecycle/coordination UI; **missing** incoming-request “Open case” entry (WP-F gap) |
| WP-G | Partial | Focused lifecycle integration tests added; full rules suite / concurrent-open stress not run |
| WP-H | Not started | Manual E2E on canonical emulators; acceptance report pending |

## Focused automated tests (emulator-only)

Runner: `shared/functions/scripts/run-case-lifecycle-integration-tests.mjs`  
Harness: `firebase emulators:exec` on `firebase.emulator-functions-test.json` (ports 8226/8227), project `demo-sibol-coord-fn` (non-production).

Preflight in tests: `assertFunctionsIntegrationEmulatorEnv()` — local hosts, rejects `sibol-286d0`, allows `demo-sibol-*` test projects.

**Last run:** 4/4 pass — `openBarangayCaseFromAssistance.test.mjs`, `transitionBarangayCaseStatus.test.mjs` (after commit `c3d247d`, runner `node shared/functions/scripts/run-case-lifecycle-integration-tests.mjs`).

**Git milestones on `main`:** `9ef6f69` isolation closeout · `c3d247d` functions/rules/tests · `67e8dc9` Flutter lifecycle UI (iOS Podfile/SwiftPM WIP excluded).

## Blocked / not executed

- **Demo seed:** QA anchor health and INT-001 demo flows remain blocked on empty canonical emulator (no seed authorized).
- **Full functions integration suite:** Not re-run in this tranche (guard audit: legacy tests check `FIRESTORE_EMULATOR_HOST` only; lifecycle runner uses production-id rejection + dedicated ports).
- **Manual phone / production E2E:** Out of scope.
- **Concurrent open-case stress test:** Planned in WP-G; not yet implemented.

## Production protection

No production deploy, no production Firestore/Auth operations, no device installs during this tranche.

## Manual acceptance still required (WP-H)

1. Canonical emulators + acknowledged assistance → open case from Barangay UI (once wired on incoming request detail).
2. Lifecycle transitions (open → inProgress → resolved/closed) with coordination block on close.
3. MOPH status update + Barangay information response on emulator data.
4. PA sign-off — **do not** infer from automated tests alone.
