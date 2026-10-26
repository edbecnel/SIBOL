# SIBOL-P0-RECOVERY-001 — Execution report

**Handover UUID:** `a5d1e7c9-2b64-4e80-9c31-f8d72b0654ae`  
**PA amendment (password preservation):** Applied — no Auth restore from `offline-qa-closure-20261026-095408`; selective Firestore repair only.

## Git

| | SHA |
|--|-----|
| Starting HEAD | `4833c5b92cf4b511b371c1f8f3054eb46f465df5` |
| Ending HEAD | _(see commit below after push)_ |

## Root causes

1. **Profile `permission-denied`:** Flutter was launched as `flutter run -d emulator-5554` **without** emulator wiring. `EnvConfig.useEmulators` defaulted to `false`, so Auth/Firestore targeted **hosted** `sibol-286d0` while operators exercised **local** emulators. Rules and data on the emulator were correct; the client was on the wrong backend.
2. **Obsolete “Barangay Tres” labels:** Active emulator `users.assignedBarangay` still used `Barangay Tres, Balingasag` on four accounts; organizations/directory/cases/reports on the running emulator already used canonical **Barangay 3** naming. App compile-time `AppConfig.demoBarangay` and several tests/rules fixtures still referenced Tres.

## Security rules

No rule changes. Client SDK sign-in against `127.0.0.1:9099` / `8195` reads `users/{uid}` and `organizationMemberships/mbr_barangay03__{uid}` successfully for `barangay.demo@sibol.local` (`6dCjs4T7E4Lk3bzyhHhHNKMXZF5h`).

## Recovery dataset and backups

| Backup | Role |
|--------|------|
| `terminal-cleanup-20261026-141223` | **Kept running** — emulators still imported from this at session start; **not** replaced wholesale. |
| `offline-qa-closure-20261026-095408` | **Not used for Auth** per PA amendment (passwords changed after 09:54). |
| `pre-p0-recovery-20261026-143817` | Pre-repair export of **current** Auth + Firestore. |
| `post-p0-recovery-20261026-144500` | Post-repair export; **Auth SHA-256 identical** to pre-repair (`accounts.json` 7004 bytes, hash `b288e6755602c996…`). |

**Auth preservation evidence:** `barangay.demo` password hash in post-repair export **≠** closure backup (expected after PO password change). Pre-repair vs post-repair hash **equal** (repair touched Firestore only).

## Actions taken

1. **Firestore-only repair:** `shared/provisioning/scripts/repair-p0-recovery-001-emulator.mjs` — patched four `users.assignedBarangay` values to `Barangay 3, Balingasag`; verified no `Barangay Tres` in active collections.
2. **Client default:** `EnvConfig.useEmulators` — development builds default to local emulators unless `--dart-define=USE_FIREBASE_EMULATORS=false`.
3. **Naming cleanup** in app config, `DemoOrgConstants.barangay03OrgId`, rules-test fixtures, runbook, SPEC-REG-001 §11.1.
4. **Submitter identity:** `runResolveAssistanceRequestSubmitter` on `demo-assist-inbox-001` populated `submitterDisplayName` / `submitterAccountEmail` on emulator (`Demo Teen User`, `teen.demo@sibol.local`).
5. **Flutter:** Restarted on `emulator-5554` with `--dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true` (emulators implied by development default).

No `firebase emulators:start --import` from closure. No `seed:emulator` Auth rewrite. No password resets.

## Login verification (no secrets logged)

| Account | Result |
|---------|--------|
| `teen.demo@sibol.local` | **LOGIN_OK** + Firestore profile active (local `.env.emulator.local`) |
| `moph.demo@sibol.local` | **LOGIN_OK** + profile active |
| `barangay.demo@sibol.local` | **LOGIN_FAIL** `auth/wrong-password` with values in `.env.emulator.local` — consistent with PO-changed password **after** closure; **Auth hashes preserved** on emulator |

**Operator:** Sign in as Barangay staff with the **current** password already set on the emulator (not committed). Update local `.env.emulator.local` when convenient; do not reseed Auth to “fix” env drift.

## Automated tests

| Suite | Result |
|-------|--------|
| `sibol_app` `flutter test` | **190** pass |
| `shared/firestore-rules-test` `npm test` | **121** pass |
| `shared/functions` `npm test` | **87** pass |
| `shared/provisioning` `npm test` | **16** pass |
| `flutter analyze` | No new errors (pre-existing infos/warnings) |

## Android smoke

- App rebuilt and installed on `emulator-5554` after emulator-default fix.
- Full Barangay UI walkthrough with PO password not automated (env stale). Teen/MOPH auth path verified programmatically against emulators.

## Files changed (code/docs)

- `sibol_app/lib/config/env_config.dart`, `app_config.dart`, `demo_org_constants.dart`
- `sibol_app/test/*`, `sibol_app/test/env_config_test.dart`
- `shared/firestore-rules-test/test/*`, `shared/functions/src/geo/demoPsgcShim.ts`
- `shared/provisioning/scripts/repair-p0-recovery-001-emulator.mjs`
- `Docs/Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md`
- `Docs/Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md`

## Outstanding risks

- Local `.env.emulator.local` may lag PO-updated Barangay staff password; integration scripts using that env var will fail until updated locally.
- `teenAssistanceRequests` without identity snapshots need one online open by Barangay (callable refresh) unless backfilled.

## Commits and push

_(filled after commit/push)_
