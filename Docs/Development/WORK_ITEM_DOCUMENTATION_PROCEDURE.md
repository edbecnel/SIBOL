# Work-item documentation procedure (EDF-aligned)

> **Adopted:** 2026-10-20 (SIBOL-GOV-001 recovery)  
> **Applies to:** Software engineering work items (`SIBOL-IMP-*`, `SIBOL-FB-*`, `SIBOL-GOV-*`)

Use existing EDF domains (`Docs/Development`, `Docs/Verification`, `Docs/Architecture/ADRs`) — no parallel issue tracker required at Bootstrap tier.

## At initiation (before implementation)

1. Read [edf-project-context.yaml](../../edf-project-context.yaml), [PROJECT_INDEX.md](../../PROJECT_INDEX.md), [Docs/Development/README.md](README.md).
2. Create or open `Docs/Development/SIBOL_<AREA>_<NNN>_EXECUTION_REPORT.md` (or `_PLAN.md` if plan-only) with:
   - Work item ID, title, **Handover UUID**, date
   - **PA authorization** (scope and explicit prohibitions)
   - Objectives linked to specs and ADRs
3. Architecture changes → ADR in `Docs/Architecture/ADRs/`.
4. Human manual verification required → schedule MVR under `Docs/Verification/Records/` (see [MVR-0001-tranche1-role-walkthrough.md](../Verification/Records/MVR-0001-tranche1-role-walkthrough.md) as example).

## During planning (PLAN mode)

- Record investigation conclusions in the work-item plan section.
- List intended file touches; do not implement.

## During implementation (AGENT mode)

- Update **Implementation** and **Files changed** in the execution report.
- Record new ADR IDs when decisions are made.

## At verification

- Run `flutter test` / `flutter analyze`; record pass counts and date (no secrets).
- Link new test files.
- Complete MVR execution section when applicable.

## At completion

- **PA acceptance/rejection** subsection (quote handover UUID).
- Update [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md).
- Update [CHANGELOG.md](../../CHANGELOG.md) `[Unreleased]` (one line per work item).
- EA completion message must list documentation paths changed.

## Pre-report checklist

- [ ] Work-item doc exists and matches scope
- [ ] Verification evidence in report or MVR
- [ ] ADRs updated if needed
- [ ] Register + CHANGELOG updated
- [ ] No passwords/tokens in docs
