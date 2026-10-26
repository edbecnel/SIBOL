# SIBOL-OFFLINE-QA-001 — Emulator backup and recovery

> **Not for production.** Canonical ports: Auth **9099**, Firestore **8195**, Functions **5001**.

## Current offline-accepted backup (2026-10-26)

| Field | Value |
|-------|--------|
| Location | `.firebase-qa-backups/offline-qa-accepted-20261026-084832/` (gitignored) |
| Mechanism | `firebase emulators:export` while emulators were running |
| Execution report | [SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md](../Development/SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md) |
| SHA-256 manifest | `SHA256MANIFEST.txt` inside the backup directory |

**Supersedes** `pre-prototype-003-20261025` for **offline QA acceptance** evidence (cases, follow-ups, and post–QA-001 coordination state). Older backups remain on disk for history; do not restore an older tree over this checkpoint without PA authorization.

**Read-only anchor checks (live emulator at export time):**

- `teenAssistanceRequests/32sQiFj9v8T6R6T3Asih` — acknowledged, `orgId: barangay03`
- `barangayCoordinationRegistry/32sQiFj9v8T6R6T3Asih` — exists
- `caseCoordinationThreads/CxsRXE0ciuhrxXa1L0Ay` — `phase: referred`
- `cases/fhcQrLxE0IhwPFzCPinH` — Maria Offline Test; notes include `QA-OFFLINE-CASE-001`, `QA-OFFLINE-EDIT-001`
- `cases/fhcQrLxE0IhwPFzCPinH/followUps/hmqFPpUNlQcf5z9UftwC` — `QA-OFFLINE-FOLLOWUP-001`

## Recovery procedure (requires PA authorization)

Only if emulators must be restarted to resume from this checkpoint:

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL
./shared/scripts/start-demo-emulators.sh --import=.firebase-qa-backups/offline-qa-accepted-20261026-084832
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
