# SIBOL launcher icon source

| Asset | Role |
|-------|------|
| [`../../../Docs/Branding/SIBOL-Logo-Icon.png`](../../../Docs/Branding/SIBOL-Logo-Icon.png) | **PA-approved app icon** (square artwork). Do not modify. |
| `sibol_app_icon_source.png` | 1024×1024 resample from `SIBOL-Logo-Icon.png` (white backing for opaque launcher assets). |

Other branding files (reference only):

- `SIBOL-Logo.png` — full horizontal logo (in-app / marketing).
- `SIBOL-Logo-And-Icon.png` — combined branding sheet.

Regenerate launcher bitmaps:

```bash
cd sibol_app
node tool/crop_launcher_icon_source.mjs   # requires: npm install --prefix tool sharp
dart run flutter_launcher_icons
```
