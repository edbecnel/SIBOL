# SIBOL organization identity — development roadmap (approved sequence)

> **Work item:** SIBOL-ORG-IDENTITY-001 · **Related:** SIBOL-OFFLINE-001  
> **Source:** Implementation plan PLAN-002-REFINE-001 (PO-approved sequence)

## Milestones

| Milestone | Scope | Status (M0) |
|-----------|--------|-------------|
| **M0** | EDF drafts, gates, MVR draft, acquisition docs | **Complete (AGENT-001)** |
| **M1** | PSGC pipeline, validators, mixed-path fixture; NHFR synthetic Track A | **Not authorized** |
| **M2** | Identity keys, callables, rules, teen resolution | Not started |
| **M3** | Flutter geo UI, admin/teen registration | Not started |
| **M4** | Connected SIBOL-INT-001 E2E (synthetic seed preserved) | Not started |
| **M5** | Handoff documentation for SIBOL-OFFLINE-001 | Not started |

## Cross-work-item order

1. Finalize org identity contracts (M0–M1).
2. Implement geographic registration + uniqueness (M2–M3).
3. Connected INT-001 E2E on existing emulator dataset (M4).
4. **Prioritize SIBOL-OFFLINE-001** before substantial new workflows.
5. Offline/intermittent connectivity verification.
6. Later: clean Central-Admin bootstrap rehearsal and demo reset (not during ORG-IDENTITY).

## Gates

- **G-PSGC-REDIST** — PSA redistribution (open).
- **G-NHFR** — NHFR redistribution (open).
- **ADR-REG-003 acceptance** — package prepared; PA acceptance pending.
- **ADR-REG-004** — proposed.
