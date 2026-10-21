# SIBOL-IMP-002 T2-3 — Plan (case create/edit)

> **Handover UUID:** `9b26f80d-4e71-4b35-8c62-d741a9f305be`  
> **Status:** **Planning only — NOT authorized for implementation**  
> **Date:** 2026-10-21  
> **Depends on:** T2-1/T2-2 published; [CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md](SIBOL_IMP_002_CROSS_PROJECT_ARCHITECTURE_ASSESSMENT.md)

## 1. Objective (when authorized)

Allow barangay users to **create** and **edit** fictional demonstration cases (and optionally follow-ups in a later sub-phase) while preserving validation, rules, and read-only teen/MOPH boundaries.

## 2. Recommended boundaries

| In scope (typical T2-3) | Out of scope |
|-------------------------|--------------|
| `CaseRecord` create/update via existing repository | Report submission, approval admin UI |
| Reuse `CaseValidation` + `CaseRecordModel.assertValidForWrite` | New org-hierarchy model (defer to platform phase) |
| Form screens + navigation from dashboard | Follow-up **create** (could be T2-3b or T2-3 scope split — PA decision) |
| Widget/unit tests for forms and repository calls | Firestore rules **deploy** without PA auth |
| Offline: document `hasPendingWrites` UX only if in same authorization | Emergency escalation |

## 3. Repository and validation reuse

- Extend `CaseRepository` with `createCase(CaseRecord)` / `updateCase(CaseRecord)` using `CaseRecordModel.toFirestore()`.
- Client-side validation before write; align with `shared/contracts/case_record.schema.json`.
- **Do not** allow client to set `reportStatus` to submitted/accepted states reserved for Cloud Functions (ADR-0003).

## 4. Firestore authorization (current rules — deploy not authorized here)

Confirmed in repo [`firestore.rules`](../../firestore.rules):

- `allow read, create, update: if isBarangay()` on `cases` and `followUps`.
- `allow delete: if false`.

T2-3 should add **field allow-list validation in rules** (recommended before production) — e.g. immutable `createdAt`, restricted `reportStatus` transitions. Requires separate rules-deploy handover.

## 5. Data integrity and audit

- Set `createdAt` on create, `updatedAt` on every update (server timestamp preferred long-term; client `FieldValue.serverTimestamp()` for T2-3 if authorized).
- Preserve fictional naming conventions (`demoName`, ages 13–19).
- No separate audit collection in T2-3 unless PA expands scope.

## 6. SIBOL-specific vs reusable

| Layer | T2-3 recommendation |
|-------|---------------------|
| `CaseValidation`, enums | Keep in `sibol_app` until shared schema stabilizes |
| Repository interface | Add write methods; later extract interface to `shared/` if SpeakUp aligns on contract |
| Forms / routes | SIBOL UI only |
| Workflow / approval | **No client implementation** — depend on future server policy per FUTURE_CROSS_PROJECT_PLATFORM_REQUIREMENTS |

## 7. Dependencies on future reporting workflow

- Case `reportStatus` field must remain compatible with [REPORTING_CONTRACT.md](../../shared/docs/REPORTING_CONTRACT.md).
- T2-4+ `submitReport` function should remain sole writer of `reports/*` and authoritative transitions to submitted/accepted.
- Admin-configurable reviewer (default MOPH) is **not** a T2-3 prerequisite; avoid hardcoding MOPH-only assumptions into case forms.

## 8. Verification plan (when implemented)

- Automated: form validation tests, repository unit tests with fake Firestore or emulator (if authorized).
- Manual: barangay create/edit on Android against `sibol-286d0`; teen still denied `cases`.

## 9. PA gates before coding

1. Authorize T2-3 umbrella (create + edit cases).
2. Confirm whether follow-up **create** is in T2-3 or deferred.
3. Authorize Firestore rules hardening + deploy if field constraints added.
4. SpeakUp Connect source review (optional but recommended per assessment §2).
