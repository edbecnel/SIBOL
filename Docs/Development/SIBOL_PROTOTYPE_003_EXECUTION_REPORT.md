# SIBOL-PROTOTYPE-003 — Execution report

**Starting HEAD:** `6447220`  
**Ending HEAD:** `1ae7611`  
**Authorization:** Controlled emulator integration without reseed or production deploy.

## Phase A — Inspect and safeguard

### Repository

- HEAD `6447220`, clean tracked tree.

### Running emulator configuration

| Item | Finding |
|------|---------|
| Starter | `./shared/scripts/start-demo-emulators.sh --import=.firebase-qa-backups/pre-fix-002` (PID **92887**) |
| Auth | **9099** (node) |
| Firestore | **8195** (java, rules from repo; seeded from `pre-fix-002` then mutated by QA sessions) |
| Functions | **5001** (node) |
| Hub | **4400** |
| Persistence | In-memory since import; **no** `--export-on-exit` on current process |

### Backup created (mandatory)

| Field | Value |
|-------|--------|
| Path | `.firebase-qa-backups/pre-prototype-003-20261025/` (**not committed**) |
| Command | `firebase emulators:export … --force` while emulators running |
| Recovery doc | [SIBOL_PROTOTYPE_003_EMULATOR_RECOVERY.md](../Operations/SIBOL_PROTOTYPE_003_EMULATOR_RECOVERY.md) |

SHA-256 checksums recorded in recovery doc.

### QA anchor verification (read-only, live Firestore **8195**)

| Anchor | Result |
|--------|--------|
| `teenAssistanceRequests/32sQiFj9v8T6R6T3Asih` | exists, `acknowledged`, `orgId: barangay03` |
| `barangayCoordinationRegistry/32sQiFj9v8T6R6T3Asih` | exists |
| `users/pjHSdYK7Vh2qYAnBzu6FmMeWjUMU` | exists |
| `caseCoordinationThreads/CxsRXE0ciuhrxXa1L0Ay` | exists, `phase: referred` |
| `cases` / `reports` collection counts | **0** (W2/W3 may need in-session demo data) |

## Phase B — Functions integration

| Check | Result |
|-------|--------|
| `npm run build` in `shared/functions` | **PASS** — exports include `regAcknowledgeTeenAssistanceRequest` |
| Running emulator callables | **Already registered** — HTTP **401** UNAUTHENTICATED for teen submit, ack, referral (proves presence) |
| Restart required? | **No** — current Functions process already serves post–OFF-001 ack callable |
| Auth/Firestore interrupted? | **No** |

## Phase C — Integration verification

| Check | Result |
|-------|--------|
| `node shared/scripts/verify-canonical-emulator-health.mjs` | **PASS** |
| Flutter `flutter test` | **134/134 PASS** |
| Functions `npm test` (isolated **8226**) | **70/70 PASS** |
| QA-001 records modified? | **No** |

## Phase D — Acceptance preparation

- Updated [SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md](../Operations/SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md) §8–9 (health script, backup pointer, minimal PO steps).

## Remaining blockers

- **None** for callable integration on the current running stack.
- If emulators are **stopped**, restart must use `--import=.firebase-qa-backups/pre-prototype-003-20261025` (separate PA session — not executed here).
- W2/W3 demos may need creating fictional **cases** (and thus report counts) without altering QA assistance/referral documents.

## Prototype acceptance

**Not declared.**
