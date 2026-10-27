# Frecy — Android install (live Firebase)

> **Work item:** SIBOL-DELIVERY-001  
> **Firebase:** `sibol-286d0` (production project, not emulators)  
> **Platform:** Android only

## APK (prepared on engineering machine)

| Field | Value |
|-------|--------|
| Build | `flutter build apk --release` with `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false` |
| Path (local) | `sibol_app/build/app/outputs/flutter-apk/app-release.apk` |
| Git HEAD when built | Record in execution report (`8adb841` or later) |
| Signing | Debug keystore (repo `build.gradle.kts`) — suitable for sideload demo, not Play Store |

Transfer the APK to the phone (USB, cloud drive, or `adb install` if a computer is available).

## Phone setup

1. **Settings → Security** (or Apps): allow installation from the chosen source (USB / files / browser).
2. Open the APK file and confirm install.
3. Launch **SIBOL**. First launch needs network access to Google/Firebase.

The app uses `google-services.json` for `sibol-286d0` and does **not** point at `10.0.2.2` when built as above.

## Demonstration accounts (no passwords in this document)

| Role | Email |
|------|--------|
| Teen (seeded) | `teen.demo@sibol.local` |
| Barangay | `barangay.demo@sibol.local` |
| MOPH | `moph.demo@sibol.local` |

Passwords are in the Product Owner password manager (`SIBOL_DEMO_PASSWORD_*` env vars per [DEMO_ACCOUNTS.md](../../shared/docs/DEMO_ACCOUNTS.md)).

**New teen registration** in the app is supported after live Functions deploy (see execution report).

## Suggested walkthrough

Follow [SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md](SIBOL_PROTOTYPE_002_THREE_WORKFLOW_DEMO_RUNBOOK.md) on **live** Firebase once backend deploy is approved.

Known live gaps until deploy: most Cloud Functions are missing on production (only `createCoordinationReferral` was deployed at dry-run time). Teen registration, assistance submit/acknowledge, and case identity callables require **approved** `firebase deploy --only functions`.

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Sign-in fails | Wrong password or Auth user missing on live |
| Callable / internal error after sign-in | Functions not deployed or rules out of date |
| Permission denied on Firestore | Rules not deployed to match app @ HEAD |

Do not reset Firebase or reinstall the app to “fix” data without engineering approval.
