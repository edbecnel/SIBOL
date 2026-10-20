# SIBOL-FB-002 Phase A — Execution report

**Handover UUID:** `7e4b0f93-8c26-4d51-a9f0-62e8c5d31b74`  
**Date:** 2026-10-20  
**Phase:** A — Provisioning infrastructure hardening  
**Git commit/push:** Not performed (not authorized)  
**Firebase writes / deploy / Auth changes:** None

## 1. Files modified or created

| Path | Action |
|------|--------|
| `shared/provisioning/package.json` | Created |
| `shared/provisioning/seed_tranche1_demo.mjs` | Created (main entry) |
| `shared/provisioning/src/constants.mjs` | Created |
| `shared/provisioning/src/config.mjs` | Created |
| `shared/provisioning/src/case_payloads.mjs` | Created |
| `shared/provisioning/src/schema_validate.mjs` | Created |
| `shared/provisioning/src/preflight.mjs` | Created |
| `shared/provisioning/src/provision.mjs` | Created |
| `shared/provisioning/test/preflight.test.mjs` | Created |
| `shared/scripts/seed_tranche1_demo.mjs` | Modified (launcher only) |
| `shared/docs/DEMO_ACCOUNTS.md` | Modified (env-based passwords) |
| `shared/docs/PROVISIONING.md` | Created |
| `Docs/Development/FIREBASE_SETUP.md` | Modified (provisioning pointers) |
| `.gitignore` | Modified (`shared/provisioning/node_modules/`) |

`shared/provisioning/package-lock.json` and `node_modules/` exist locally after `npm install` (gitignored).

## 2. Credential hardening

- Removed hardcoded passwords from tracked seed source (logic moved to `shared/provisioning/`).
- Passwords read from `SIBOL_DEMO_PASSWORD_TEEN`, `SIBOL_DEMO_PASSWORD_BARANGAY`, `SIBOL_DEMO_PASSWORD_MOPH`.
- Script exits with a clear error if any are missing.
- Dry-run and reports log emails and roles only — never password values.

### Prior tracked exposure (rotation recommended)

Before public Git publication, assume these **former** demo passwords are compromised if the repo was shared:

- Previously in `shared/scripts/seed_tranche1_demo.mjs` and `shared/docs/DEMO_ACCOUNTS.md` (patterns `SibolDemo-*-2026!`).

**Recommendation:** If demo users already exist in `sibol-286d0`, reset passwords via Firebase Console or delete and re-provision after Phase B authorization. If users were never created, rotation is still recommended before first live seed.

## 3. Node dependency solution

- Dedicated package `shared/provisioning/` declares `firebase-admin@^12.6.0`.
- Run `npm install` in that directory; imports resolve from `shared/provisioning/node_modules` without `NODE_PATH`.
- `shared/scripts/seed_tranche1_demo.mjs` spawns the provisioning entry with `cwd` set to `shared/provisioning`.

## 4. Administrative authentication findings

- Seed uses `applicationDefault()` (ADC).
- **Keyless (preferred for owners):** `gcloud auth application-default login` with an account granted Firebase Admin / appropriate IAM on `sibol-286d0`.
- **Existing key file:** `GOOGLE_APPLICATION_CREDENTIALS` if already issued (Phase A did not create keys).
- IAM unchanged. If ADC lacks Auth/Firestore permissions, live seed will fail at runtime — document required roles for owner approval.

## 5. Preflight / dry-run behavior

- `--dry-run`: local validation + operation plan; **no** Firebase initialization unless `--remote-read`.
- `--confirm-project=` must match `FIREBASE_PROJECT_ID` / `GCLOUD_PROJECT`.
- Validates demo emails, canonical roles, five `demo-case-00N` IDs, and fictional case payloads against `shared/contracts/case_record.schema.json` rules.
- `--remote-read`: optional Auth/Firestore reads to refine plan; still no writes.

## 6. Idempotency safeguards

- Existing Auth users: skip create; **never** update password.
- Existing `users/{uid}`: skip update if `role` or `active` differs from intended demo profile.
- Existing `cases/demo-case-*`: skip overwrite.
- Scope limited to three demo emails and five demo case IDs.

## 7. Cleanup procedure

Documented in [shared/docs/PROVISIONING.md](../../shared/docs/PROVISIONING.md): dry-run-first destructive cleanup for demo Auth users, profiles, cases, and follow-ups — **not implemented or executed** in Phase A.

## 8. Local test results

```bash
cd shared/provisioning && npm install && npm test
```

- 5 tests passed (project mismatch, missing passwords, validation pass, idempotent planning).
- CLI: missing passwords → exit 1; project mismatch → exit 1; `--dry-run` → exit 0, no Admin writes.

## 9. Remaining requirements before live provisioning

1. PA authorization for Firebase Auth + Firestore **writes**.
2. Owner sets `SIBOL_DEMO_PASSWORD_*` and ADC (or approved admin credentials).
3. Confirm IAM allows user create + Firestore writes on `sibol-286d0`.
4. Optional: run `--dry-run --remote-read` to preview against live project.
5. Address prior password exposure if demo users may exist.

## 10. Proposed live provisioning command

```bash
cd shared/provisioning
npm install
export FIREBASE_PROJECT_ID=sibol-286d0
# export SIBOL_DEMO_PASSWORD_* (from password manager)
npm run seed -- --confirm-project=sibol-286d0
```

## 11. Git status

Run `git status` in repo root before commit (Phase A: uncommitted changes expected).

## 12. Confirmations

| Activity | Performed |
|----------|-----------|
| Firebase Auth create/update/delete | **No** |
| Firestore write/delete | **No** |
| Firebase deploy | **No** |
| Service account key generation | **No** |
| IAM changes | **No** |
| Flutter / SpeakUp changes | **No** |
| Git commit/push | **No** |

**STOP — await PA authorization before live provisioning.**
