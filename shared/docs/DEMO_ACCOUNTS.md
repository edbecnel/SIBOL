# SIBOL demonstration accounts (fictional)

> **Status:** Active — Tranche 1 / SIBOL-FB-002 Phase A  
> **Applies To:** Firebase project `sibol-286d0` (demonstration only)

All accounts use **fictional** identities. Passwords are supplied locally via environment variables (never committed).

| Role | Email | Password source |
|------|-------|-----------------|
| Teen | `teen.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_TEEN` |
| Barangay | `barangay.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_BARANGAY` |
| MOPH | `moph.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_MOPH` |

Canonical role values written to `users/{uid}`: `teen`, `barangay`, `moph`.

## Owner setup

1. Choose three strong passwords (password manager).
2. Export the variables in your shell or a **local, gitignored** env file (not tracked).
3. Run provisioning preflight — see [PROVISIONING.md](PROVISIONING.md).

## Provision (after PA authorizes live seed)

```bash
cd shared/provisioning
npm install
export FIREBASE_PROJECT_ID=sibol-286d0
# export SIBOL_DEMO_PASSWORD_* from password manager
npm run seed -- --confirm-project=sibol-286d0
```

Validate first with `--dry-run` (no Firebase writes).

Roles are written to `users/{uid}` by the Admin SDK. End users cannot change `role` (see `firestore.rules`).

## Prior credential exposure

Earlier revisions stored demonstration passwords in `shared/scripts/seed_tranche1_demo.mjs` and this document. If those values were used against `sibol-286d0`, rotate passwords in Firebase Auth (or delete and re-create demo users) before any repository publication.
