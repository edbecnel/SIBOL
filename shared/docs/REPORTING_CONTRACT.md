# Server-authoritative reporting contract (Tranche 2 target)

## Callable: `submitReport` (planned)

**Caller:** Active `barangay` user.

**Input (illustrative):**

```json
{ "caseId": "demo-case-001", "summary": "Fictional monthly summary" }
```

**Server checks:**

- Auth uid has `users/{uid}.role == barangay` and `active == true`
- Case exists and belongs to demonstration barangay
- Idempotent guard against duplicate submit where appropriate

**Server writes:**

- `reports/{reportId}` with `reportStatus: submitted`, `acceptedAt`, `caseId`, `summary`, `submittedBy`
- Updates `cases/{caseId}.reportStatus` to `submitted` (server-side Admin SDK bypasses client rules)

**Client must not:**

- Set `visibleToMoph` or equivalent flags directly
- Mark `submitted` without function success

Tranche 1 stub: [`shared/functions/src/index.ts`](../functions/src/index.ts).
