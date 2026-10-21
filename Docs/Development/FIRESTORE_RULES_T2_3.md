# Firestore rules — T2-3 hardening

> **Handover:** `b72d5c94-…` (implementation), `f3a7c219-…` (verification/Git), `a4e71d39-…` (deploy)  
> **Status:** **Deployed** to `sibol-286d0` (2026-10-21); ruleset `3f65a5f3-19c1-4134-98d3-d5e420864afc`

## Rationale

Published baseline (`308d8c2`) allowed barangay `create`/`update` on `cases` without field-level constraints. T2-3 adds server-side enforcement aligned with [`shared/contracts/case_record.schema.json`](../../shared/contracts/case_record.schema.json):

- Allowed field keys only (`additionalProperties: false` parity).
- Age 13–19, valid `caseStatus`, client-writable `reportStatus` values (`notSubmitted`, `pendingSubmit`).
- **Create:** `reportStatus` must be `notSubmitted`.
- **Update:** `createdAt` and `reportStatus` immutable (reporting transitions remain server-authoritative per ADR-0003).

## Delta vs `origin/main` (`308d8c2`)

| Topic | Before | After |
|-------|--------|-------|
| Case create/update | `isBarangay()` only | + `caseCoreFieldsValid`, create `notSubmitted`, update immutability |
| Teen/MOPH/unauth | Unchanged deny paths for cases | Unchanged |
| Reports | Unchanged | Unchanged |
| Follow-ups | Barangay read/write | Unchanged |

## Verification

```bash
cd shared/firestore-rules-test && npm ci && npm test
```

14 scenarios (2026-10-21): roles, immutability, allow-list, types, delete denial, follow-up read, reports client-write denial.

Uses Firebase emulator (port **8195** in root [`firebase.json`](../../firebase.json)).

## Organization scoping

Not introduced in T2-3. All barangay users share the demo case namespace. Future org-id claims require ADR + rules pass.

## Deployment readiness (analysis only)

### Compatibility with existing fictional records

Provisioning uses `reportStatus: "notSubmitted"` and schema fields only (`shared/provisioning`). Existing `demo-case-001` … `005` should remain readable by barangay and editable on non-reporting fields after deploy.

**Risk:** Any manually altered production case with extra fields or invalid types will fail barangay **update** until corrected (read still allowed).

### Expected access after deploy

| Role | Cases | Follow-ups | Reports |
|------|-------|------------|---------|
| Barangay | Read; create/update per validation; no delete | Unchanged | No client write |
| Teen | Denied | Denied | Denied |
| MOPH | Denied | Denied | Read accepted submitted only |
| Unauthenticated | Denied | Denied | Denied |

### Deploy (executed 2026-10-21)

```bash
firebase deploy --only firestore:rules --project sibol-286d0
```

Pre-deploy rollback copy: `Docs/Verification/Artifacts/firestore.rules.pre-t2-3-deploy-2026-10-21.rules`.

### Rollback

Redeploy rules from previous Git revision (e.g. `308d8c2`):

```bash
git show 308d8c2:firestore.rules > /tmp/firestore.rules.rollback
firebase deploy --only firestore:rules --project sibol-286d0
# (with rules file restored in repo or via firebase.json path)
```

Keep a copy of the pre-deploy rules in the Firebase console revision history as secondary rollback.

### Remaining limitations

- No organization-level isolation between barangay accounts.
- Follow-up subcollection writes still lack field-level rules (unchanged from T2-2).
- Cases with server-set `reportStatus` beyond client enum cannot be updated by clients until policy allows (by design).

### Suggested Android manual QA (post-deploy, fictional demo only)

1. Sign in as `barangay.demo@` — list cases, open detail, confirm follow-ups load.
2. Create new fictional case — success; verify in list.
3. Edit case notes/status — success.
4. Sign in as teen — confirm no case routes/data.

## Teen assistance requests (SIBOL-DEMO-002, local rules — deploy pending PA)

- Collection `teenAssistanceRequests`: teen create/read own only; no client update/delete.
- See [`SIBOL_DEMO_002_EXECUTION_REPORT.md`](SIBOL_DEMO_002_EXECUTION_REPORT.md) and `assistance_requests.rules.test.mjs`.
5. Sign in as MOPH — confirm dashboard without case list; reports behavior unchanged.

**Do not use real PII until org-scoped authorization exists.**
