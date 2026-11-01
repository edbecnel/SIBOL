# MVR-FIREBASE-PROD-INTEGRITY-002 — Production Firestore backup-to-live comparison

**Work item:** SIBOL-FIREBASE-PROD-INTEGRITY-002  
**Handover UUID:** `b6f0a2d9-83c4-4a17-9e52-71d8c5f093ab`  
**Prior record:** [MVR-FIREBASE-PROD-INTEGRITY-001.md](./MVR-FIREBASE-PROD-INTEGRITY-001.md) (Cloud Logging; Firestore ops **INDETERMINATE**)  
**Production project:** `sibol-286d0` (default Firestore database `(default)`)  
**Repository HEAD (start):** `7203f254b39f2fd578caa365953c388fb535a705`  
**Repository HEAD (end):** `40ccf558e5053e743051bf0a57d38baeb5e09e9b`  
**Investigation date:** 2026-11-01  
**Classification:** **DATABASE CHANGED SINCE BASELINE**; **NO EVIDENCE** of Cursor Nov 1 testing writes on compared diffs

---

## 1. Authorization and boundaries

| Boundary | Status |
|----------|--------|
| PO-approved read-only production document comparison | **Authorized** (`b6f0a2d9`) |
| Production Firestore writes / deletes | **Not performed** |
| Firestore import or restore into production | **Not performed** |
| New GCS backup or backup mutation | **Not performed** |
| Production callable / Auth test sign-in | **Not performed** |
| SIBOL application runtime as comparison client | **Not used** |
| Raw inventories or PII in git | **Not committed** |

**Methods:** `gsutil ls` / metadata (GCS); local import of export into **Firestore Emulator** (port **8380**, isolated config); read-only Admin SDK recursive inventory against **live** `sibol-286d0` with **`FIRESTORE_EMULATOR_HOST` unset**; SHA-256 content fingerprints; server `createTime` / `updateTime` on changed paths only (no field values in this record).

**Utilities (repository):**

- `shared/provisioning/scripts/compare-firestore-readonly-inventory.mjs`
- `shared/provisioning/scripts/compare-firestore-readonly-diff.mjs`

---

## 2. Baseline backup verification

| Item | Value |
|------|--------|
| GCS prefix | `gs://sibol-286d0-delivery-backups/pre-delivery-20261027T023121Z/` |
| Reported export time | **2026-10-27T02:31:21Z** (delivery documentation / object naming) |
| Project identity | **`sibol-286d0`** (export taken from production delivery backup bucket for that project) |
| Export scope | `all_namespaces/all_kinds` (`*.overall_export_metadata`, `output-0`, `export_metadata`) |
| Completeness (export artifact) | **Single output shard** (~11.6 KiB); no additional shards listed under prefix |
| Other production exports in bucket | **None** — only this prefix under `gs://sibol-286d0-delivery-backups/` |
| Closer baseline to Nov 1 window | **No** — no newer export exists |

**Excluded from baseline:** None identified in export metadata (all kinds / all namespaces). **Live side** used the same recursive enumeration (root collections + subcollections). No secondary Firestore database compared.

---

## 3. Comparison method

1. **Backup side:** Downloaded export objects to a local temp workspace; imported into Firestore Emulator via `firebase emulators:exec` with `--import` (project id `sibol-286d0`, emulator port **8380** to avoid conflict with developer emulators on **8195**). Ran inventory script against emulator.
2. **Live side:** Ran inventory script with emulator env vars **cleared**; confirmed `emulator: null` and `count: 65`.
3. **Diff:** Path union; classify **ADDED**, **DELETED**, **MODIFIED** (fingerprint mismatch), **UNCHANGED** (fingerprint match).
4. **Attribution helper:** Read-only `get()` on each added/modified path; record server timestamps only.

Fingerprints canonicalize Firestore types (timestamps, geo, references, bytes) before hashing — export/import vs live Admin SDK representation differences were **not** observed on the **10** unchanged cross-check documents (including nested `followUps` and `staffEvents`).

---

## 4. Summary counts

| Classification | Count |
|----------------|------:|
| Backup documents | **30** |
| Current production documents | **65** |
| Unchanged | **10** |
| Added | **35** |
| Deleted | **0** |
| Modified | **20** |
| Not comparable | **0** |

**Documents differing from baseline (added + deleted + modified):** **55**

**Comparison completeness:** **COMPLETE** for default database `(default)` — full recursive inventory on live; full export imported to emulator for baseline. **Partial** historical certainty: backup is **2026-10-27**; cannot prove absence of transient writes that left no net diff.

---

## 5. Per-collection breakdown

| Collection | Backup | Live | Unchanged | Added | Deleted | Modified |
|------------|-------:|-----:|----------:|------:|--------:|---------:|
| assistanceAcknowledgmentIdempotency | 0 | 2 | 0 | 2 | 0 | 0 |
| assistanceSubmissionIdempotency | 0 | 2 | 0 | 2 | 0 | 0 |
| auditEvents | 0 | 12 | 0 | 12 | 0 | 0 |
| barangayCoordinationRegistry | 2 | 3 | 0 | 1 | 0 | 2 |
| caseCoordinationThreads | 6 | 9 | 4 | 3 | 0 | 2 |
| cases | 11 | 11 | 5 | 0 | 0 | 6 |
| organizationDirectory | 0 | 2 | 0 | 2 | 0 | 0 |
| organizationMemberships | 0 | 4 | 0 | 4 | 0 | 0 |
| organizations | 0 | 2 | 0 | 2 | 0 | 0 |
| reports | 3 | 3 | 0 | 0 | 0 | 3 |
| teenAssistanceRequests | 5 | 7 | 1 | 2 | 0 | 4 |
| users | 3 | 8 | 0 | 5 | 0 | 3 |

---

## 6. Privacy-safe difference inventory (evidence)

Document paths below use **`pathHash`** = first 12 hex chars of SHA-256(path). Fingerprints are SHA-256 of canonical field JSON (values not reproduced here).

### 6.1 ADDED (35)

| Collection | Count | Nature | Attribution evidence |
|------------|------:|--------|----------------------|
| assistanceAcknowledgmentIdempotency | 2 | Server-side idempotency records (callable pattern `{uid}__ack-…`) | **All** server timestamps **2026-10-28**; aligns with [MVR-001](./MVR-FIREBASE-PROD-INTEGRITY-001.md) Oct 28 callable activity; **none** on **2026-11-01** |
| assistanceSubmissionIdempotency | 2 | Server-side idempotency (`{uid}__assist-…`) | **2026-10-28** server timestamps |
| auditEvents | 12 | Audit trail documents (`aud_*`) | Created **2026-10-27** after backup cutoff (**02:31:21Z**) through **2026-10-28**; not present in Oct 27 export snapshot |
| organizationDirectory | 2 | Org directory (`barangay03`, `hospital01`) | Post-backup provisioning / feature data (timestamps after cutoff) |
| organizationMemberships | 4 | Membership bindings | Post-backup; consistent with org rollout |
| organizations | 2 | Organization root docs | Post-backup |
| barangayCoordinationRegistry | 1 | New registry doc | Post-backup |
| caseCoordinationThreads | 3 | New thread + `private/binding` + `staffEvents` | Post-backup coordination flow |
| teenAssistanceRequests | 2 | New assistance request docs | Post-backup |
| users | 5 | New Auth user profile docs | Post-backup sign-up / provisioning |

**Synthetic test markers:** No `*.demo@sibol.local`-style paths in added set. Idempotency keys match **production callable** naming, not Flutter test fixtures.

### 6.2 DELETED (0)

No document paths present in backup missing from live.

### 6.3 MODIFIED (20)

| Collection | Count | Nature | Attribution evidence |
|------------|------:|--------|----------------------|
| cases | 6 | Includes provisioned **`demo-case-001` … `demo-case-005`** and one non-demo case id | Server timestamps **after 2026-10-27T02:31:21Z**; demo ids are **authorized demonstration seed** ([PROVISIONING.md](../../shared/docs/PROVISIONING.md)); **no** **2026-11-01** timestamps |
| teenAssistanceRequests | 4 | Field updates on existing requests | Post-backup; **2026-10-28** activity plausible |
| reports | 3 | Reporting documents updated | Post-backup |
| barangayCoordinationRegistry | 2 | Registry updates | Post-backup |
| caseCoordinationThreads | 2 | Thread metadata updates (subdocs unchanged where listed in §6.4) | Post-backup |
| users | 3 | Profile updates on existing users | Post-backup |

### 6.4 UNCHANGED (10) — spot check

Includes nested paths under `caseCoordinationThreads/.../private/binding`, selected `staffEvents`, and multiple `cases/.../followUps/demo-followup-*` pairs — confirms subcollection coverage.

---

## 7. Timestamp correlation (changed paths only)

| Window | Changed paths with server `createTime`/`updateTime` |
|--------|------------------------------------------------------:|
| After backup cutoff **2026-10-27T02:31:21Z** | **55 / 55** |
| **2026-10-28** (calendar day UTC) | **12** (explicit Oct 28 timestamps) |
| **2026-11-01** (Cursor primary test day) | **0** |

This does **not** prove zero Nov 1 writes globally (e.g. writes that left no diff, or writes to paths that still match backup fingerprints). It **does** show that **every document that differs from the Oct 27 backup** last changed **before Nov 1** per Firestore server metadata.

---

## 8. Mandatory conclusions

| # | Question | Answer |
|---|----------|--------|
| 1 | Does current production Firestore match the pre-change backup? | **No** |
| 2 | How many documents differ? | **55** (35 added, 20 modified, 0 deleted) |
| 3 | Which collections contain differences? | See §5 — all listed collections except none with deletes only |
| 4 | Any differences attributable to Cursor automated testing? | **No direct evidence.** **Zero** Nov 1 server timestamps on all **55** differing documents; patterns match **authorized app/callable** traffic ([MVR-001](./MVR-FIREBASE-PROD-INTEGRITY-001.md) Oct 28 baseline) |
| 5 | Differences explained by authorized production operations? | **Plausible and consistent** — post-backup audit/org/coordination/idempotency/case updates; Oct 28 callable window documented in MVR-001 |
| 6 | Collections excluded? | **None** identified for `(default)` DB |
| 7 | Closer historical backup? | **No** — only `pre-delivery-20261027T023121Z` |
| 8 | Residual uncertainty? | Backup is **4+ days** before Nov 1; no Nov 1 export; cannot detect reverted writes; MVR-001 logging gap for undetected direct SDK writes remains for **non-diff** paths |

---

## 9. Executive findings

**HAS THE LIVE PRODUCTION FIRESTORE DATABASE CHANGED SINCE THE BACKUP?**  
**YES** — **55** document-level differences vs `pre-delivery-20261027T023121Z` (65 live docs vs 30 in backup snapshot).

**IS THERE EVIDENCE THAT CURSOR'S AUTOMATED TESTING MODIFIED PRODUCTION FIRESTORE?**  
**NO** — On the compared difference set, **no** document carries a **2026-11-01** server timestamp; diff patterns align with **post-backup production activity** (notably **2026-10-28** callable-related artifacts per MVR-001). This **does not** contradict MVR-001’s **INDETERMINATE** logging verdict for undetected writes that left no net diff.

---

## 10. Production modification during investigation

**Confirmed:** Investigation used read-only GCS listing, emulator-local import, and read-only Firestore `get` / list operations against live `sibol-286d0`. **No** production documents were created, updated, or deleted.

---

## 11. Related controls

| Control | Status |
|---------|--------|
| Firebase application testing gate | **CLOSED** (unchanged) |
| Protected tag `SIBOL-PRE-ENHANCEMENT-2026-10-29` | **Not modified** |

---

## 12. Evidence references (sanitized)

- GCS: `gsutil ls gs://sibol-286d0-delivery-backups/`
- Local working copies (deleted after report): `/tmp/sibol-prod-integrity-002/` — inventories, diff, metadata JSON **not** in repository
- Cross-reference: [MVR-FIREBASE-PROD-INTEGRITY-001.md](./MVR-FIREBASE-PROD-INTEGRITY-001.md)
