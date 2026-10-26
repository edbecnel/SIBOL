# SIBOL-OFFLINE-QA-001 — Verified emulator data checkpoint

**Handover UUID:** `d6b19f43-8a72-4e50-bc31-9f2d607e14a8`  
**Work item:** SIBOL-OFFLINE-QA-001  
**Starting HEAD:** `243c1be`  
**Application HEAD (unchanged):** `243c1be` — this checkpoint commit adds documentation only.  
**Authorization:** Non-destructive export of accepted offline QA evidence on the running canonical emulator stack.

## Purpose

Preserve the Product Owner–accepted offline workflow dataset (teen assistance, barangay acknowledgment, MOPH referral, case create/edit, follow-up sync) before continuing with offline aggregate-report testing.

## Pre-execution verification

| Check | Result |
|-------|--------|
| Git branch / HEAD | `main` @ `243c1be` |
| Firebase project | `sibol-286d0` (running hub @ `127.0.0.1:4400`) |
| Emulator starter | `./shared/scripts/start-demo-emulators.sh --import=.firebase-qa-backups/pre-prototype-003-20261025` (PID **3040**) |
| Auth | **9099** — healthy (`authEmulator.ready: true`) |
| Firestore | **8195** — healthy (HTTP **200**; seeded from `pre-prototype-003-20261025`, then mutated by QA sessions) |
| Functions | **5001** — healthy (`verify-canonical-emulator-health.mjs` **PASS**) |
| Prior `.firebase-qa-backups/` dirs | `pre-geo-fix-001`, `pre-fix-002`, `pre-moph-referral-001`, `pre-prototype-003-20261025` (preserved) |
| Export destination free | `.firebase-qa-backups/offline-qa-accepted-20261026-084832/` did not exist before export |

## Export

| Field | Value |
|-------|--------|
| **Timestamp (local)** | 2026-10-26 08:48:32 (`offline-qa-accepted-20261026-084832`) |
| **Directory** | `.firebase-qa-backups/offline-qa-accepted-20261026-084832/` (**gitignored; not committed**) |
| **Command** | `firebase emulators:export .firebase-qa-backups/offline-qa-accepted-20261026-084832 --project sibol-286d0` |
| **Mechanism** | Firebase Emulator Suite export against **running** hub (no stop/reset/reimport) |
| **Services in export** | **Firestore** + **Authentication** (per `firebase-export-metadata.json`) |
| **Not captured** | Functions emulator code/runtime state (reload via `shared/functions` build on restart) |
| **Result** | **SUCCESS** (`Export complete`) |

### Export artifact checks

| Artifact | Present | Nonempty |
|----------|---------|----------|
| `firebase-export-metadata.json` | Yes | Yes (255 B) |
| `auth_export/accounts.json` | Yes | Yes (5939 B) |
| `auth_export/config.json` | Yes | Yes |
| `firestore_export/firestore_export.overall_export_metadata` | Yes | Yes |
| `firestore_export/.../output-0` | Yes | Yes (15722 B) |

### SHA-256 manifest

| Field | Value |
|-------|--------|
| **Location** | `.firebase-qa-backups/offline-qa-accepted-20261026-084832/SHA256MANIFEST.txt` |
| **Verification** | `shasum -a 256 -c SHA256MANIFEST.txt` — **all listed files OK** |

Representative checksums (full list in manifest):

| File | SHA-256 |
|------|---------|
| `firebase-export-metadata.json` | `abd2b79bf499cec0344dde85f30aae5fee5a06fd6ebd51db1729182f5f5ea156` |
| `auth_export/accounts.json` | `152b8f10dafcb738935b99e1529f84f7f04bb54bf983b3322d78e0bb7db480b9` |
| `firestore_export/.../output-0` | `eba0f450bc90bca27f8487274a7ca62e429a88c4452890c6bd368302dc66d516` |

## Live emulator verification (post-export; read-only)

Emulators were **not** restarted. Firebase Admin against `FIRESTORE_EMULATOR_HOST=127.0.0.1:8195`:

### Maria Offline Test (case)

| Field | Value |
|-------|--------|
| Path | `cases/fhcQrLxE0IhwPFzCPinH` |
| Markers | `QA-OFFLINE-CASE-001`, `QA-OFFLINE-EDIT-001` — **both present** |

### Accepted follow-up

| Field | Value |
|-------|--------|
| Path | `cases/fhcQrLxE0IhwPFzCPinH/followUps/hmqFPpUNlQcf5z9UftwC` |
| Parent `caseId` | `fhcQrLxE0IhwPFzCPinH` |
| Marker | `QA-OFFLINE-FOLLOWUP-001` — **present** |

### QA-001 coordination anchors (unchanged)

| Record | Result |
|--------|--------|
| `teenAssistanceRequests/32sQiFj9v8T6R6T3Asih` | exists — `status: acknowledged`, `orgId: barangay03` |
| `barangayCoordinationRegistry/32sQiFj9v8T6R6T3Asih` | exists |
| `caseCoordinationThreads/CxsRXE0ciuhrxXa1L0Ay` | exists — `phase: referred` |

## Recovery

See [SIBOL_OFFLINE_QA_001_EMULATOR_RECOVERY.md](../Operations/SIBOL_OFFLINE_QA_001_EMULATOR_RECOVERY.md).

## Limitations

- Backup contains **Auth accounts** (password hashes in emulator export format) — treat as **sensitive local development data**; never commit or publish.
- Export reflects emulator state at checkpoint time; **running** stack may diverge until next export.
- Android app local cache is **not** part of this backup.
- Offline aggregate-report QA (O7/O8) was **not** started in this session.

## Determination

**PASS** — Export completed safely; manifest verifies; live emulator retains all accepted QA anchors after export.
