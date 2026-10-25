# SIBOL-PROTOTYPE-003 — Emulator backup and recovery

> **Not for production.** Canonical ports: Auth **9099**, Firestore **8195**, Functions **5001**.

## Current backup (2026-10-25)

| Field | Value |
|-------|--------|
| Location | `.firebase-qa-backups/pre-prototype-003-20261025/` (gitignored) |
| Mechanism | `firebase emulators:export` while emulators were running |
| `firebase-export-metadata.json` SHA-256 | `abd2b79bf499cec0344dde85f30aae5fee5a06fd6ebd51db1729182f5f5ea156` |
| `auth_export/accounts.json` SHA-256 | `50531c4763560fc9da65489e242c6567c28909fdc15c3f9287684b136d0a0507` |
| `firestore_export.overall_export_metadata` SHA-256 | `610a6a8384e332e0d0c031652f4d81d77ead272fb286cc0ef874565322988396` |

**Read-only anchor checks (live emulator at export time):**

- `teenAssistanceRequests/32sQiFj9v8T6R6T3Asih` — exists, `status: acknowledged`, `orgId: barangay03`
- `barangayCoordinationRegistry/32sQiFj9v8T6R6T3Asih` — exists
- `caseCoordinationThreads/CxsRXE0ciuhrxXa1L0Ay` — exists (note QA report thread id typo `…XalL0Ay` vs live `…Xa1L0Ay`)
- `users/pjHSdYK7Vh2qYAnBzu6FmMeWjUMU` — exists (QA teen)

Older backups (`pre-fix-002`, `pre-moph-referral-001`, etc.) are preserved; **do not** restore them over `pre-prototype-003-20261025` for acceptance prep.

## Recovery procedure (requires PA authorization)

Only if emulators must be restarted:

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL
./shared/scripts/start-demo-emulators.sh --import=.firebase-qa-backups/pre-prototype-003-20261025
```

Then verify:

```bash
node shared/scripts/verify-canonical-emulator-health.mjs
```

**Do not** use `--export-on-exit` to a different path without copying this backup first.

## Functions code refresh

If callables are missing after a restart, rebuild before start (script already runs `npm run build`):

```bash
cd shared/functions && npm run build
```
