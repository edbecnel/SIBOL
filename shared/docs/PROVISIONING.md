# SIBOL demonstration provisioning

> **Work item:** SIBOL-FB-002 Phase A  
> **Firebase project:** `sibol-286d0`  
> **Writes:** Require separate PA authorization (dry-run is default for validation)

## Dependency installation

`firebase-admin` is installed under `shared/provisioning/` (not via `NODE_PATH`).

```bash
cd shared/provisioning
npm install
```

## Credentials (passwords)

Demonstration passwords are **never** stored in Git. Set locally before seeding:

| Account | Environment variable |
|---------|----------------------|
| `teen.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_TEEN` |
| `barangay.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_BARANGAY` |
| `moph.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_MOPH` |

Use strong, unique values compatible with Firebase email/password sign-in. Store them in a password manager. Do not paste passwords into shell history, logs, or execution reports.

If passwords were ever committed to a repository (see Phase A execution report), **rotate or invalidate** those Auth users before public publication.

## Administrative authentication (Firebase Admin SDK)

The seed tooling uses `applicationDefault()` (Application Default Credentials).

Supported approaches (no service-account private key download required for evaluation):

1. **User ADC** — `gcloud auth application-default login` with a Google account that has Firebase Admin / appropriate IAM on `sibol-286d0`.
2. **Service account key file** — only if your organization already issued one; set `GOOGLE_APPLICATION_CREDENTIALS` to its path. Phase A does **not** authorize generating new keys.

Phase A does **not** change IAM. If ADC lacks `firebaseauth.users.create` or Firestore write access, document the gap and request owner approval.

## Commands

### Dry-run (local validation, no writes)

```bash
cd shared/provisioning
export FIREBASE_PROJECT_ID=sibol-286d0
export SIBOL_DEMO_PASSWORD_TEEN='(from password manager)'
export SIBOL_DEMO_PASSWORD_BARANGAY='(from password manager)'
export SIBOL_DEMO_PASSWORD_MOPH='(from password manager)'
npm run seed -- --dry-run --confirm-project=sibol-286d0
```

### Dry-run with optional remote **read-only** snapshot

Adds Auth/Firestore reads to refine the operation plan. Still **no writes**.

```bash
npm run seed -- --dry-run --remote-read --confirm-project=sibol-286d0
```

### Live provisioning (PA authorization required)

```bash
npm run seed -- --confirm-project=sibol-286d0
```

Equivalent launcher from repo root:

```bash
node shared/scripts/seed_tranche1_demo.mjs --dry-run --confirm-project=sibol-286d0
```

## Idempotency safeguards

| Resource | Behavior |
|----------|----------|
| Auth users | Lookup by email; create only if missing; **never** change existing password |
| `users/{uid}` | Create if missing; if document exists, **skip** updates when `role` or `active` differs |
| `cases/{demo-case-NNN}` | Create only if missing; **no overwrite** of existing demo case documents |
| `followUps` | Created only when parent case is created |
| Scope | Only `teen.demo@`, `barangay.demo@`, `moph.demo@` and `demo-case-001` … `demo-case-005` |

## Cleanup procedure (not executed in Phase A)

Dedicated cleanup is **destructive** and requires explicit PA authorization. Proposed safe pattern:

1. Require `--confirm-project=sibol-286d0` (same as seed).
2. Default mode: `--dry-run` listing documents that **would** be deleted.
3. Live cleanup only with `--execute-cleanup` (future script or flag).

**Proposed deletion scope (demo identifiers only):**

- Firebase Auth: the three `*.demo@sibol.local` users (by email lookup).
- Firestore: `users/{uid}` for those UIDs.
- Firestore: `cases/demo-case-001` … `demo-case-005` and subcollection `followUps/*`.

Do not delete collections, non-demo users, or non-demo cases.

## Tests

```bash
cd shared/provisioning
npm test
```
