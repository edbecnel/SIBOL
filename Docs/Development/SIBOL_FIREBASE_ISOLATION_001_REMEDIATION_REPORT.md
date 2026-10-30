# SIBOL-FIREBASE-ISOLATION-001 — Remediation Report

**Work item:** SIBOL-FIREBASE-ISOLATION-001  
**Handover UUID (remediation):** `7b3f91c2-6e48-4d15-a0c7-9f82e5b31460`  
**Handover UUID (runtime verification):** `c49d82e1-6a35-4f07-9b21-7e05d83a6c90`  
**Branch:** `main`  
**Baseline commit (remediation):** `ee10100`  
**Classification:** **COMPLETE—VERIFIED** (runtime isolation identity and endpoint gates; operational QA seed and ADC hygiene tracked separately)

## Original safety finding

Local Firebase emulator workflows could bind to production project identity `sibol-286d0` because `.env.emulator.local` and shell overrides were applied after canonical defaults, and several emulator scripts hard-coded the production project id. That breaks the PA mandate for canonical emulator identity `demo-sibol-emulator` and increases risk of ADC-backed operations targeting live Firebase when emulator env is incomplete.

## Root cause

1. `.env.emulator.local` (gitignored) set `FIREBASE_PROJECT_ID=sibol-286d0`.
2. `start-demo-emulators.sh` sourced local env without a fail-closed enforcement step.
3. Emulator provisioning, integration smoke, and health scripts referenced `sibol-286d0` instead of `demo-sibol-emulator`.
4. Preflight guards checked canonical id but did not explicitly reject production id as a distinct failure mode (now covered in unit tests).

## Files corrected (remediation scope)

| Area | Path |
|------|------|
| Enforcement | `shared/scripts/enforce-canonical-emulator-env.sh` (new) |
| Canonical env | `shared/scripts/emulator-canonical.env.sh` |
| Startup | `shared/scripts/start-demo-emulators.sh` |
| Static gate | `shared/scripts/verify-emulator-isolation-static.sh` (new) |
| Isolation CLI | `shared/scripts/validate-local-firebase-isolation.sh` (`--static`) |
| INT-001 preflight | `shared/scripts/validate-int-001-emulator.sh` |
| Health check | `shared/scripts/verify-canonical-emulator-health.mjs` |
| Example env | `.env.emulator.example` |
| Local env | `.env.emulator.local` (gitignored; corrected in place, not committed) |
| Guards | `shared/provisioning/src/emulator_guard.mjs`, `shared/provisioning/src/constants.mjs` |
| Tests | `shared/provisioning/test/emulator_guard.test.mjs`, `emulator_ports.test.mjs` |
| Seed / repair (emulator-only) | `shared/provisioning/seed_emulator_demo.mjs`, `backfill-*-emulator.mjs`, `repair-p0-recovery-001-emulator.mjs`, `shared/functions/scripts/repair-geo-fix-003-emulator.mjs`, `verify-canonical-qa-anchors.mjs` |
| Integration harness | `shared/integration/scripts/run-prototype-smoke.mjs`, `shared/integration/test/*.smoke.mjs` |
| Functions test runner | `shared/functions/scripts/run-firestore-integration-tests.mjs`, `shared/functions/test/helpers/emulator_env_guard.mjs` (new) |

**Intentionally unchanged:** production release config (`sibol_app/lib/config/firebase_options.dart`), `shared/delivery/scripts/*live*`, and production `--confirm-project=sibol-286d0` provisioning flows.

## Static verification evidence

Executed (no emulators started, no Firebase I/O):

```bash
./shared/scripts/verify-emulator-isolation-static.sh
```

Results:

- Preflight (`preflight-emulator-env.mjs`) **rejects** `FIREBASE_PROJECT_ID=sibol-286d0` with canonical emulator hosts set.
- `enforce-canonical-emulator-env.sh` **rejects** production project id and conflicting overrides.
- `emulator-canonical.env.sh` exports `FIREBASE_PROJECT_ID=demo-sibol-emulator`.
- `node --test` in `shared/provisioning`: **9/9** tests passed, including new production-id rejection case.

Alternate entry:

```bash
./shared/scripts/validate-local-firebase-isolation.sh --static
```

## Runtime verification evidence (2026-10-30)

**Authorization:** PA handover `c49d82e1-6a35-4f07-9b21-7e05d83a6c90` — controlled emulator start and non-destructive checks only. No seed, import, deploy, or CASE-LIFECYCLE tests.

### Preflight (before start)

| Check | Result |
|--------|--------|
| Git HEAD at `ee10100` | Pass |
| CASE-LIFECYCLE / iOS WIP unstaged | Preserved |
| Canonical project in `canonical_ports.json` | `demo-sibol-emulator` |
| `.env.emulator.local` `FIREBASE_PROJECT_ID` | `demo-sibol-emulator` (gitignored) |
| Ports 9099 / 8195 / 5001 free | Pass (after cleanup of stale processes) |
| `.emulator-data` in workspace | Absent — no import/modify |

### Emulator startup

- **Command:** `bash shared/scripts/start-demo-emulators.sh` (build + canonical env + `.env.emulator.local` + enforce + `firebase emulators:start --project "${FIREBASE_PROJECT_ID}" --only auth,firestore,functions`).
- **Firebase CLI:** `Detected demo project ID "demo-sibol-emulator", emulated services will use a demo configuration…`
- **Firestore JVM (ps):** `--project_id demo-sibol-emulator`
- **Functions URLs:** `http://127.0.0.1:5001/demo-sibol-emulator/us-central1/…`
- **Endpoints:** Auth `127.0.0.1:9099`, Firestore `127.0.0.1:8195`, Functions `127.0.0.1:5001` — all listening at verification time.
- **Production deploy:** None (`firebase deploy` not invoked).

**Warning observed (residual risk):** Firebase CLI reported Application Default Credentials present; non-emulated services could use production. All authorized checks set `FIRESTORE_EMULATOR_HOST` / `FIREBASE_AUTH_EMULATOR_HOST` to local canonical ports and `demo-sibol-emulator`; no production Admin SDK calls were made during verification.

### Runtime script results (emulators up)

| Script | Result |
|--------|--------|
| `validate-local-firebase-isolation.sh` | **Pass** — `project=demo-sibol-emulator`, local hosts, ports open |
| `validate-int-001-emulator.sh` | **Pass** — ports + `preflight-emulator-env.mjs --check-reachable` |
| `enforce-canonical-emulator-env.sh` with `FIREBASE_PROJECT_ID=sibol-286d0` | **Pass (fail-closed)** — rejected before emulator use |
| `verify-canonical-emulator-health.mjs` | **Partial** — ports and required callables OK; QA anchor sub-step exit 1 on empty emulator (see below) |

**Callable probe (local HTTP POST, empty payload):** `regSubmitTeenAssistanceRequest`, `regAcknowledgeTeenAssistanceRequest`, `createCoordinationReferral` returned expected unauthenticated responses — confirms registration on `demo-sibol-emulator` functions emulator, not production.

**QA anchor sub-step (read-only Firestore GETs):** `verify-canonical-qa-anchors.mjs` reported seeded QA documents **missing** on a fresh emulator (`teenAssistanceRequests/32sQiFj9…` not found). This is a **demo dataset** expectation, not an isolation failure. No writes performed. Full green on this sub-step requires a separately authorized seed/import — **not executed**.

**Excluded (outside authorization):** seeding, snapshot import, integration/case-lifecycle test suites, production backup/export.

### Clean shutdown

Emulators stopped via controlled `pkill` of firebase/emulator processes; ports 9099/8195/5001 confirmed closed. No `--export-on-exit`, no snapshot delete/modify.

### Defects found during runtime (local fixes, not in `ee10100`)

1. **`start-demo-emulators.sh`:** with `set -u`, trailing `"${@}"` errors when no extra args (`@: unbound variable` on macOS bash). Local fix: `${1+"$@"}` (uncommitted alongside this EDF update).
2. **`verify-canonical-emulator-health.mjs`:** duplicate ESM imports caused `SyntaxError` on Node 24 until deduplicated (uncommitted fix required to run authorized health script).

Recommend a small follow-up commit for items 1–2 on `main` (exact-file, no CASE-LIFECYCLE WIP).

## Runtime verification pending (requires PA release of emulator hold)

~~1–4 below completed under handover `c49d82e1`.~~ Remaining operational items:

1. ~~Start emulators via `shared/scripts/start-demo-emulators.sh`…~~ **Done** (see above).
2. ~~Run `./shared/scripts/validate-local-firebase-isolation.sh`…~~ **Done**.
3. ~~Run `./shared/scripts/validate-int-001-emulator.sh`…~~ **Done**.
4. ~~Run `node shared/scripts/verify-canonical-emulator-health.mjs`.~~ **Done** (QA anchors need seed for exit 0).
5. Run provisioning preflight after **authorized** seed workflow (not part of isolation verification).

## `.emulator-data` / snapshot status

Read-only inspection: `.emulator-data` directory **not present** in this workspace clone (nothing deleted during remediation). If snapshots exist on other machines, verify `firebase-export-metadata.json` project id compatibility with `demo-sibol-emulator` before import—**no migration executed**.

## Production access restrictions

Under hold: no `firebase deploy`, no production Firestore/Auth operations, no emulator start during this remediation commit window. No evidence of production modification from this remediation edit set.

## CASE-LIFECYCLE-001 WIP

Uncommitted CASE-LIFECYCLE and unrelated iOS changes were **not** reverted or staged as part of isolation remediation commits (see Git section in engineering completion report).

## PA acceptance status

**Runtime isolation verification complete** — PA review recommended for **COMPLETE—VERIFIED** on SIBOL-FIREBASE-ISOLATION-001 scope. General Firebase safety hold for **CASE-LIFECYCLE-001** remains until PA explicitly releases it.

## Recommended next authorization request

1. Accept SIBOL-FIREBASE-ISOLATION-001 (**COMPLETE—VERIFIED**).
2. Optional: commit startup/health script fixes noted above.
3. Optional: authorized demo **seed** (separate hold) if full QA anchor health exit 0 is required.
4. Explicit **CASE-LIFECYCLE-001** hold release before resuming Firebase-connected lifecycle implementation or tests.
