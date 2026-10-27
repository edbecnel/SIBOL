# SIBOL-DELIVERY-001 — Live migration preparation

**Firebase project:** `sibol-286d0`  
**Default mode:** read-only dry-run (no live writes)

## Quick commands

```bash
cd shared/delivery
npm install
npm run dry-run
npm run inventory-export -- ../../.firebase-qa-backups/po-case-identity-prep-20261026-1832
npm run compare-functions
```

Requires Application Default Credentials (`gcloud auth application-default login`) for live reads.

## Android (Frecy) — live Firebase APK

```bash
cd sibol_app
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=USE_FIREBASE_EMULATORS=false
```

Output: `sibol_app/build/app/outputs/flutter-apk/app-release.apk` (gitignored).

Install instructions: [SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md](../../Docs/Operations/SIBOL_DELIVERY_001_FRECY_ANDROID_INSTALL.md).

## Live writes

**Not authorized** by delivery prep alone. See [SIBOL_DELIVERY_001_EXECUTION_REPORT.md](../../Docs/Development/SIBOL_DELIVERY_001_EXECUTION_REPORT.md) for the Product Owner approval gate.
