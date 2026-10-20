# SIBOL-FB-002 — Operational seed execution (addendum)

> **Supplements:** [SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md](SIBOL_FB_002_PHASE_A_EXECUTION_REPORT.md)  
> **Planning handover UUID:** `b8e72a49-1c35-4f60-9d28-6a40e9c753bf`  
> **Phase A handover UUID:** `7e4b0f93-8c26-4d51-a9f0-62e8c5d31b74`  
> **Date recorded:** 2026-10-20  
> **Retrospective reconstruction:** Owner-reported outcomes; exact CLI transcript not preserved in repo.

## 1. Objective

Provision fictional demonstration Auth users, Firestore profiles, cases, and follow-ups on live project `sibol-286d0` for end-to-end role testing.

## 2. Tooling used

- `shared/provisioning/` package (Phase A hardening).
- Launcher: `shared/scripts/seed_tranche1_demo.mjs`.
- Passwords via environment variables per [shared/docs/PROVISIONING.md](../../shared/docs/PROVISIONING.md) (values **not** recorded here).

## 3. Reported operational outcome (project owner)

| Asset | Expected | Owner verification |
|-------|----------|-------------------|
| Firebase Auth demo users | 3 (teen, barangay, MOPH) | Present — live sign-in on Android |
| `users/{uid}` profiles | 3 with roles | Present |
| `cases` documents | 5 fictional demo cases | Barangay list shows five rows |
| `followUps` documents | 5 aligned to demo cases | Implied by seed design; not UI-verified in T1 |

Acceptance traceability: [TRANCHE_1_ACCEPTANCE_REPORT.md](TRANCHE_1_ACCEPTANCE_REPORT.md) ACC-06.

## 4. What this addendum does not claim

- No copy of `--confirm-project=` command line or ADC identity in repo.
- No Firebase deploy or rules changes as part of FB-002.
- Phase A explicitly performed **no** live writes; this addendum documents **subsequent owner-authorized** seed execution only.

## 5. PA disposition

Demo provisioning accepted as part of Tranche 1 functional acceptance (`f71b8c62-…`).
