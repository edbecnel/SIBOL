# SIBOL-INT-001 — Emulator demonstration runbook

> **Handover UUIDs:** `b7e42a91-6c38-4f05-9d27-a813e0c65b42` (INT-001); `a6d2c941-7e35-4b80-9f26-c103e8d754ab` (AGENT-002); `c8f24a61-3d79-4e05-9b12-f6a730d84e25` (EMULATOR-001); `d7a39c42-8f61-4b05-a2e9-63c714d80f52` (SEED-001)  
> **Work item:** SIBOL-INT-001  
> **Scope:** Local Firebase emulators and synthetic data only — **not production**. Production Firebase deploy and production data changes are **not authorized** in this work stream.

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

## 2. Emulator configuration (canonical)

**Authoritative ports** for operator demonstrations are defined in [`firebase.json`](../../firebase.json) and mirrored in [`shared/emulator/canonical_ports.json`](../../shared/emulator/canonical_ports.json).

| Service | Port | Config |
|---------|------|--------|
| Authentication | 9099 | `firebase.json` → `emulators.auth` |
| Firestore | **8195** | `firebase.json` → `emulators.firestore` |
| Cloud Functions | 5001 | `firebase.json` → `emulators.functions` |
| Emulator UI | 4000 | `firebase.json` → `emulators.ui` |

**Project ID (emulator):** `sibol-286d0` (matches Flutter `firebase_options.dart`).

**CI / isolated integration smoke** uses [`firebase.emulator-smoke-isolated.json`](../../firebase.emulator-smoke-isolated.json) on Auth **9315** / Firestore **8325** (see [`shared/emulator/smoke_isolated_ports.json`](../../shared/emulator/smoke_isolated_ports.json)) so tests do not collide with canonical **8195/9099** or legacy demo **8215/9199** stacks.

Override config: `SIBOL_FIREBASE_EMULATOR_CONFIG=firebase.emulator-demo.json` (legacy ports).

**Safety (fail-closed seeding):** `shared/provisioning` refuses demo seed or verify unless:

- `FIRESTORE_EMULATOR_HOST` and `FIREBASE_AUTH_EMULATOR_HOST` are set to **local** hosts on the **canonical** ports above (8195 / 9099),
- `FIREBASE_PROJECT_ID` is `sibol-286d0`,
- `--confirm-emulator-demo` is passed,
- and (for writes / verify) the emulators respond on those endpoints.

Application Default Credentials may still be present; seeding does **not** treat ADC or project id alone as proof of emulator isolation.

## 3. Start emulators (no seed)

**Working directory:** repository root (`/Users/edbecnel/Development/GitHub/SIBOL`).

**Command:**

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL
firebase emulators:start --project sibol-286d0 --only auth,firestore,functions
```

Equivalent wrapper (builds Functions first):

```bash
./shared/scripts/start-demo-emulators.sh
```

**Expected:** CLI lists Auth **9099**, Firestore **8195**, Functions **5001**, Emulator UI **4000**; Cloud Functions load without error.

**Failure indicators:** Port already in use; Functions build failure; “Could not start” for any emulator.

**Safe corrective action:** Free the conflicting port or stop the other process; rebuild with `cd shared/functions && npm run build`; do **not** point seed scripts at production.

Leave this terminal open. Optional persistence:

```bash
./shared/scripts/start-demo-emulators.sh --import=./.emulator-data/int-001 --export-on-exit
```

**Note:** Starting emulators does **not** create demonstration users or organizations. Seeding is a separate step (§4).

## 4. Pre-flight and seed demonstration data

Only after emulators are running and **Project Architect** authorizes seeding:

**Working directory:** repository root.

### 4.1 Non-destructive pre-flight

```bash
./shared/scripts/validate-int-001-emulator.sh
```

**Expected:** `OK: port 8195 open`, `OK: port 9099 open`, `OK: port 5001 open`, and `OK: emulator environment validated`.

**Failure indicators:** `WARN: Nothing listening` on canonical ports; guard errors mentioning port **8080** (stale `.env.emulator.local` — update `FIRESTORE_EMULATOR_HOST=127.0.0.1:8195`).

**Safe corrective action:** Start emulators (§3); align `.env.emulator.local` with [`.env.emulator.example`](../../.env.emulator.example); if your **shell** still exports an old Firestore host (e.g. `8080`), run `unset FIRESTORE_EMULATOR_HOST` or open a fresh terminal before validate/seed; re-run pre-flight. Do not seed until pre-flight passes.

### 4.2 Seed (writes fictional data)

```bash
./shared/scripts/seed-emulator-demo.sh
```

Runs `verify:emulator` after seed unless `SIBOL_SKIP_SEED_VERIFY=1`.

Dry-run (no writes, no reachability check):

```bash
cd shared/provisioning && npm run seed:emulator -- --dry-run --confirm-emulator-demo
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

Emulator ports in demonstration mode match §2 (`EmulatorConfig` in `sibol_app/lib/config/emulator_config.dart`).

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
3. Restart emulators (§3).
4. Re-run seed (§4) after pre-flight passes.

## 9. Automated smoke (no UI)

```bash
cd shared/integration && npm test
```

Spawns isolated emulators (ports **9315 / 8325** by default) via `firebase.emulator-smoke-isolated.json`. Does not use the operator’s 9099 / 8195 stack.

Full regression:

```bash
./shared/scripts/run-int-001-verification.sh
```

## 10. Troubleshooting

| Symptom | Check |
|---------|--------|
| Seed refused / port 8080 | Update `.env.emulator.local` to Firestore **8195**; re-run `validate-int-001-emulator.sh` |
| Seed refused (other) | Emulator env vars, canonical ports, `--confirm-emulator-demo` |
| Flutter cannot reach Auth/Firestore | `USE_FIREBASE_EMULATORS=true`; Android uses `10.0.2.2`; Firestore port **8195** |
| REG callables fail | Functions emulator on 5001; rebuild `shared/functions` |
| Permission denied on assistance | Teen `assignedBarangay` + `selectedBarangayOrgId` match request `orgId` |
| Index errors | [`firestore.indexes.json`](../../firestore.indexes.json) loaded by emulator config |
| ADC warning on emulator start | Expected; ensure seed/verify use emulator env vars (fail-closed guard) |

## 11. Known limitations

- Provisional teen onboarding policy (consent, age gates) — Product Owner decisions; not legal consent.
- No production Firebase deploy in this work item.
- iOS **Simulator** runtime was not available in the execution environment (physical device only).
- Operator-observed mobile E2E is distinct from automated emulator smoke tests.
