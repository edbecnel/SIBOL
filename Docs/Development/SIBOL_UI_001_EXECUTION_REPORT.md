# SIBOL-UI-001 — Execution report (application launcher icon)

> **Handover UUID:** `c81e4f29-6d73-4b05-a892-3f7e16d9c420`  
> **Date:** 2026-10-21  
> **Git commit/push:** **Not authorized**  
> **Firebase / T2-3 functional changes:** **Not authorized**  
> **PA acceptance:** Pending

## 1. PA authorization

Local implementation and verification only. No commit, Firebase, or case-management changes.

## 2. Approved source asset

| Asset | Use |
|-------|-----|
| [`Docs/Branding/SIBOL-Logo-Icon.png`](../Branding/SIBOL-Logo-Icon.png) | **PA-approved app icon** (corrected 2026-10-21). **Unmodified.** |
| [`sibol_app/assets/branding/sibol_app_icon_source.png`](../../sibol_app/assets/branding/sibol_app_icon_source.png) | 1024×1024 from `SIBOL-Logo-Icon.png`. |

**Superseded:** `SIBOL-Logo.png` / `SIBOL-Logo-And-Icon.png` crops for launcher. **Not used:** `assets/images/sibol_logo.png` (in-app only).

Regenerate: [`assets/branding/README.md`](../../sibol_app/assets/branding/README.md) or [`sibol_app/tool/crop_launcher_icon_source.mjs`](../../sibol_app/tool/crop_launcher_icon_source.mjs).

## 3. Android

- **Package:** `flutter_launcher_icons` in `pubspec.yaml`.
- **Legacy mipmaps:** `android/app/src/main/res/mipmap-*/ic_launcher.png` (generated).
- **Adaptive icon:** `mipmap-anydpi-v26/ic_launcher.xml` + `drawable-*/ic_launcher_foreground.png` with background color `#5BC8F5` (sky tone from artwork).
- **Manifest:** unchanged `@mipmap/ic_launcher`; application ID and Firebase unchanged.

## 4. iOS

- **AppIcon:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` regenerated from same source.
- **`remove_alpha_ios: true`** — opaque icons for App Store rules.
- Bundle ID, signing, and Firebase plist paths unchanged.

## 5. Regeneration

```bash
cd sibol_app
dart run flutter_launcher_icons
```

## 6. Verification (2026-10-21)

| Check | Command / method | Result |
|-------|------------------|--------|
| Dependencies | `flutter pub get` | OK |
| Icon generation | `dart run flutter_launcher_icons` | OK — Android adaptive + iOS AppIcon |
| Analyze | `flutter analyze` | **0 errors**, 11 info hints |
| Tests | `flutter test` | **46/46** passed |
| Android build | `flutter build apk --debug` | OK |
| Android install | `adb install -r app-debug.apk` on `emulator-5554` | OK |
| Android launcher visual | Generated `mipmap-xxxhdpi/ic_launcher.png` + debug install | **SIBOL sun/hills artwork** (not Flutter default); home-screen drawer capture not obtained in EA session |
| iOS build | `flutter build ios --simulator --no-codesign` | **OK** — `Runner.app` built; AppIcon 1024 asset matches source |
| iOS Simulator launch | Not run | Simulators available; **home-screen icon not visually confirmed** on device |

## 7. PA disposition

Pending review.
