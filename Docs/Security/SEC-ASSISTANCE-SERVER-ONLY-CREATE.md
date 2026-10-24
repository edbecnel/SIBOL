# Teen assistance — server-only create (SEC note)

**Status:** Implemented (PROTOTYPE-VERIFY-001)

## Control

Clients **cannot** `create` documents in `teenAssistanceRequests`. Submissions use callable **`regSubmitTeenAssistanceRequest`** with `assistanceSubmissionIdempotency` (client deny in rules).

## Verification

- `assistance_requests.rules.test.mjs` — denies teen client create.
- `int001_scenarios.smoke.mjs` — Scenario C client `addDoc` → `permission-denied`.
- `assistance_submission.test.mjs` — idempotent server writes.

## Seeding / tests

Operator seed and rules-test fixtures use **Admin SDK** or rules-disabled contexts to insert demonstration requests.
