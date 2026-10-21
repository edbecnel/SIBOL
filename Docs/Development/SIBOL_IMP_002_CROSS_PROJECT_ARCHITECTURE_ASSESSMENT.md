# SIBOL-IMP-002 — Cross-project architecture assessment

> **Handover UUID:** `9b26f80d-4e71-4b35-8c62-d741a9f305be`  
> **Date:** 2026-10-21  
> **Mode:** Planning only — no implementation, no SpeakUp Connect changes  
> **SpeakUp Connect sources in workspace:** **None** (see §2)

## 1. Purpose

Prepare T2-3 case create/edit and later reporting phases by comparing **verified SIBOL implementation** with **documented intent** for SpeakUp Connect and cross-project platform requirements.

## 2. SpeakUp Connect availability

| Item | Status |
|------|--------|
| SpeakUp Connect repository or app sources in `/Users/edbecnel/Development/GitHub/SIBOL` | **Not present** |
| SIBOL references | ADR-0002 (adapted Riverpod/go_router patterns); Tranche 1 report (“read-only reference”); distinct Firebase project `sibol-286d0` vs `speakup-connect-891dd` |

**Information required from PA/owner before a code-level comparison:**

- SpeakUp Connect repository path or architecture documentation package.
- Organization/tenant model, role matrix, and admin capabilities as implemented.
- Reporting and approval flows (if any) in production or prototype.
- Emergency escalation features (if any).

Until then, assessment below is **SIBOL-confirmed** plus **SIBOL-documented future intent** ([FUTURE_CROSS_PROJECT_PLATFORM_REQUIREMENTS.md](../Specifications/FUTURE_CROSS_PROJECT_PLATFORM_REQUIREMENTS.md)).

## 3. SIBOL — confirmed implementation

### Organization and hierarchy

| Topic | SIBOL today |
|-------|-------------|
| Organization types | **Not modeled** — single fictional `barangay` string on case; no municipality/school/DepEd hierarchy |
| User scope | Global demo roles (`teen`, `barangay`, `moph`) on `users/{uid}` — no org membership document |

### Roles, permissions, administration

| Topic | SIBOL today |
|-------|-------------|
| Roles | Three fixed roles; provisioned by Admin SDK seed; users cannot change `role` ([`firestore.rules`](../../firestore.rules)) |
| Barangay | Read/create/update `cases` and subcollection `followUps` |
| Teen | No `cases` access |
| MOPH | Read `reports` only when server-set `acceptedAt` + `reportStatus == submitted` |
| Administrator | **No app role**; policy changes require rules/functions deployment (not admin UI) |

### Sensitive case / report data

| Topic | SIBOL today |
|-------|-------------|
| Case fields | Fictional demo schema ([CASE_AND_REPORTING_MODEL.md](../Specifications/CASE_AND_REPORTING_MODEL.md)); JSON schema in `shared/contracts/case_record.schema.json` |
| Reports | Client cannot write `reports`; `submitReport` stub in Cloud Functions |
| Confidentiality | Role-based Firestore rules + fictional-data UX banners |

### Workflows (implemented)

| Workflow | Status |
|----------|--------|
| Case list (barangay) | **Yes** |
| Case detail read-only | **Yes** (T2-1) |
| Follow-up timeline read-only | **Yes** (T2-2) |
| Case create/edit | **No** (T2-3 planned) |
| Follow-up create/edit | **No** |
| Report submit / MOPH review | **No** (stubs/docs only) |

### Emergency escalation

| Topic | SIBOL today |
|-------|-------------|
| Implementation | **None** — requirements tracked only in FUTURE_CROSS_PROJECT_PLATFORM_REQUIREMENTS §B |

### Audit and confidentiality

| Topic | SIBOL today |
|-------|-------------|
| Audit trail | `createdAt` / `updatedAt` on cases; no separate audit log collection |
| Configurable approval audit | **Not implemented** |

## 4. SpeakUp Connect — documented intent only (not verified in code)

From SIBOL program context and future-requirements doc (product direction, **not confirmed against SpeakUp codebase**):

- Organization categories: municipalities, barangays, universities, DepEd, schools.
- Shared need: sensitive minor-related case/report handling.
- Desired platform: org-scoped policies, configurable approval, emergency escalation, reusable reporting foundation.

**Assumption risk:** SpeakUp Connect may use different auth, org model, or reporting stack until sources are reviewed.

## 5. Reuse opportunities (design-level, not authorized)

| SIBOL artifact | Extraction candidate | Notes |
|----------------|---------------------|--------|
| `CaseRepository` + validation | Generic “org-scoped document repository” | Needs org-id in path or claims |
| `CaseFollowUpTimeline` + stream provider | Generic read-only event timeline | Schema-agnostic presenter |
| `shared/contracts/*.schema.json` | Shared validation package | Keep SIBOL fictional fields separate from SpeakUp domains |
| `shared/functions` reporting stub | Server workflow engine entry point | Must grow into policy-driven approval, not hardcoded MOPH |
| Role-home + nested routes | Flutter navigation pattern | Already used in T2-1 |

## 6. Gaps vs long-term objective

| Gap | Impact on T2-3+ |
|-----|-----------------|
| No organization entity | Case create/edit must not hardcode single-barangay demo forever; introduce org scope in schema/rules before multi-tenant reuse |
| No admin-configurable workflow | T2-3 can use fixed barangay CRUD; reporting phases need server policy store |
| No audit log | T2-3 should set `updatedAt` consistently; consider function-written audit events later |
| No escalation | Out of T2-3 scope |

## 7. PA disposition

Assessment complete for planning. **T2-3 implementation not authorized** by this handover.
