# SIBOL-GEO-001 — Execution Report

**Handover:** SIBOL-GEO-001-AGENT-001  
**Base commit:** `295e030`  

## 1. PSGC source, version, reuse

| Field | Value |
|-------|--------|
| **Originator** | Philippine Statistics Authority (PSA) |
| **Official page** | https://psa.gov.ph/classification/psgc |
| **Publication** | PSGC quarterly release **2025-06-30** (2025-2Q dataset) |
| **SIBOL version id** | `psgc-psa-2025-2q` |
| **Build input** | `@jobuntux/psgc@0.2.1` / `2025-2Q` JSON (normalized at build time from PSA quarterly tables) |
| **Retrieved** | Build script timestamp in `shared/geo-reference/manifests/psgc-psa-2025-2q.json` |
| **Reuse** | PSA publishes PSGC for public statistical use; **acknowledge PSA as source** in product/docs. Build tool package is not authoritative; committed artifact + manifest record provenance. |

PSA Classification API (`classification.psa.gov.ph`) requires an access token for automated download; this handover used the **published quarterly tables** via the documented build pipeline instead of inventing codes.

## 2. Dataset counts

| Level | Count |
|-------|------:|
| Regions | 18 |
| Provinces | 82 |
| Cities / municipalities | 1,632 |
| Barangays | 42,011 |
| **Nodes total** | **43,743** |

Artifact: `shared/geo-reference/artifacts/psgc-psa-2025-2q.json` (~4.0 MB bundled in Flutter).

## 3. Hierarchy

- **Provincial:** Region → Province → City/Municipality → Barangay  
- **Independent / HUC / ICC:** Region → City → Barangay (no artificial province parent)  
- **NCR:** 16 highly urbanized cities under region (no province nodes)

## 4. Flutter selectors

- Separate **Province**, **City / municipality**, and **Highly urbanized / independent city** controls (no combined “province or city” list).  
- Parent changes clear descendants.  
- Barangay list shows parent context for duplicate names.  
- Synthetic bundles show a warning banner.  
- Default bundle: `psgc-psa-2025-2q` (offline).

## 5. Barangay Tres verification

| Level | PSGC code | Name |
|-------|-----------|------|
| Region | `1000000000` | Region X (Northern Mindanao) |
| Province | `1004300000` | Misamis Oriental |
| Municipality | `1004302000` | Balingasag |
| Barangay | `1004302022` | Barangay 3 (Poblacion) — PO acceptance “Barangay Tres” |

Automated: `psgc_acceptance_test.dart`, `psgc_psa_acceptance.test.mjs`.

## 6. Offline operation

Bundled JSON in `sibol_app/assets/geo/`; no network for dropdown population.

## 7. Organization routing safeguards

- PSGC selection does **not** create organizations or roles.  
- Unmapped barangays: server `not-found` with user-facing message in Flutter.  
- **Emulator prototype only:** when `SIBOL_ALLOW_DEMO_IDENTITY=true`, pinned map `1004302022 → barangay03` (`demoPsgcShim.ts`) — documented explicit demo bridge, not silent production mapping.

## 8. Tests

| Suite | Result |
|-------|--------|
| Flutter | **107/107 PASS** |
| geo-reference | **7/7 PASS** |
| Cloud Functions | **PASS** (60) |
| Android debug build | **PASS** |

## 9. Android emulator UI

Full registration with new selectors: **NOT RUN** (agent).

## 10. Limitations

- Full national bundle increases app size (~4 MB).  
- Production orgs need `organizationIdentityKeys` for real PSGC codes; only demo shim covers Barangay 3 → `barangay03` in emulator.  
- PSA API token-based refresh remains an operator build step (`npm run build:psgc` in `shared/geo-reference`).

## 11. Resume QA

```bash
cd sibol_app
flutter run -d emulator-5554 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Register as Teen → select **Region X → Misamis Oriental → Balingasag → Barangay 3** → complete (requires Functions emulator with demo identity flags as today).
