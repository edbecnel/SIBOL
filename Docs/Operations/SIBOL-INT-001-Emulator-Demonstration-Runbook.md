# SIBOL-INT-001 — Emulator demonstration runbook

> **Handover UUIDs:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42` (INT-001); `a6d2c941-7e35-4b80-9f26-c103e8d754ab` (AGENT-002 continuation)  
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
./shared/scripts/validate-int-001-emulator.sh   # ports + dry-run guard
./shared/scripts/seed-emulator-demo.sh          # runs verify:emulator after seed
```

Dry-run (no writes):

```bash
./shared/scripts/seed-emulator-demo.sh --dry-run
```

### Demonstration organizations

| Org ID | Type | Name |
|--------|------|------|
| `barangay03` | Barangay | Barangay Tres |
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
flutter run -d <device-id> \
  --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
```

**Critical:** Without `USE_FIREBASE_EMULATORS=true`, the app talks to **production** Firebase (`sibol-286d0`). Emulator demos will fail or hit live data.

Physical iOS device on LAN: emulator host is not automatic — prefer Android emulator for local demos.

## 6. Scenarios A–F (operator walkthrough)

Record **Manual PASS / FAIL / BLOCKED** and a one-line note per scenario in the execution report.

### Scenario A — Central Administrator

| Step | Do | On screen | Success | If it fails |
|------|-----|-----------|---------|-------------|
| A1 | Sign in as `central.admin@sibol.local` | Login → role home / settings | No auth error | Check emulators + seed; `USE_FIREBASE_EMULATORS` |
| A2 | Settings → **Organizations** | Org list | `barangay03`, `hospital01` visible (after seed) | Re-seed; Emulator UI → Firestore `organizations` |
| A3 | Create org (use **disposable** name, not demo ids) | Create form | Success snackbar; new **server-generated** `orgId` returned | Functions emulator; central `isCentralAdmin` |
| A4 | Sign in as Barangay staff | Login | No central org admin UI | Expected denial |

### Scenario B — Organization Administrator

| Step | Do | On screen | Success | If it fails |
|------|-----|-----------|---------|-------------|
| B1 | Sign in `barangay.org.admin@sibol.local` | Settings | Org admin / staff entry | Membership `org.manage_*` on `barangay03` |
| B2 | Staff administration | Invite list | Can invite; no case inbox without `case.read` | Capabilities in Firestore membership |
| B3 | Accept invitation (second browser/user) | Pending invite flow | Active membership | Use emulator invitation id from Functions logs / Firestore |

### Scenario C — Teen

| Step | Do | On screen | Success | If it fails |
|------|-----|-----------|---------|-------------|
| C1 | Register or sign in `teen.demo@sibol.local` | Teen home | Profile complete | `regRegisterTeenAccount` / seed profile |
| C2 | Assistance → new request | Form | Submitted confirmation | `selectedBarangayOrgId=barangay03` on profile |
| C3 | My requests | List | Own request only | Rules teen isolation |

### Scenario D — Barangay staff

| Step | Do | On screen | Success | If it fails |
|------|-----|-----------|---------|-------------|
| D1 | Sign in `barangay.demo@sibol.local` | Barangay home | Incoming assistance | `orgId=barangay03` query |
| D2 | Open `demo-assist-inbox-001` | Detail | Acknowledge control | Seed sample request |
| D3 | Acknowledge → referral to MOPH | Referral form | Success | `coordination.barangay` capability |
| D4 | Submitted referrals | History list | Prior referral | Org-scoped coordination threads |

### Scenario E — MOPH

| Step | Do | On screen | Success | If it fails |
|------|-----|-----------|---------|-------------|
| E1 | Sign in `moph.demo@sibol.local` | MOPH home | Referral inbox | `hospital01` + `coordination.hospital` |
| E2 | Open referral | Detail read-only | No edit controls for case writes | Increment B read-only |

### Scenario F — Security (spot checks)

| Step | Do | Expected |
|------|-----|----------|
| F1 | Teen opens another teen’s request id | Denied / empty |
| F2 | Barangay staff queries other org | Denied |
| F3 | Org admin without `case.read` opens cases | No case data |
| F4 | Unauthenticated Firestore read | Denied |

Automated coverage for F1–F4: `shared/integration/test/prototype_journey.smoke.mjs`, `shared/firestore-rules-test`.

## 7. Condensed role sequence (quick reference)

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

## 8. Reset / reseed

1. Stop emulators (Ctrl+C).
2. Remove persisted data if used: `rm -rf .emulator-data/int-001`
3. Restart emulators (step 3).
4. Re-run seed (step 4).

## 9. Automated smoke (no UI)

```bash
cd shared/integration && npm test
```

Fails clearly if emulators cannot start or authorization/seed is wrong.

Full regression:

```bash
./shared/scripts/run-int-001-verification.sh
```

## 10. Troubleshooting

| Symptom | Check |
|---------|--------|
| Seed refused | Emulator env vars and `--confirm-emulator-demo` |
| Flutter cannot reach Auth | `USE_FIREBASE_EMULATORS=true`; Android uses `10.0.2.2` |
| REG callables fail | Functions emulator on 5001; rebuild `shared/functions` |
| Permission denied on assistance | Teen `assignedBarangay` + `selectedBarangayOrgId` match request `orgId` |
| Index errors | [`firestore.indexes.json`](../../firestore.indexes.json) loaded by emulator config |

## 11. Known limitations

- Provisional teen onboarding policy (consent, age gates) — Product Owner decisions; not legal consent.
- No production Firebase deploy in this work item.
- iOS **Simulator** runtime was not available in the execution environment (physical device only).
- Operator-observed mobile E2E is distinct from automated emulator smoke tests.
