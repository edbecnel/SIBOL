# SIBOL demonstration accounts (fictional)

> **Status:** Active — Tranche 1 / SIBOL-FB-002 Phase A  
> **Applies To:** Firebase project `sibol-286d0` (demonstration only)

All accounts use **fictional** identities. Passwords are supplied locally via environment variables (never committed).

| Role | Email | Password source |
|------|-------|-----------------|
| Teen | `teen.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_TEEN` |
| Barangay (coordination staff) | `barangay.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_BARANGAY` |
| MOPH (coordination staff) | `moph.demo@sibol.local` | `SIBOL_DEMO_PASSWORD_MOPH` |

### Organization administrators (live + emulator)

These accounts are **not** ordinary coordination staff. They hold `org.manage_members` and `org.manage_roles` on their demo organization via `organizationMemberships`.

| Organization | Email | Password source (local env) | Live provisioning script |
|--------------|-------|------------------------------|---------------------------|
| `barangay03` — Barangay 3 (Poblacion) | `barangay.org.admin@sibol.local` | `SIBOL_EMULATOR_PASSWORD_BARANGAY_ORG_ADMIN` | `shared/delivery/scripts/provision-barangay-org-admin-live.mjs` |
| `hospital01` — Misamis Oriental Provincial Hospital | `moph.org.admin@sibol.local` | `SIBOL_EMULATOR_PASSWORD_MOPH_ORG_ADMIN` | `shared/delivery/scripts/provision-moph-org-admin-live.mjs` |

Canonical role values written to `users/{uid}`: `teen`, `barangay`, `moph` (org admins use `barangay` or `moph` respectively, not a separate profile role string).

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
