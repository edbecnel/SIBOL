# MVR-FIREBASE-PROD-INTEGRITY-001 — Production Firebase historical integrity

**Work item:** SIBOL-FIREBASE-PROD-INTEGRITY-001  
**Handover UUID (Phase 2):** `7b4f2d81-9a36-4c75-b0e2-6d184f9ac523`  
**Phase 1 plan:** `prod_firebase_integrity_phase1_c3e4d0e9.plan.md`  
**Production project:** `sibol-286d0` (project number `1057794781295`)  
**Repository HEAD at investigation:** `5e53dbfcbefafab95e3c19cdf5a0ba3868c18beb`  
**Investigation date:** 2026-11-01  
**Classification:** **INDETERMINATE** (Firestore mutations); **NO RELEVANT ACTIVITY OBSERVED** (Cloud Functions / Cloud Run logs in primary window)

---

## 1. Authorization and boundaries

| Boundary | Status |
|----------|--------|
| PO Phase 2 read-only production inspection | **Authorized** (`7b4f2d81`) |
| Production Firestore/Auth read or write via SDK | **Not performed** |
| Production callable invocation | **Not performed** |
| Deploy, seed, IAM, logging config changes | **Not performed** |
| Raw audit exports in git | **Not committed** (sanitized summary only) |

**Read-only methods used:** `gcloud projects describe`, `gcloud logging read`, `gcloud logging logs list`, `gcloud projects get-iam-policy` (partial), `gsutil ls` (backup prefix listing). All commands used explicit `--project=sibol-286d0`.

**Active identity:** Human Google account (redacted in this report); default gcloud project confirmed as `sibol-286d0` before queries.

---

## 2. Historical periods examined

| Period | Purpose |
|--------|---------|
| **Primary (Phase 1 window):** `2026-10-30T13:00:00Z` → `2026-11-01T01:00:00Z` | Cursor emulator + automated test activity (Nov 1 UTC+8 morning) |
| **Extended (local evidence):** `2026-11-01T00:00:00Z` → `2026-11-01T04:00:00Z` | Covers full Nov 1 UTC+8 device test day through ~noon local |
| **Adjacent baseline:** `2026-10-29T00:00:00Z` → `2026-10-31T00:00:00Z` | Log volume comparison |
| **Reference (pre-window production activity):** `2026-10-28T00:00:00Z` → `2026-10-28T23:59:59Z` | Legitimate Cloud Functions traffic (not attributed to Nov 1 Cursor session) |
| **Marker search:** `2026-10-01` → `2026-11-05` | Synthetic test strings / demo emails in log text |

---

## 3. Available log sources and coverage

| Source | Available in project | Retention / coverage notes |
|--------|----------------------|----------------------------|
| Cloud Run / Functions (`run.googleapis.com/*`) | **Yes** | Entries observed on **2026-10-28**; **zero** entries in primary window |
| Cloud Audit — Activity (`cloudaudit.googleapis.com/activity`) | **Log name exists** | **Zero** entries returned for primary and Oct 29–31 windows |
| Cloud Audit — Data Access (`cloudaudit.googleapis.com/data_access`) | **Not observed** | Queries returned **no** entries (likely **not enabled** or empty) |
| Firestore API (`firestore.googleapis.com` / `cloud_firestore_database`) | **Not observed** | **No** document-level audit entries in sampled queries |
| Firebase Auth / Identity Platform activity logs | **Not queried successfully** | No dedicated identity log stream identified in `logs list` sample |
| GCS backup metadata | **Yes** (read-only list) | `gs://sibol-286d0-delivery-backups/pre-delivery-20261027T023121Z/` — export dated **2026-10-27** (before incident window); **not** compared document-by-document |

**Critical limitation:** Absence of **Firestore Data Access** audit logs means **production Firestore reads/writes cannot be confirmed or ruled out** from Cloud Logging alone.

---

## 4. Queries performed (summary)

| # | Target | Filter (abbrev.) | Result |
|---|--------|------------------|--------|
| Q1 | Any logs | Primary window timestamps | **0 entries** (`[]`) |
| Q2 | Firestore | `firestore.googleapis.com` / `cloud_firestore_database` | **0 entries** |
| Q3 | Cloud Functions / Run | `cloud_run_revision` in primary window | **0 entries** |
| Q4 | Cloud Audit Activity | `cloudaudit.googleapis.com/activity` | **0 entries** (primary + Oct 29–31) |
| Q5 | Data Access audit | `cloudaudit.googleapis.com/data_access` | **0 entries** (any time sample) |
| Q6 | Extended Nov 1 | `2026-11-01T00:00Z`–`04:00Z` | **0 entries** |
| Q7 | Callable names (Oct 28 baseline) | `regSubmitTeenAssistanceRequest`, `createCoordinationReferral`, etc. | **Activity on 2026-10-28 only** |
| Q8 | Test markers | `consent-referral acceptance` text | **0 entries** |
| Q9 | GCS backups | `gsutil ls` delivery backup prefix | **Metadata only** (2026-10-27 export) |

All queries: `--project=sibol-286d0`, read-only. No retries after empty results except adjacent window expansion per handover §3.

---

## 5. Findings by service (mandatory classifications)

### Firestore (document operations)

| Classification | **INSUFFICIENT EVIDENCE** |
|----------------|---------------------------|
| Rationale | No Firestore Data Access audit stream; no `firestore.googleapis.com` log lines in primary window. Client SDK writes would not appear in Functions logs. |
| Writes/deletes in primary window | **Not established** |
| Reads in primary window | **Not established** |

### Cloud Functions / Cloud Run (callables)

| Classification | **NO RELEVANT ACTIVITY OBSERVED IN AVAILABLE RECORDS** (primary window) |
|----------------|--------------------------------------------------------------------------|
| Rationale | Zero `run.googleapis.com` log entries Oct 30 13:00 UTC – Nov 1 04:00 UTC. |
| Target callables (`regSubmitTeenAssistanceRequest`, `regAcknowledgeTeenAssistanceRequest`, `createCoordinationReferral`, disclosure/case lifecycle names) | **None invoked** in primary window per available logs |
| Oct 28 reference activity | **Observed** (e.g. `regsubmitteenassistancerequest`, `createcoordinationreferral`) — **outside** primary window; **not** attributed to Cursor Nov 1 emulator testing without principal/workstation evidence |

### Firebase Authentication

| Classification | **INSUFFICIENT EVIDENCE** |
|----------------|---------------------------|
| Rationale | No Identity Platform / Auth audit logs retrieved; no sign-in performed as part of investigation. |
| Synthetic demo emails in logs | **Not found** in searchable text queries (Oct–Nov sample) |

### Administrative activity

| Classification | **NO RELEVANT ACTIVITY OBSERVED IN AVAILABLE RECORDS** (primary window) |
|----------------|--------------------------------------------------------------------------|
| Rationale | Zero Cloud Audit Activity entries in primary window. |
| Deployments / IAM changes | **Not observed** in window (does not exclude out-of-band activity without logs) |

### Production data integrity comparison

| Classification | **NOT APPLICABLE** |
|----------------|-------------------|
| Rationale | No pre/post Firestore export snapshot pair within or straddling the primary window suitable for diff; only 2026-10-27 backup prefix listed. **No new export initiated.** |

---

## 6. Correlation with Cursor local testing

| Phase 1 local evidence | Production log correlation |
|------------------------|----------------------------|
| Firestore emulator JVM (`firestore-debug.log`, Nov 1 ~05:28–08:07 UTC+8) | **Consistent with local emulator**, not cloud logging |
| Flutter integration tests (`emulator-5554`, `USE_FIREBASE_EMULATORS=true`) | **No** matching Cloud Functions invocations in primary window |
| Misconfigured client project id `sibol-286d0` against **local** emulator | Documented in isolation audit; **not** cloud endpoint evidence |
| Synthetic markers (`*.demo@sibol.local`, fictional consent text) | **Not found** in production logs (Oct–Nov search) |

**Attribution to Cursor testing:** **No corroborating production log evidence** in the primary window. Oct 28 production callable traffic **predates** the incident window and is treated as **unrelated** absent attribution fields (principal email not populated on sampled Oct 28 entries).

**First credible production event tied to Nov 1 Cursor session:** **None identified** in available records.

---

## 7. Required conclusions

| Question | Answer |
|----------|--------|
| Production Firestore **writes/deletes** confirmed from testing? | **No** — **not confirmable** (INSUFFICIENT EVIDENCE) |
| Production Firestore **reads** confirmed? | **No** — **not confirmable** |
| Production **Auth / Functions** access confirmed in primary window? | **Functions:** none in logs; **Auth:** unknown |
| Activity attributable to **Cursor testing**? | **No evidence found** in available records |
| Unexpected production data changes identified? | **No** (no data inspected) |
| Periods lacking evidence? | **All Firestore document ops**; **Auth**; primary window otherwise **empty** |
| Is “production was untouched” demonstrably supportable? | **No** — stronger statement not justified; see executive finding |

---

## 8. Executive finding

**PRODUCTION FIRESTORE MODIFIED BY CURSOR TESTING: NO EVIDENCE FOUND**

*(This is not proof of zero modification. Firestore Data Access logging was not available. Direct client Firestore access in the primary window cannot be excluded from logging gaps alone.)*

---

## 9. Residual uncertainty

1. **Firestore Data Access audit** — not present in query results; document-level production mutations during the primary window remain **INDETERMINATE**.
2. **Empty primary window** — strongly suggests **no Cloud Functions / Cloud Run** production traffic during Cursor emulator testing; does **not** cover direct Firestore SDK or Admin SDK paths with ADC.
3. **Oct 28 production callables** — confirm legitimate non-test operations separately; **outside** primary incident window.
4. **Log retention** — if retention < incident window, results would under-report; Oct 28 logs still visible, so total project log absence Oct 29–Nov 1 is **notable**.

---

## 10. Production modification during investigation

**Confirmed:** No production resources were modified during Phase 2 (read-only CLI only).

---

## 11. Related controls

| Control | Status |
|---------|--------|
| Firebase application testing gate | **CLOSED** (unchanged) |
| SIBOL-FIREBASE-ISOLATION-001 remediation | **Separate** — not implemented under this handover |
| Protected tag `SIBOL-PRE-ENHANCEMENT-2026-10-29` | **Not modified** |

---

## 12. Evidence references (sanitized)

- Phase 1 timeline: `prod_firebase_integrity_phase1_c3e4d0e9.plan.md`
- Local emulator log: `firestore-debug.log` (repository root, not committed)
- Git commits: `de1e079`, `5e53dbf` (2026-11-01 UTC+8) — emulator-focused verification
- Cloud Logging: `gcloud logging read` — primary window **0** entries; Oct 28 baseline **present**; project `sibol-286d0` verified via `gcloud projects describe`
- GCS: `gs://sibol-286d0-delivery-backups/pre-delivery-20261027T023121Z/` metadata list only

**Raw log JSON not stored in repository.**
