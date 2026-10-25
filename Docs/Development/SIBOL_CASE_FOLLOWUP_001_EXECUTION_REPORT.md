# SIBOL-CASE-FOLLOWUP-001 — Execution report

**Handover UUID:** `a7e4c190-2d63-4f85-9b17-c6e2038d5a41`  
**PA baseline cited:** `ea1e139` (actual implementation baseline: `44830e3` with OFF-002-B partial follow-up; this milestone completes PO requirements)  
**Starting HEAD:** `44830e3`  
**Ending HEAD:** `521fae8`  

## Summary

Barangay staff can add follow-up entries on an existing case with a notes-focused form, staff UID and server `createdAt` on write, chronological timeline display, and per-row **Pending sync** / **Cached** indicators via Firestore persistence (no custom queue).

OFF-002 follow-up creation item is **completed**; OFF-002 overall remains complete per prior tranches A–D — this change refines W2 follow-up to PO P0 spec.

## Implemented functionality

| Requirement | Implementation |
|-------------|----------------|
| Add Follow-Up action | App bar + **Add follow-up** button on case detail |
| Simple entry form | `AddFollowUpDialog` — observation/action text (validated) |
| Save to case | `CaseRepository.createFollowUp` → `cases/{id}/followUps/{id}` |
| Chronological timeline | Existing `orderBy('scheduledAt')` + `CaseFollowUpTimeline` |
| Staff identity + timestamp | `createdByUid` + `createdAt` (`FieldValue.serverTimestamp()`) |
| Org authorization | Unchanged rules: `canWriteCaseOrg(parentCaseOrgId)` |
| Offline | Firestore persistence; `hasPendingWrites` → **Pending sync** chip |

## Automated verification

| Suite | Result |
|-------|--------|
| `cd sibol_app && flutter test` | **142/142 PASS** |
| `test/cases.rules.test.mjs` (isolated emulator) | PASS (incl. new follow-up create/deny-teen cases) |

Mocked/widget tests cover validation, timeline ordering, pending chip, and repository create. **Android device offline→online** is not claimed from unit tests alone (see acceptance below).

## Offline behavior

- Writes use native Firestore offline queue; entries show **Pending sync** until the server acknowledges.
- Survives app restart via Firestore local persistence (same mechanism as W2 cases).
- No `PendingOperation` queue for follow-ups (per assignment).

## Limitations

- Timeline shows staff **UID** (not display name) unless profile lookup is added later.
- Existing seeded follow-ups without `createdByUid`/`createdAt` still render using `scheduledAt`.
- Concurrent edits: Firestore last-write-wins (prototype).

## Minimal Android acceptance (device/emulator)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Barangay sign-in → open a case (create one if needed) | Case detail loads |
| 2 | Tap **Add follow-up** → enter text → **Save** | Entry appears at bottom of timeline with timestamp |
| 3 | Verify **Recorded by staff ({uid})** | Matches signed-in barangay user |
| 4 | Enable airplane mode → add another entry | **Pending sync** chip on new row |
| 5 | Force-stop app → reopen offline | Pending entry still visible |
| 6 | Restore network | Chip clears when sync completes |
| 7 | Teen account → attempt case URL | No access (existing rules) |
