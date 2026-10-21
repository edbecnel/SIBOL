# SIBOL-IMP-002 — Tranche 2 implementation plan (proposed)

> **Handover UUID (T1-CLOSE / planning):** `f71b8c62-2e49-4d03-a615-9c7e82b4d390`  
> **Status:** T2-1 **published** (`8480c1a`); T2-2 **published**; T2-3 **planned only** (handover `9b26f80d-…`)  
> **Date:** 2026-10-20 (plan); T2-1 delivery 2026-10-21  
> **Gate:** [TRANCHE_2_IMPLEMENTATION_GATE.md](TRANCHE_2_IMPLEMENTATION_GATE.md)

## 1. Purpose

Define traceable Tranche 2 engineering scope derived from [TRANCHE_1_EXECUTION_REPORT.md](TRANCHE_1_EXECUTION_REPORT.md) §15, [CASE_AND_REPORTING_MODEL.md](../Specifications/CASE_AND_REPORTING_MODEL.md), [REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md), ADR-0003–0004, and FB-005 findings.

## 2. Requirements traceability

| Req ID | Requirement | T1 state |
|--------|-------------|----------|
| T2-R01 | Barangay case create/edit/detail | List only; no `onTap` (FB-005) |
| T2-R02 | Follow-up timeline UI | Data + stream; no screen |
| T2-R03 | `submitReport` callable per contract | Stub throws `failed-precondition` |
| T2-R04 | MOPH accepted-reports list | Placeholder dashboard |
| T2-R05 | Offline pending submit UX | Not implemented (ADR-0004) |
| T2-R06 | Case list search/filter | **PA confirm in/out** |
| T2-R07 | Teen assistance stub | **Optional P1 — PA gate** |
| T2-R08 | Emulator integration tests | 28 widget/unit tests only |
| T2-R09 | Role-based security rules | Rules present; no client report writes |

## 3. Proposed phases

| Phase | Deliverable | PA gate |
|-------|-------------|---------|
| T2-1 | Case detail (read-only) + `ListTile.onTap` + routes + tests | **Complete** — [SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_1_EXECUTION_REPORT.md) |
| T2-2 | Follow-up timeline on detail | **Complete** — [SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md](SIBOL_IMP_002_T2_2_EXECUTION_REPORT.md) |
| T2-3 | Case create/edit + repository writes | **Planned** — [SIBOL_IMP_002_T2_3_PLAN.md](SIBOL_IMP_002_T2_3_PLAN.md) (not authorized) |
| T2-4 | Implement `submitReport` in `shared/functions/src/index.ts` | **Functions deploy** |
| T2-5 | Barangay submit UI + offline pending handling | — |
| T2-6 | MOPH reports list | Sample `reports` seed decision |
| T2-7 | Emulator integration tests | Optional CI |
| T2-8 | Search/filter on case list | PA scope |
| T2-9 | Teen assistance stub | PA optional |

## 4. Architecture notes

- Routes: e.g. `/barangay/cases/:caseId` in `route_constants.dart` / `app_router.dart`.
- New screens: case detail, case edit/create, follow-up timeline, report submit flow, MOPH reports list.
- Client calls callable `submitReport`; server writes `reports/*` and case `reportStatus` (ADR-0003).
- Align writes with `shared/contracts/case_record.schema.json`.

## 5. Firebase / security

- Keep client **denied** on `reports` create/update/delete.
- Deploy gates: rules/index changes and Cloud Functions require explicit PA authorization.
- Teen assistance (if approved) needs new collection + rules.

## 6. Acceptance (T2)

- Widget/unit tests for navigation, forms, redirects.
- Emulator integration: barangay submit → MOPH read; teen cannot read `cases`.
- Manual role walkthrough (Android + `flutter run` on iOS).

## 7. PA decision points

1. Authorize Tranche 2 umbrella (SIBOL-IMP-002).
2. T2-R06 search/filter — in or out?
3. T2-R07 teen assistance — in, out, or later?
4. Functions deploy + rules/index updates.
5. Seed sample `reports` for MOPH UI vs function-only E2E.
6. Git commit policy for T2 delivery.

## 8. Documentation expectation

Each T2 phase or work item uses [WORK_ITEM_DOCUMENTATION_PROCEDURE.md](WORK_ITEM_DOCUMENTATION_PROCEDURE.md) and updates [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md).
