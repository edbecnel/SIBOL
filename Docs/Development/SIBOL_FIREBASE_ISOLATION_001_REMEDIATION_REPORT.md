# SIBOL-FIREBASE-ISOLATION-001 — Remediation Report

**Work item:** SIBOL-FIREBASE-ISOLATION-001  
**Handover UUID:** `7b3f91c2-6e48-4d15-a0c7-9f82e5b31460`  
**Branch:** `main`  
**Classification:** **IMPLEMENTED—ACCEPTANCE PENDING** (runtime emulator gates not executed under current hold)

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

## Runtime verification pending (requires PA release of emulator hold)

1. Start emulators via `shared/scripts/start-demo-emulators.sh` and confirm process uses `--project demo-sibol-emulator`.
2. Run `./shared/scripts/validate-local-firebase-isolation.sh` (full gate, ports reachable).
3. Run `./shared/scripts/validate-int-001-emulator.sh` with emulators up.
4. Run `node shared/scripts/verify-canonical-emulator-health.mjs`.
5. Run provisioning preflight with `--check-reachable` after seed workflow (authorized separately).

## `.emulator-data` / snapshot status

Read-only inspection: `.emulator-data` directory **not present** in this workspace clone (nothing deleted during remediation). If snapshots exist on other machines, verify `firebase-export-metadata.json` project id compatibility with `demo-sibol-emulator` before import—**no migration executed**.

## Production access restrictions

Under hold: no `firebase deploy`, no production Firestore/Auth operations, no emulator start during this remediation commit window. No evidence of production modification from this remediation edit set.

## CASE-LIFECYCLE-001 WIP

Uncommitted CASE-LIFECYCLE and unrelated iOS changes were **not** reverted or staged as part of isolation remediation commits (see Git section in engineering completion report).

## PA acceptance status

**Pending** — awaiting PA review of static evidence and explicit authorization for runtime verification.

## Recommended next authorization request

Request **runtime isolation verification** only: emulator start, `validate-local-firebase-isolation.sh`, INT-001 preflight, and (if approved) a single seeded demo smoke—still **no** production deploy and **no** CASE-LIFECYCLE Firebase-connected implementation until hold release.
