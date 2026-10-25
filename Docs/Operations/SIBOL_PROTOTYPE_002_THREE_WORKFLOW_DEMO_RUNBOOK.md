# SIBOL-PROTOTYPE-002 — Three-workflow demonstration runbook

> **Scope:** Fictional demonstration on **local Firebase emulators** (`sibol-286d0`) or preserved PO QA emulator data.  
> **Not for production.** Do not reseed or reset emulator data without separate PA authorization.

## 1. What you are demonstrating

| # | Workflow | Primary roles |
|---|----------|----------------|
| W1 | Teen assistance → Barangay acknowledge → Barangay referral → MOPH coordination inbox | Teen, Barangay staff, MOPH operational staff |
| W2 | Barangay confidential **case** list, detail, create/edit, follow-ups | Barangay staff with case capabilities |
| W3 | Barangay **aggregate report** submit → history/receipt → MOPH submitted reports | Barangay staff, MOPH operational staff |

PO acceptance reference for W1: [SIBOL_QA_001_ACCEPTANCE_REPORT.md](../Development/SIBOL_QA_001_ACCEPTANCE_REPORT.md) (preserve existing records).

## 2. Required emulator services

| Service | Canonical port | Config |
|---------|----------------|--------|
| Auth | 9099 | [firebase.json](../../firebase.json) |
| Firestore | 8195 | same |
| Cloud Functions | 5001 | same |
| Emulator UI | 4000 | optional |

**Functions build (required for W1 acknowledgment):** app @ `1382431+` calls `regAcknowledgeTeenAssistanceRequest`. After pulling current `main`, run `cd shared/functions && npm run build` before starting emulators. If Functions were started from an older build, barangay **Acknowledge** will fail until emulators are restarted with a fresh build (**requires PA authorization** if PO QA data must stay hot — prefer build + restart in a maintenance window without reseed).

**Flutter launch:**

```bash
cd sibol_app
flutter run -d <device> \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Ports must match [emulator_config.dart](../../sibol_app/lib/config/emulator_config.dart) and [canonical_ports.json](../../shared/emulator/canonical_ports.json).

Extended startup: [SIBOL-INT-001-Emulator-Demonstration-Runbook.md](SIBOL-INT-001-Emulator-Demonstration-Runbook.md).

## 3. Accounts and roles

Use passwords from your local env / password manager (see [DEMO_ACCOUNTS.md](../../shared/docs/DEMO_ACCOUNTS.md)).

| Role | Typical email | Notes |
|------|---------------|--------|
| Teen (new registration) | Register in app with PSGC barangay | QA-001 used live teen UID on emulator |
| Teen (seeded) | `teen.demo@sibol.local` | If present in your emulator seed |
| Barangay operations | `barangay.demo@sibol.local` or org `barangay03` staff | Must have `coordination.barangay` for W1 referrals |
| MOPH **operational** | `moph.demo@sibol.local` | **Required** for W1 inbox and W3 reports |
| MOPH org admin only | `moph.org.admin@sibol.local` | **Not** for coordination/report demos |

## 4. Demo data preparation

- **W1:** At least one `teenAssistanceRequests` in `submitted` status for the barangay org, or create via Teen **New support request** (server callable).
- **W2:** At least one fictional `cases` document for the barangay `orgId` (seed or **Create case** in app). Aggregate counts use cases matching `assignedBarangay` label.
- **W3:** W2 cases with `totalCaseCount > 0` before **Submit report to MOPH**.

Do **not** delete or reseed PO QA documents referenced in QA-001 unless authorized.

## 5. Workflow steps and expected results

### W1 — Teen assistance and referrals

1. **Teen:** Sign in or register → **New support request** → submit → **My requests** shows new item (`submitted`).
2. **Barangay:** Sign in → incoming assistance → open request → **Acknowledge** → success snackbar; status **Acknowledged**.
3. **Teen:** **My requests** → detail shows acknowledgment time (if same teen account).
4. **Barangay:** **Refer to MOPH** (minimum-information summary) → confirmation dialog.
5. **MOPH:** Sign in as `moph.demo@sibol.local` → coordination inbox → open referral → see display ref and summary; **no** teen name or original assistance description.

**Callable dependencies:** `regSubmitTeenAssistanceRequest`, `regAcknowledgeTeenAssistanceRequest`, `createCoordinationReferral`.

### W2 — Barangay case management

1. **Barangay:** Home → case list (org-scoped) → tap case → detail + follow-up timeline.
2. Tap **Edit** → change status/notes → save → detail reflects update.
3. Optional: **Create case** from home.

**Authorization:** Firestore rules enforce `canReadCaseOrg` / `canWriteCaseOrg` ([firestore.rules](../../firestore.rules)). Client lists filter by `orgId`; cross-organization isolation is **rules-backed** — do not claim multi-tenant guarantees beyond tested rules.

### W3 — Aggregate reporting

1. **Barangay:** Home → **Submit report to MOPH** → review counts → confirm → navigates to **receipt**.
2. **Barangay:** **Submitted reports** → open prior submission.
3. **MOPH:** Home → submitted reports list → open report → aggregate counts only (no case names).

**Contract:** Client creates `reports/*` per DEMO-004 rules; `submitReport` callable remains deferred.

## 6. Known limitations (state honestly)

- **OFF-002:** All three workflows support offline capture and sync after reconnect (W1 queue; W2 Firestore persistence; W3 queued reports with stable `reports/{operationId}` idempotency). See [SIBOL_OFF_002_EXECUTION_REPORT.md](../Development/SIBOL_OFF_002_EXECUTION_REPORT.md).
- CASE-COORD Increment C (staff event writes) and Teen **My Case** are **out of scope**.
- Push notifications are not implemented.
- Physical device vs emulator: PO QA-001 used Android emulator; phone install is optional.
- Functions emulator must include post–OFF-001 exports for W1 ack (see §2).

## 7. Automated regression (CI / EA)

| Suite | Command | Typical result @ PROTOTYPE-002 |
|-------|---------|-------------------------------|
| Flutter | `cd sibol_app && flutter test` | 134+ pass |
| Functions | `cd shared/functions && npm test` | 70 pass (isolated Firestore **8226**) |
| Rules | `cd shared/firestore-rules-test && npm test` | 107 pass (isolated) |
| Integration smoke | `cd shared/integration && npm test` | 8 pass (isolated **9315/8325**) |

Do not run integration tests against inactive canonical ports.

## 8. Canonical emulator health (PROTOTYPE-003)

Before acceptance demos on a **running** canonical stack:

```bash
node shared/scripts/verify-canonical-emulator-health.mjs
```

Expect `regAcknowledgeTeenAssistanceRequest` among registered callables (HTTP **401** unauthenticated is OK).

**Latest full export (preserve QA-001 data):** `.firebase-qa-backups/pre-prototype-003-20261025/` — see [SIBOL_PROTOTYPE_003_EMULATOR_RECOVERY.md](SIBOL_PROTOTYPE_003_EMULATOR_RECOVERY.md).

## 9. Minimal final Product Owner acceptance (do not repeat full QA-001)

| Step | Role | Action | Expected observation |
|------|------|--------|----------------------|
| W1a | EA/operator | Run `verify-canonical-emulator-health.mjs` | All ports up; three callables registered; QA assistance doc `32sQiFj9v8T6R6T3Asih` present |
| W1b | Barangay | Open QA assistance request (or new submit + ack on **non-QA** test request) | **Acknowledge** succeeds via callable (no client Firestore-only ack) |
| W1c | MOPH | `moph.demo@sibol.local` → coordination inbox | Referral from QA registry visible; no teen narrative |
| W2 | Barangay | Create or open a **case** → edit status/notes | List is org-scoped; save persists (demo may start with **zero** cases — create one) |
| W3 | Barangay | **Submit report to MOPH** (requires ≥1 case) → receipt | MOPH sees aggregate counts only on submitted reports list |

**Note:** At PROTOTYPE-003 export time, `cases` and `reports` counts were **0** on the emulator; W2/W3 acceptance may require creating a fictional case (and thus counts) during the session without touching QA-001 assistance/referral records.

**P0 online acceptance (2026-10-25):** Individual coordination and aggregate reporting **PASS** on Android emulator — [SIBOL_P0_ONLINE_ACCEPTANCE_REPORT.md](../Development/SIBOL_P0_ONLINE_ACCEPTANCE_REPORT.md) (referral `SIBOL-REF-5985CB0B6FCD3C97`, report `rpt-1792921070922438-1807377220`).

## 10. Minimal offline acceptance (OFF-002; device/emulator)

Use **airplane mode** or emulator network disable between steps. Do **not** restart canonical emulators or mutate QA-001 assistance/referral anchors.

| Step | Role | Action | Expected observation |
|------|------|--------|----------------------|
| O1 | Teen | Submit assistance request while offline | Global banner + pending row on **My requests**; not on server until online |
| O2 | Teen | Kill app → reopen offline | Pending row still visible |
| O3 | Teen | Restore network | Banner clears after sync; request appears in Firestore list |
| O4 | Barangay | Open case list online, then go offline | Cached list notice; open cached case |
| O5 | Barangay | Edit case or add follow-up offline | Sync notice on detail; snackbar on save |
| O6 | Barangay | Reconnect | Pending writes sync; failures stay visible (no false success) |
| O7 | Barangay | Submit report offline (after ≥1 case) | **Submitted reports** shows queued card; local snapshot disclaimer on submit screen if cache/pending cases |
| O8 | Barangay | Reconnect | Queued report becomes normal receipt; MOPH sees aggregate on submitted list |

**Limitation:** W2 concurrent edits are last-write-wins at the Firestore layer (documented; not conflict-detected). W3 counts are frozen at queue time and labeled when case cache is incomplete or has pending writes.
