# SIBOL v0.5.0 — Android & iOS demonstration milestone

> **Classification:** Demonstration milestone — **not** a general production launch  
> **Publication date:** 2026-10-22  
> **EDF record:** SIBOL-REL-005 (handovers `c6e1d4a9-…`, publication `0f3e8b29-…`)

## 1. Published release traceability

| Field | Value |
|-------|--------|
| Repository | https://github.com/edbecnel/SIBOL |
| GitHub Release | https://github.com/edbecnel/SIBOL/releases/tag/v0.5.0 |
| Tag | `v0.5.0` (**immutable** — do not move) |
| Release commit | `ba7c1338c8d17e5f65177188077d54d7afa15e99` |
| Branch | `main` |
| Pre-demo restore tag (historical) | `sibol-demo-003-working-baseline` → `c06fd2bb12c050850761eaccae8f6054c5c8314a` |

Live Firebase demonstration project: `sibol-286d0` (rules/index deploy evidence in DEMO-003/004 execution reports and verification artifacts).

## 2. Milestone scope (by work item)

Authoritative implementation and acceptance detail remains in each execution report and linked MVR. This section summarizes only.

### SIBOL-DEMO-002 — Teen assistance requests

- Teen submits fictional assistance requests; **My Requests** lists own submissions.  
- **Records:** [SIBOL_DEMO_002_EXECUTION_REPORT.md](SIBOL_DEMO_002_EXECUTION_REPORT.md), [MVR-0003](../Verification/Records/MVR-0003-demo-002-teen-assistance-emulator.md) (emulator, live Firebase).

### SIBOL-DEMO-003 — Barangay request processing

- Barangay **Incoming requests**, acknowledge workflow; teen sees acknowledgment status.  
- **Records:** [SIBOL_DEMO_003_EXECUTION_REPORT.md](SIBOL_DEMO_003_EXECUTION_REPORT.md), [MVR-0004](../Verification/Records/MVR-0004-demo-003-barangay-ack-emulator.md).

### SIBOL-DEMO-004 — Municipal (MOPH) reporting

- Barangay aggregate submit; MOPH submitted-reports list and detail; Firestore rules and composite indexes for authorized queries (including post–query-fix index deploy).  
- **Records:** [SIBOL_DEMO_004_EXECUTION_REPORT.md](SIBOL_DEMO_004_EXECUTION_REPORT.md), [MVR-0005](../Verification/Records/MVR-0005-demo-004-moph-reporting-emulator.md).

### SIBOL-DEMO-005 — Submission history and receipts

- Barangay **Submitted reports** history and persistent **submission receipt**; cross-login persistence verified.  
- **Records:** [SIBOL_DEMO_005_EXECUTION_REPORT.md](SIBOL_DEMO_005_EXECUTION_REPORT.md), [MVR-0006](../Verification/Records/MVR-0006-demo-005-barangay-report-history-emulator.md).  
- **Gap:** Post-submit automatic navigation to receipt after a **new** live submission — **not** operator-verified (MVR-0006 §Not tested).

### Supporting delivery (included in tag tree, not demo slice IDs)

- Tranche 2 barangay case management, launcher branding ([SIBOL_UI_001_EXECUTION_REPORT.md](SIBOL_UI_001_EXECUTION_REPORT.md)), T2-3 rules hardening — see [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md).

## 3. Automated verification evidence (repository records)

Figures below are taken from **documented** EA runs at DEMO-004/005 completion; not re-run for REL-005.

| Check | Authoritative figure | Primary reference |
|-------|---------------------|-------------------|
| Firestore rules emulator | **36/36** | [SIBOL_DEMO_005_EXECUTION_REPORT.md](SIBOL_DEMO_005_EXECUTION_REPORT.md) §5; [shared/firestore-rules-test/README.md](../../shared/firestore-rules-test/README.md) |
| Flutter unit/widget tests | **55 passed** | [SIBOL_DEMO_005_EXECUTION_REPORT.md](SIBOL_DEMO_005_EXECUTION_REPORT.md) §5 |
| Flutter analyze | **0 errors** (pre-existing warnings) | Same |
| Debug APK build | **Success** | DEMO-004/005 execution reports |
| Live composite indexes | **Six** READY on `sibol-286d0` | [firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json](../Verification/Artifacts/firestore.indexes.post-demo-004-query-fix-deploy-2026-10-22.metadata.json) |

## 4. Physical-device deployment milestone

### 4.1 Android (backup demonstration device)

| Item | Record |
|------|--------|
| Device | Samsung Galaxy S9 |
| OS | Android 10 |
| Result | Flutter install and launch **successful**; Teen, Barangay, and MOPH demonstration workflows **exercised successfully** (operator-reported; PA acceptance for REL-005) |
| Role | **Backup** demonstration device |

*Distinct from emulator MVRs (§2) and from [SIBOL_DEMO_001_EXECUTION_REPORT.md](SIBOL_DEMO_001_EXECUTION_REPORT.md) (Realme Note 50 / other PO device tracks).*

### 4.2 iOS (physical iPhone)

| Item | Record |
|------|--------|
| Device | Physical iPhone, **iOS 27.0.1** |
| Signing | Xcode automatic signing with developer **Personal Team** (see §5) |
| Build | **Release** build used so SIBOL launches from Home Screen without Flutter tooling attached |
| Launch | **Confirmed successful** on device |
| Workflow depth | **Not documented** — do **not** claim full Teen/Barangay/MOPH retest on iPhone unless separate MVR is filed |

## 5. iOS deployment findings (development tooling)

Documented for future engineering; **not** classified as application defects without further evidence.

1. Xcode signing required Apple **development team** assignment in `ios/Runner.xcodeproj/project.pbxproj` (present at release commit `ba7c133`).
2. Operator must trust the locally signed developer app in iOS **Settings** before first launch.
3. Flutter **debug** builds did not launch independently from the iPhone Home Screen (expected Flutter/debug limitation for this workflow).
4. `flutter build` release path completed, but Flutter CLI did not locate the expected application bundle path.
5. Actual release bundle found at: `sibol_app/build/ios/Release-iphoneos/Runner.app` (relative to `sibol_app/`).
6. Successful install used: `xcrun devicectl device install app --device <DEVICE_ID> build/ios/Release-iphoneos/Runner.app` (device identifier omitted from EDF).
7. SIBOL then launched successfully from the device.

**Operator security follow-up:** Mac development-signing **Keychain** access was temporarily relaxed during troubleshooting; restore stricter access control on the signing key (operator action — not an app change).

## 6. Known limitations and follow-up

| Item | Status |
|------|--------|
| Production / public deployment | **Out of scope** — demonstration milestone only |
| Frecy primary Android phone | Install and verification **pending** |
| Samsung Galaxy S9 | **Backup** demo device (§4.1) |
| Full iOS role workflow verification | **Not documented** |
| DEMO-005 post-submit receipt navigation (new submit) | **Not operator-tested** (MVR-0006) |
| Keychain access control | **Operator follow-up** (§5) |

## 7. Related indexes

- [WORK_ITEM_REGISTER.md](WORK_ITEM_REGISTER.md)  
- [Docs/Verification/README.md](../Verification/README.md)  
- [CHANGELOG.md](../../CHANGELOG.md) — `[0.5.0]` entry (REL-005)
