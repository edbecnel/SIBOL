# Firebase setup — SIBOL

> **Status:** Active (project `sibol-286d0`)  
> **Owner:** Engineering  
> **Last updated:** 2026-10-20

## Canonical configuration

| Artifact | Path | In git? |
|----------|------|---------|
| Dart Firebase options | `sibol_app/lib/config/firebase_options.dart` | **Yes** (client API keys) |
| Android native config | `sibol_app/android/app/google-services.json` | **No** (gitignored) |
| iOS native config | `sibol_app/ios/Runner/GoogleService-Info.plist` | **No** (gitignored) |
| FlutterFire metadata | `sibol_app/firebase.json` | Yes |

**Firebase project ID:** `sibol-286d0` (not SpeakUp Connect `speakup-connect-891dd`).

Dart options **must match** the native `google-services.json` / `GoogleService-Info.plist` values. If they diverge, iOS may fail at startup with:

```text
[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
```

That error often means the native default app was created from the plist/JSON while Dart passed different `FirebaseOptions` (for example Tranche 1 placeholders), not necessarily that `Firebase.initializeApp` was called twice in application code.

## Investigation result (Tranche 1)

| Check | Result |
|-------|--------|
| Existing SIBOL Firebase config in repo | **None** before Tranche 1 (`firebase.json` added; options were placeholders) |
| Distinct from SpeakUp Connect | **Required** |
| Coordinator approval to create project | **Completed** — project `sibol-286d0` |

## FlutterFire configure

Run from the **`sibol_app/`** directory so `--out` is relative to the app package:

```bash
dart pub global activate flutterfire_cli
cd sibol_app
flutterfire configure \
  --project=sibol-286d0 \
  --platforms=android,ios \
  --android-package-name=com.most.sibol.sibol_app \
  --ios-bundle-id=com.most.sibol.sibolApp \
  --out=lib/config/firebase_options.dart
```

Do **not** use `--out=sibol_app/lib/config/...` when the working directory is already `sibol_app/`.

Copy or regenerate platform files locally if needed:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Firestore rules (coordinator / PA authorization)

```bash
firebase deploy --only firestore:rules --project sibol-286d0
```

## Demo data (separate authorization)

Provisioning package: `shared/provisioning/` (`npm install`, then `npm run seed`).  
Launcher: `shared/scripts/seed_tranche1_demo.mjs` with `--confirm-project=sibol-286d0`.  
Documentation: [shared/docs/PROVISIONING.md](../../shared/docs/PROVISIONING.md), [shared/docs/DEMO_ACCOUNTS.md](../../shared/docs/DEMO_ACCOUNTS.md).

## Emulators (optional)

Integrated demonstration (SIBOL-INT-001):

```bash
./shared/scripts/start-demo-emulators.sh
./shared/scripts/seed-emulator-demo.sh   # after configuring .env.emulator.local
```

See [SIBOL-INT-001-Emulator-Demonstration-Runbook.md](../Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md).

Run the app with:

```bash
cd sibol_app
flutter run --dart-define=USE_FIREBASE_EMULATORS=true \
  --dart-define=SIBOL_COORD_REGISTRY_RULES_V2=true
```
