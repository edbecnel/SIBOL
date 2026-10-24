# Functions integration tests

## Full regression

From `shared/functions`:

```bash
npm test
```

This runs:

1. `test/authz.test.mjs` (unit)
2. Firestore integration tests inside **dedicated** emulators via `scripts/run-firestore-integration-tests.mjs`

## Emulator isolation

| Suite | Config | Firestore port |
|-------|--------|----------------|
| `shared/firestore-rules-test` | `firebase.emulator-isolated.json` | 8215 |
| `shared/functions` integration | `firebase.emulator-functions-test.json` | 8226 |

Do not point integration tests at `127.0.0.1:8195` or reuse a long-lived emulator with stale data.

Integration tests **require** `FIRESTORE_EMULATOR_HOST` set by `firebase emulators:exec` (the runner sets `127.0.0.1:8226`).

## Integration only

```bash
npm run test:integration
```
