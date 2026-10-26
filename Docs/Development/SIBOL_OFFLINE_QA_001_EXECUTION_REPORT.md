# SIBOL-OFFLINE-QA-001 — Verified emulator data and offline acceptance

**Initial checkpoint handover:** `d6b19f43-8a72-4e50-bc31-9f2d607e14a8`  
**Closure handover:** `7c78cd67-cbcc-487f-8a05-a0b9c4b6eb53`  
**Work items:** SIBOL-OFFLINE-QA-001, SIBOL-OFFLINE-QA-CLOSE-001  
**Prototype tag:** `sibol-prototype-2026-10-26-offline-qa` (annotated; not production release)

## Purpose

Preserve and document Product Owner–accepted **offline prototype QA** (O1–O8) on the local Firebase emulator stack, including emulator exports for academic demonstration and project closure.

**This checkpoint is not production readiness or final legal/project closure.**

---

## Offline QA acceptance summary (O1–O8)

| Step | Scope | Evidence type | Result |
|------|--------|---------------|--------|
| O1 | Teen — offline assistance submit | **Manual UI** (PO) | **PASS** |
| O2 | Teen — kill app, reopen offline | **Manual UI** (PO) | **PASS** |
| O3 | Teen — reconnect sync | **Manual UI** (PO) | **PASS** |
| O4 | Barangay — cached case list offline | **Manual UI** (PO) | **PASS** |
| O5 | Barangay — offline case edit + follow-up sync | **Manual UI** (PO) + **backend** (EA read-only) | **PASS** |
| O6 | Barangay — reconnect after pending writes | **Manual UI** (PO) | **PASS** (within O3–O5 sessions) |
| O7 | Barangay — offline aggregate report submit | **Manual UI** (PO) + **backend** (EA `9f6c4a82-…`) | **PASS** |
| O8 | MOPH — offline reopen of submitted aggregate report | **Manual UI** (PO) | **PASS** |

W1 coordination anchors from prior QA-001 remain in the same emulator dataset (teen assistance, barangay ack, MOPH referral).

### O5 backend anchors (EA)

| Record | Path |
|--------|------|
| Maria Offline Test | `cases/fhcQrLxE0IhwPFzCPinH` — `QA-OFFLINE-CASE-001`, `QA-OFFLINE-EDIT-001` |
| Follow-up | `cases/fhcQrLxE0IhwPFzCPinH/followUps/hmqFPpUNlQcf5z9UftwC` — `QA-OFFLINE-FOLLOWUP-001` |

### O7 manual evidence (PO)

| Field | Value |
|-------|--------|
| Account | `barangay.demo@sibol.local` |
| Organization | `barangay03` (`Barangay 3 (Poblacion)`) |
| Report reference | `rpt-1792977276032033-991721059` |
| Displayed submission time | 26 October 2026, 9:15 AM (UTC+8) |
| Aggregate | total **1**, active **1**, follow-up scheduled **0**, completed **0**, closed **0** |
| UX | Awaiting server confirmation offline → `submitted` after reconnect |

### O7 backend evidence (EA handover `9f6c4a82-1d35-4e79-9c20-6b8f3d72a145`)

| Check | Result |
|-------|--------|
| Path | `reports/rpt-1792977276032033-991721059` |
| `orgId` | `barangay03` |
| `reportStatus` | `submitted` |
| `submittedAt` | `2026-10-26T01:15:22.060Z` (9:15 AM UTC+8) |
| Counts | 1 / 1 / 0 / 0 / 0 — **match manual QA** |
| Duplicates | **1** document with this id (sole doc in `reports`) |
| Privacy | Aggregate fields only; no case ids, teen narrative, or `demoName` on report document |
| MOPH destination field | **Not in schema** — MOPH read via rules (`hospital01` pilot coordination capability) |

`barangay` on the report is the site label `Barangay 3, Balingasag` (not the directory display name `Barangay 3 (Poblacion)`).

### O8 evidence (PO)

MOPH (`moph.demo@sibol.local`, `hospital01`) opened the same report online, then viewed it again in airplane mode with expected reference and counts — **no loading/permission failure observed in UI**. Backend re-verification of client cache behavior is **out of scope** for O8; persisted `reports/*` supports online inbox/detail.

---

## Emulator checkpoints

### Interim export (pre–O7/O8)

| Field | Value |
|-------|--------|
| Directory | `.firebase-qa-backups/offline-qa-accepted-20261026-084832/` |
| When | 2026-10-26 08:48:32 |
| Note | Does **not** include O7 aggregate report; **preserved unchanged** |

### Final closure export (O1–O8 complete)

| Field | Value |
|-------|--------|
| **Directory** | `.firebase-qa-backups/offline-qa-closure-20261026-095408/` (**gitignored**) |
| **Command** | `firebase emulators:export .firebase-qa-backups/offline-qa-closure-20261026-095408 --project sibol-286d0` |
| **When** | 2026-10-26 09:54:08 (local) |
| **Services** | Firestore + Authentication |
| **Running stack** | Not reset; import origin still `pre-prototype-003-20261025` + session mutations |
| **Result** | **SUCCESS** |

**Export content verification (string presence in `firestore_export/.../output-0`):**  
`rpt-1792977276032033-991721059`, Maria case id, all three offline QA markers, teen assistance id `32sQiFj9v8T6R6T3Asih`, follow-up id `hmqFPpUNlQcf5z9UftwC` — **present**.

**SHA-256 manifest:** `SHA256MANIFEST.txt` in backup directory — `shasum -a 256 -c SHA256MANIFEST.txt` — **all files OK**.

| File | SHA-256 |
|------|---------|
| `firebase-export-metadata.json` | `abd2b79bf499cec0344dde85f30aae5fee5a06fd6ebd51db1729182f5f5ea156` |
| `auth_export/accounts.json` | `683da127b70c7990fac8339f38a627639b379e77e37b497d7ed253922eb79bac` |
| `firestore_export/.../output-0` | `d30eb47fe2a35dea995697fccaa45b183226c35c2368299a20e975a8a3da5bba` |

**Recovery:** [SIBOL_OFFLINE_QA_001_EMULATOR_RECOVERY.md](../Operations/SIBOL_OFFLINE_QA_001_EMULATOR_RECOVERY.md).

---

## Environment (closure session)

| Item | Value |
|------|--------|
| Firebase project | `sibol-286d0` (emulators only) |
| Firestore | `127.0.0.1:8195` |
| Auth | `127.0.0.1:9099` |
| Functions | `127.0.0.1:5001` |
| Git at closure docs | `4789f91` → documentation commit on `main` (see git log) |

---

## Deferred enhancement

**SIBOL-OFFLINE-REQ-001** — pending submission cancellation and draft retention: **NOT APPROVED / NOT AUTHORIZED**.  
See [SIBOL_OFFLINE_REQ_001_DEFERRED_ENHANCEMENT.md](SIBOL_OFFLINE_REQ_001_DEFERRED_ENHANCEMENT.md).

---

## Prototype development commitment boundary

**Unpaid prototype development commitment ends 29 October 2026.**

After that date, further development, maintenance, or enhancements require a **separately agreed arrangement**. This statement is a **project planning boundary** only; it does not resolve intellectual-property ownership or other legal terms.

---

## Known limitations (prototype)

- Not production Firebase, release signing, or full security re-audit.
- Offline UX uses Firestore persistence; server rejection after local queue is not fully surfaced for all flows.
- W2 concurrent edits: last-write-wins; no conflict UI.
- W3 aggregate counts frozen at queue time; disclaimers when cache incomplete.
- O8 validates MOPH **client** offline read of previously loaded aggregate data, not a separate server export.
- Auth export in backups is **sensitive** — never commit.
- Functions emulator code is not in Firestore/Auth export.

---

## Determination

**PASS** — O1–O8 accepted; final emulator checkpoint exported, manifest verified, and documented for offline-QA prototype baseline tag.
