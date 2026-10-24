# Firestore security rules tests (SIBOL)

Runs `@firebase/rules-unit-testing` against [`../../firestore.rules`](../../firestore.rules) using the Firebase emulator.

```bash
npm install
npm ci
npm test
```

59 security scenarios (cases, teen assistance, aggregate reports, case coordination). Requires Firebase CLI. Emulator port is configured in root [`firebase.json`](../../firebase.json) (`8195`).
