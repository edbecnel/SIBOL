# SIBOL-CASE-COORD-001 — Barangay submitted referral history (B-HISTORY)

> **Requirement ID:** SIBOL-CASE-COORD-001-B-HISTORY  
> **Priority:** Required (PA addendum)  
> **Status:** **Implemented in repo** (handover `a4e9c2d7-…`); operator MVR-0009 pending  
> **Authorization:** Implementation authorized; **no Firebase deploy**; **not Increment C**

## 1. PA requirement summary

Barangay personnel must browse and review **referrals previously submitted by their barangay**, including **active and closed** threads, with authorized header fields and **chronological staff-event history**, minimum-information privacy, and no cross-barangay access.

## 2. Increment B gap analysis (inspection)

| Capability | Present in Increment B? | Notes |
|------------|-------------------------|--------|
| Dashboard entry **Submitted Referrals** | **No** | Dashboard has Incoming requests, Submit report, **Submitted reports** (aggregate `reports` — different domain). |
| Barangay list of coordination threads | **No** | Only MOPH `watchOpenThreadsForMoph()` (open phases only). |
| Barangay referral **detail** + staff events | **No dedicated screen** | Rules allow barangay read of `caseCoordinationThreads/{id}` and `staffEvents` for own `barangay`; no Flutter route. |
| Submit referral (create) | **Yes** | `BarangayCoordinationReferralScreen`, callable `createCoordinationReferral`. |
| Per-request “already referred” on assistance detail | **Yes** | Registry probe + copy on detail. |
| MOPH inbox + detail | **Yes** | Reusable `CoordinationThreadDetailBody` (no teen uid / original teen text). |
| Closed phase in data model | **Yes** | `CoordinationPhase.closed`; barangay header read not limited to open phases. |
| Cross-barangay denial (rules) | **Yes** | `barangayCanReadCoordinationThread()` / `barangayCanReadCoordinationThreadId()`. |
| Session persistence | **Yes (backend)** | Threads/events in Firestore; no local-only cache required for retention across app restarts. |

**Conclusion:** Increment B delivers **referral creation** and **MOPH review**, not **barangay referral history UI**. Implementation is an **extension** of Increment B coordination features, not a duplicate of aggregate **Submitted reports**.

## 3. Reuse (do not duplicate)

| Reuse | Path / pattern |
|-------|----------------|
| Detail body (privacy-safe fields + timeline) | `sibol_app/lib/features/coordination/presentation/widgets/coordination_thread_detail_body.dart` |
| List UX pattern (loading / empty / error) | `barangay_submitted_reports_screen.dart` |
| Repository / models | `CoordinationRepositoryImpl`, `CoordinationThread`, `CoordinationStaffEvent` |
| MOPH detail structure | `moph_coordination_detail_screen.dart` — factor shared **detail shell** or add parallel screen wired to **barangay-scoped** providers (same widget tree, different providers). |

**Do not** add a second Firestore collection for history; use `caseCoordinationThreads` as source of truth.

## 4. Proposed implementation (pending PA implementation handover)

### 4.1 Flutter (scoped)

1. **Routes:** e.g. `/barangay/submitted-referrals`, `/barangay/submitted-referrals/:threadId` (names distinct from `submitted-reports`).
2. **Dashboard:** `OutlinedButton` **Submitted referrals** on `barangay_home_screen.dart`.
3. **Repository:** `watchSubmittedReferralsForBarangay(String barangay)` — query:

   ```text
   caseCoordinationThreads
     .where('barangay', == assignedBarangay)
     .where('phase', whereIn: [referred, awaitingBarangay, awaitingMoph, closed])
     .orderBy('lastStaffEventAt', descending: true)
   ```

4. **Providers:** `barangayCoordinationThreadsProvider`, `barangayCoordinationThreadProvider(threadId)`, `barangayCoordinationStaffEventsProvider(threadId)` — mirror MOPH naming; scope by profile `assignedBarangay` on list; detail by thread id + rules.
5. **Screens:** list + detail; detail uses `CoordinationThreadDetailBody`.
6. **Optional:** link from list row to related assistance request via `private/binding` **only on barangay detail** if PA wants navigation back to incoming request (barangay may read binding per rules); do not expose binding fields on MOPH UI.

### 4.2 Firestore rules

**Expected: no rule change** for read paths already in Increment A/B (barangay reads threads and staffEvents for matching `barangay`).

**Add rules tests** (when implementing):

- Barangay list query for all phases at own site — **allow**.
- Barangay list/query filtered to other site — **deny** (documents fail rule or query returns empty).
- Teen / MOPH list on barangay-scoped query shape — **deny**.

### 4.3 Firestore indexes

Existing composite (deployed Increment A):

- `caseCoordinationThreads`: `barangay` ASC, `phase` ASC, `lastStaffEventAt` DESC.

Proposed query uses `whereIn` on `phase` (4 values) + `orderBy lastStaffEventAt` — **likely satisfied** by this index. Confirm in emulator before deploy; if Firebase requests a new composite, add to `firestore.indexes.json` in the same change set as implementation (deploy only when PA authorizes).

**No new index** required if using registry-only list (not recommended — weaker sort and duplicate UX).

### 4.4 Functions / Increment C

- **No new callables** for B-HISTORY (read-only UI).
- **Increment C** remains separate (staff event writes, phase transitions). History screen **displays** events created by callables/rules in C when they exist; until then, timeline may show initial `referral_submitted` only.

### 4.5 Privacy (DEC-CASE-001)

- List and detail: same header fields as MOPH (`displayRef`, category, barangay, summary, phase, staff events).
- Do not show teen uid, teen name, or original `teenAssistanceRequests.description` on these screens.
- Do not add MOPH-visible fields to barangay-only registry documents in UI.

## 5. Verification plan (when implemented)

| Test | Method |
|------|--------|
| Barangay A sees own referrals | Rules test + widget test with fake repository / emulator seed |
| Barangay A not Barangay B | Rules test cross-site query/get |
| Persistence across restart | Manual / integration: Firestore-backed stream after cold start |
| Detail + event order | Widget test on `CoordinationThreadDetailBody` + repository ordering |
| Empty history | Widget test empty list copy |
| Unauthorized roles | Rules tests teen/MOPH on barangay query |

Manual MVR (suggested): **MVR-0009** — Barangay submitted referral history (live Firebase, post-implementation).

## 6. Deployment sequencing

1. Implement Flutter + rules tests in repo (no deploy required for local/emulator QA if rules already live on `sibol-286d0`).
2. If index definition changes: deploy indexes with PA authorization (may already be live from Increment A).
3. Registry rules v2 deploy ([registry deploy readiness](SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md)) remains independent.

## 7. PA decision requested before implementation

| Item | EA assessment |
|------|----------------|
| Material expansion of closure task? | **Yes** — new routes, repository methods, providers, 2 screens, tests; **not** Increment C. |
| Firebase deploy required for MVP? | **Probably no** if existing indexes and rules on `sibol-286d0` match §4.2–4.3. |
| Proceed without separate handover? | **Recommend separate implementation handover** referencing this spec. |

**EA will not implement B-HISTORY until PA authorizes implementation** (this addendum is planning-only).

## 8. Traceability

- [SIBOL_CASE_COORD_001_PLAN.md](SIBOL_CASE_COORD_001_PLAN.md) — phase table updated  
- [ADR-0005](../Architecture/ADRs/ADR-0005-Case-Coordination-Minimum-Information.md)  
- [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md)
