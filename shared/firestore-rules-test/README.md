# Firestore security rules tests (SIBOL)

Runs `@firebase/rules-unit-testing` against [`../../firestore.rules`](../../firestore.rules) using the Firebase emulator.

```bash
npm install
npm ci
npm test
```

14 security scenarios (roles, immutability, schema parity, reports boundary). Requires Firebase CLI. Emulator port is configured in root [`firebase.json`](../../firebase.json) (`8195`).
