# SIBOL-INT-001 — Emulator demonstration runbook

> **Handover UUID:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42`  
> **Work item:** SIBOL-INT-001  
> **Scope:** Local Firebase emulators and synthetic data only — not production.

## 1. Prerequisites

| Requirement | Notes |
|-------------|--------|
| Node.js 20+ | Functions build and seed scripts |
| Firebase CLI | `firebase` logged in (emulator binaries installed) |
| Flutter SDK | `sibol_app` |
| Android emulator or device | Optional for operator walkthrough |
| `.env.emulator.local` | Copy from [`.env.emulator.example`](../../.env.emulator.example); **gitignored** |

Install package dependencies once:

```bash
cd shared/functions && npm install && npm run build
cd ../provisioning && npm install
cd ../integration && npm install
cd ../../sibol_app && flutter pub get
```

## 2. Emulator configuration

| Service | Port | Config file |
|---------|------|-------------|
| Auth | 9099 | [`firebase.emulator-demo.json`](../../firebase.emulator-demo.json) |
| Firestore | 8080 | same |
| Functions | 5001 | same |
| Emulator UI | 4000 | same |

**Project ID (emulator):** `sibol-286d0` (matches Flutter `firebase_options.dart`).

**Safety:** Seeding refuses to run without `FIRESTORE_EMULATOR_HOST`, `FIREBASE_AUTH_EMULATOR_HOST`, matching `FIREBASE_PROJECT_ID`, and `--confirm-emulator-demo`.

## 3. Start emulators

**Working directory:** repository root.

```bash
./shared/scripts/start-demo-emulators.sh
```

Leave this terminal open. Optional persistence:

```bash
./shared/scripts/start-demo-emulators.sh --import=./.emulator-data/int-001 --export-on-exit
```

## 4. Seed demonstration data

**Working directory:** repository root (script changes to `shared/provisioning`).

```bash
./shared/scripts/seed-emulator-demo.sh
```

Dry-run (no writes):

```bash
./shared/scripts/seed-emulator-demo.sh --dry-run
```

### Demonstration organizations

| Org ID | Type | Name |
|--------|------|------|
| `barangay03` | Barangay | Barangay Tres, Balingasag |
| `hospital01` | Hospital | Misamis Oriental Provincial Hospital |

### Demonstration accounts (fictional emails)

Passwords are **only** in your local `.env.emulator.local` (never committed).

| Role | Email |
|------|--------|
| Central Administrator | `central.admin@sibol.local` |
| Barangay Organization Administrator | `barangay.org.admin@sibol.local` |
| Barangay staff (BNS) | `barangay.demo@sibol.local` |
| Backup Barangay Org Admin | `backup.barangay.admin@sibol.local` |
| MOPH Organization Administrator | `moph.org.admin@sibol.local` |
| MOPH staff | `moph.demo@sibol.local` |
| Teen | `teen.demo@sibol.local` |

Use the in-app **password visibility (eye)** toggle when typing disposable emulator passwords.

## 5. Launch Flutter

**Working directory:** `sibol_app/`

Android emulator (host loopback `10.0.2.2` is configured automatically):

```bash
flutter run -d emulator-5554 \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
```

Physical iOS device on LAN: replace emulator host is not automatic — use Android emulator or macOS desktop for emulator-backed demos unless you configure host reachability.

## 6. Role-by-role demonstration sequence

| Step | Actor | Action | Expected result |
|------|--------|--------|-----------------|
| 1 | Central Admin | Sign in → Settings → **Organizations** | List includes demo Barangay and MOPH (if created); or use **Emulator: bootstrap Central Admin** once, then create orgs |
| 2 | Central Admin | Appoint org admin / inspect memberships | REG-B callables succeed; audit events in Firestore |
| 3 | Barangay Org Admin | Sign in → staff administration | Invite/list staff; no `case.read` unless granted separately |
| 4 | Teen | Register **or** sign in as `teen.demo@sibol.local` | Teen home; Barangay org on profile |
| 5 | Teen | New support request | Status `submitted`; confirmation |
| 6 | Barangay staff | Incoming requests → open `demo-assist-inbox-001` or new request | Acknowledge → `acknowledged` |
| 7 | Barangay staff | Coordination referral to MOPH | Callable success; thread in MOPH inbox |
| 8 | MOPH staff | Open referral | Read-only detail (Increment B) |
| 9 | Barangay staff | Submitted referrals history | Prior referral listed |
| 10 | Central Admin | Attempt case/assistance access without capability | Denied by rules |

Record **Manual PASS** / **FAIL** per step in the execution report.

## 7. Reset / reseed

1. Stop emulators (Ctrl+C).
2. Remove persisted data if used: `rm -rf .emulator-data/int-001`
3. Restart emulators (step 3).
4. Re-run seed (step 4).

## 8. Automated smoke (no UI)

```bash
cd shared/integration && npm test
```

Fails clearly if emulators cannot start or authorization/seed is wrong.

Full regression:

```bash
./shared/scripts/run-int-001-verification.sh
```

## 9. Troubleshooting

| Symptom | Check |
|---------|--------|
| Seed refused | Emulator env vars and `--confirm-emulator-demo` |
| Flutter cannot reach Auth | `USE_FIREBASE_EMULATORS=true`; Android uses `10.0.2.2` |
| REG callables fail | Functions emulator on 5001; rebuild `shared/functions` |
| Permission denied on assistance | Teen `assignedBarangay` + `selectedBarangayOrgId` match request `orgId` |
| Index errors | [`firestore.indexes.json`](../../firestore.indexes.json) loaded by emulator config |

## 10. Known limitations

- Provisional teen onboarding policy (consent, age gates) — Product Owner decisions; not legal consent.
- No production Firebase deploy in this work item.
- iOS **Simulator** runtime was not available in the execution environment (physical device only).
- Operator-observed mobile E2E is distinct from automated emulator smoke tests.
