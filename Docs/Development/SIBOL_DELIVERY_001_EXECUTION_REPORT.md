# SIBOL-DELIVERY-001 — Execution report (pre-approval)

**Handover UUID:** `f3a718c2-6d49-4e05-b832-9c74d0a1e956`  
**Git HEAD (prep):** `8adb841`  
**Firebase:** `sibol-286d0`  
**Status:** **STOPPED AT APPROVAL GATE** — no live writes, deploys, or Auth changes performed

## Summary

Live Firebase is far behind the current app and emulator stack. A **full emulator export import is not feasible** (Auth passwords are not exportable; UIDs differ; QA records must not move). Prepared **selective idempotent migration** tooling, **read-only live inventory**, **Functions/rules gap analysis**, and a **live-target Android release APK** for Frecy.

## Local vs live (discovery)

| Area | Local emulator snapshot | Live `sibol-286d0` (read-only) |
|------|-------------------------|--------------------------------|
| Canonical export | `.firebase-qa-backups/po-case-identity-prep-20261026-1832` | N/A |
| Auth accounts | 12 emails (incl. 5 QA/non-demo) | 3 emails (`teen|barangay|moph.demo@sibol.local`) |
| Firestore `users` | (in export; not parsed here) | 3 |
| `cases` | — | 6 |
| `teenAssistanceRequests` | — | 5 |
| Barangay label | Mixed (PSGC-style in QA) | `Barangay Tres, Balingasag` (legacy) |
| Cloud Functions deployed | Full repo set when emulators run | **1** (`createCoordinationReferral`) |
| Firestore rules (repo) | `firestore.rules` @ HEAD (~24k) | Live rules **not** equivalent to repo (CLI fetch ≠ repo size) |

**Emulator export does not migrate:** rules, indexes, Functions code, or Auth password material.

## Migration approach (selected)

1. **Backup live** Firestore (and optionally Auth metadata) to a PO-approved GCS bucket **before any write**.
2. **Deploy** `firestore.rules`, `firestore.indexes.json`, and **all** Functions from repo `main` @ HEAD.
3. **Data:** idempotent `shared/provisioning` seed (create missing Auth by email; **never** change existing passwords; skip existing `demo-case-*` docs).
4. **Org mapping:** `shared/migration` dry-run/execute for `orgId` / membership alignment on existing live documents (no QA case ids).
5. **Exclude** emulator-only QA accounts and Maria Offline Test–class records unless separately approved.

UID preservation on live: **only when Auth user already exists for that email**; new users get new UIDs.

## Dry-run results

Command: `cd shared/delivery && npm run dry-run`

| Check | Result |
|-------|--------|
| Emulator export auth inventory | 12 accounts; **5 flagged QA/non-demo** (excluded from migration manifest) |
| Live inventory | 3 Auth users; counts as in table above |
| Functions compare | **32 repo exports missing on live**, including all demo-critical callables except `createCoordinationReferral` |
| Live writes | **None** |

Demo-critical missing on live (must deploy): `regRegisterTeenAccount`, `regSubmitTeenAssistanceRequest`, `regAcknowledgeTeenAssistanceRequest`, `regResolveRegisteredTeenForCase`, `regListRegisteredTeensForCase`, `regListBarangayDirectory`, `regSyncRegisteredTeenCasesFromProfile` (disabled stub), `healthCheck`, plus admin/registration callables as needed.

**Reporting:** `submitReport` callable in repo returns `failed-precondition` (Tranche 2). Aggregate reporting on live may rely on client Firestore writes per `features/reporting/README.md` — verify after rules deploy.

**Case identity:** App @ `8adb841` expects disabled `regSync` and independent profile/case fields — requires deployed Functions + current rules.

## Backup readiness

| Item | Status |
|------|--------|
| Emulator snapshot on disk | **Yes** — `po-case-identity-prep-20261026-1832` |
| Live Firestore export | **Not run** — requires PO-approved GCS bucket and one `gcloud firestore export` command |
| Rollback plan | Restore Firestore export; redeploy previous rules/functions from last known tag |

## Frecy Android APK (live Firebase)

| Item | Detail |
|------|--------|
| Built | **Yes** — `app-release.apk` (~57 MB) |
| SHA-256 | `765ba5f43f00f5931b4f05e664ed8a411a2e3f07fa6e5d6b0bf489f12f294311` |
| Dart defines | `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false` |
| Install doc | [SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md](../Operations/SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md) |

APK is **not** committed (build artifact). Transfer to phone when ready.

## Demo account inventory (emails only)

**Live (existing):** `teen.demo@sibol.local`, `barangay.demo@sibol.local`, `moph.demo@sibol.local`

**Emulator-only (do not migrate without approval):** `maria.qa.staff@sibol.local`, `moph.qa.staff@sibol.local`, `teen.qa02@example.com`, `teen.qa03@example.com`, `teen.qa006.agent@example.com`

**Additional fictional emulator staff (optional after deploy):** `central.admin@sibol.local`, `barangay.org.admin@sibol.local`, `backup.barangay.admin@sibol.local`, `moph.org.admin@sibol.local` — provision via emulator seed tooling or extended live provisioning, not raw export import.

## Product Owner approval request (single gate)

Reply **APPROVE LIVE DELIVERY** only if all of the following are acceptable:

1. **Backup:** Run Firestore export to a bucket you designate (engineering executes; no passwords in repo).
2. **Deploy to `sibol-286d0`:** Current `firestore.rules`, `firestore.indexes.json`, and **full** Cloud Functions from repo `main`.
3. **Data migration:** Idempotent demo provisioning + orgId migration scripts — **create** missing demo resources; **no** password resets; **no** overwrite of existing `demo-case-*` documents; **exclude** QA emulator accounts.
4. **Auth:** Create Auth users only for approved fictional emails that are missing; existing demo passwords unchanged.

**Not included unless you ask:** deleting live data, importing QA cases, iOS build, Play Store publish, weakening security rules.

## Remaining blockers

1. **PO approval** for backup + deploy + data steps above.
2. **GCS backup bucket** name/IAM for `gcloud firestore export`.
3. **Demo passwords** in password manager for provisioning dry-run/live seed (env vars — not sent to engineering in chat).
4. **Live backend deploy** required before Frecy’s full walkthrough (teen registration, assistance, case identity callables).
5. **Release keystore** optional; current APK uses debug signing (fine for academic sideload).

## Tooling added

- `shared/delivery/` — `npm run dry-run`, `inventory-export`, `compare-functions`
- This report and Frecy install guide
