# Firestore security rules tests (SIBOL)

Runs `@firebase/rules-unit-testing` against [`../../firestore.rules`](../../firestore.rules) using the Firebase emulator.

```bash
npm install
npm ci
npm test
```

**66** security scenarios (cases, teen assistance, aggregate reports, case coordination, registry v2). Requires Firebase CLI.

## Emulator ports

| Mode | Command | Port |
|------|---------|------|
| **Isolated (default `npm test`)** | Uses [`../../firebase.emulator-isolated.json`](../../firebase.emulator-isolated.json) | Firestore **8215** |
| **Attached** | `npm run test:attached` | Firestore **8195** (must match root [`firebase.json`](../../firebase.json); use only when that emulator is running and clean) |

Use isolated runs when port 8195 is used by `flutter run` or another process.
