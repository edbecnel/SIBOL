# Emulator demonstration flags (local only)

These environment variables apply **only** to the machine running `firebase emulators:start`. They must **never** be set on production Cloud Functions.

| Variable | Purpose |
|----------|---------|
| `SIBOL_ALLOW_DEMO_IDENTITY=true` | Enables prototype identity bridges (e.g. PSGC demo shim in `demoPsgcShim.ts`). |
| `SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING=true` | Required for the PSGC shim to resolve `barangay03` via `resolveLegacyTeenOrgId`. |

**Teen registration (Barangay 3 / `1004302022`):** both must be `true` on the Functions emulator worker.

Configure via gitignored `.env.emulator.local` at the repository root (see `.env.emulator.example`). `start-demo-emulators.sh` sources that file when present.

Changing flags requires a **new** Functions emulator process (restart the emulator stack). See [SIBOL_GEO_001_INV_001_INVESTIGATION_REPORT.md](../../Docs/Development/SIBOL_GEO_001_INV_001_INVESTIGATION_REPORT.md).
