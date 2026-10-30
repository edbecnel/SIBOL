# SIBOL-RELEASE-BASELINE-001 — Last known-good demonstration source baseline

**Handover UUIDs:** `a6c2d871-5e49-4f03-b714-9c80e2d653ab` (investigation); `e47c6a21-8f39-4d05-a7b2-6c90d13e5f84` (final tagging)  
**Work item:** SIBOL-RELEASE-BASELINE-001  
**Date:** 2026-10-30  
**Branch:** `main`  
**Classification:** **COMPLETE** — pre-enhancement source tag applied; unified demo known-good tag not applied (see §5.3, §6)

## 1. Authorization and scope

| Authorized | Executed |
|------------|----------|
| Git history, tags, commit timestamps | **Yes** |
| EDF delivery and build records (read-only) | **Yes** |
| Annotated tag `SIBOL-DEMO-2026-10-29-KNOWN-GOOD` if evidence supports single revision | **No** — blocked by §6 |
| Firebase operations | **No** |
| Application builds or executions | **No** |
| Demonstration-phone connection | **No** |

## 2. Git state (this session)

| | |
|---|---|
| **Starting HEAD** | `194f3ff711b237cb33ecae342d914e280e48327d` — `docs: CASE-LIFECYCLE-001 spec, MVR, walkthrough, and report` |
| **Ending HEAD** | Same (documentation-only commit follows) |
| **Branch** | `main` tracking `origin/main` |
| **Preserved unstaged (not staged)** | `sibol_app/ios/Podfile.lock`, deleted SwiftPM `Package.resolved` under iOS workspace (CASE-LIFECYCLE / iOS WIP) |

### 2.1 Pre–CASE-LIFECYCLE-001 boundary on `main`

| Commit | Timestamp (+0800) | Subject |
|--------|-------------------|---------|
| `c916b0f90c047c740fde74c27fcf1db64281ffe9` | 2026-10-27 18:26:00 | `fix(auth): isolate teen email password recovery from login state (AUTH-006)` |
| *(no commits)* | 2026-10-28 – 2026-10-29 | — |
| `ee10100…` | 2026-10-30 21:10:31 | First commit of CASE-LIFECYCLE / FIREBASE-ISOLATION tranche |

**Verified:** `c916b0f` is the tip of `main` immediately before all 2026-10-30 CASE-LIFECYCLE-001 and SIBOL-FIREBASE-ISOLATION-001 commits. This matches the CASE-LIFECYCLE Git baseline cited by the Product Owner and the isolation remediation report (starting HEAD `c916b0f` before `ee10100`).

**Candidate `c916b0f`:** Confirmed as the **final pre-enhancement source revision** on `main`; not assumed without the timeline above.

## 3. Existing release tags (context)

| Tag | Points to | Notes |
|-----|-----------|--------|
| `v0.5.0` | `ba7c1338c8d17e5f65177188077d54d7afa15e99` | Immutable demo milestone tag ([SIBOL_v0.5.0_RELEASE_MILESTONE.md](SIBOL_v0.5.0_RELEASE_MILESTONE.md)) |
| `sibol-demo-003-working-baseline` | `c06fd2bb12c050850761eaccae8f6054c5c8314a` | Pre–DEMO-004 restore point |
| `sibol-prototype-2026-10-26-offline-qa` | (see `git show`) | Offline QA preservation |
| `SIBOL-PRE-ENHANCEMENT-2026-10-29` | `c916b0f90c047c740fde74c27fcf1db64281ffe9` | Annotated source baseline before 2026-10-30 CASE-LIFECYCLE work (§6.1) |
| `SIBOL-DEMO-2026-10-29-KNOWN-GOOD` | — | **Not created** — intentionally deferred (install/certification scope; §6) |

## 4. Production-connected build metadata (@ `c916b0f`)

Values from tree at `c916b0f` (no build executed in this session).

| Field | Value |
|-------|--------|
| Firebase project | `sibol-286d0` (`sibol_app/lib/config/firebase_options.dart`) |
| Android application ID | `com.most.sibol.sibol_app` |
| iOS bundle (FlutterFire) | Same project; iOS app id `1:1057794781295:ios:3d2cbfccd922e78ae49d9a` |
| App version | `0.1.0+1` (`sibol_app/pubspec.yaml`) |
| Release build flags (documented practice) | `--dart-define=ENVIRONMENT=production`, `--dart-define=USE_FIREBASE_EMULATORS=false` |
| Android release signing | **Debug keystore** (`signingConfig = debug` in `android/app/build.gradle.kts`) — prototype practice per [SIBOL_DELIVERY_001_EXECUTION_REPORT.md](SIBOL_DELIVERY_001_EXECUTION_REPORT.md) |
| iOS release signing | Xcode **Personal Team** automatic signing documented at `v0.5.0` / `ba7c133` |

No credentials, keystore passwords, or team identifiers are recorded here.

## 5. Release evidence linking source to demonstration installs

### 5.1 Verified facts

1. **Git:** Last `main` commit before 2026-10-30 enhancement work is **`c916b0f`** (§2.1).
2. **Android (Galaxy S9, production release):** EDF records a chain of **`adb install -r`** production release APKs on Samsung **SM-G960U** (Galaxy S9), preserving app data, through:
   - [SIBOL_DELIVERY_003_EXECUTION_REPORT.md](SIBOL_DELIVERY_003_EXECUTION_REPORT.md) — Git revision **`f96b362`**, APK SHA-256 documented, install success 2026-10-27 UTC
   - [SIBOL_REG_002_HOTFIX_001_EXECUTION_REPORT.md](SIBOL_REG_002_HOTFIX_001_EXECUTION_REPORT.md), [SIBOL_REG_004_EXECUTION_REPORT.md](SIBOL_REG_004_EXECUTION_REPORT.md), [SIBOL_REG_004_P0_TEEN_AUTH_EXECUTION_REPORT.md](SIBOL_REG_004_P0_TEEN_AUTH_EXECUTION_REPORT.md)
   - [SIBOL_AUTH_006_EXECUTION_REPORT.md](SIBOL_AUTH_006_EXECUTION_REPORT.md) — release APK + Galaxy S9 install after AUTH-006; agent completion record ties implementation end to commit **`c916b0f`**
3. **Firebase backend:** Live project remains **`sibol-286d0`**. REG-005 deployed `regRegisterTeenAccount` at **`420108b`** (2026-10-27) with **no Flutter/APK change** required ([SIBOL_REG_005_EXECUTION_REPORT.md](SIBOL_REG_005_EXECUTION_REPORT.md)).
4. **CASE-LIFECYCLE-001:** Implementation explicitly states **no production Firebase operations, deploy, or phone installs** during that tranche ([SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md](SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md)).

### 5.2 Reasonable but unconfirmed associations

| Association | Basis | Gap |
|-------------|--------|-----|
| “Three student demonstration phones” all run **`c916b0f`** Android release | PO intent; S9 is the only device with a **documented** production release install trail ending at AUTH-006 | Repository does **not** name or inventory three student phones; no EDF install record for Realme Note 50 or other handsets after 2026-10-21 |
| All production-connected demo handsets updated together | Sequential `install -r` on S9 suggests engineering used one release line | PO may install elsewhere without EDF capture |

### 5.3 Documented platform divergence (blocks single shared tag)

| Platform | Last EDF-documented physical install | Source revision |
|----------|--------------------------------------|-----------------|
| **Android** (Galaxy S9, production release) | AUTH-006 / delivery chain | **`c916b0f`** (strong) |
| **iOS** (physical iPhone) | [SIBOL_v0.5.0_RELEASE_MILESTONE.md](SIBOL_v0.5.0_RELEASE_MILESTONE.md) §4.2 — Release `Runner.app` via `devicectl`, launch confirmed | **`ba7c133`** (`v0.5.0` release commit, 2026-10-22) |
| **Android** (Realme Note 50) | [SIBOL_DEMO_001_EXECUTION_REPORT.md](SIBOL_DEMO_001_EXECUTION_REPORT.md) — **debug** APK 2026-10-21; [SIBOL_DEMO_002_EXECUTION_REPORT.md](SIBOL_DEMO_002_EXECUTION_REPORT.md) — production repeat **pending** | **Not** tied to `c916b0f` in EDF |

**Verified:** `ba7c133` is an ancestor of `c916b0f` (`151` commits between), but **installed iOS binary** is not evidenced as rebuilt or reinstalled after 2026-10-22.

Per handover §3: **do not apply** a single shared tag when Android and iOS **release revisions** differ in available evidence.

## 6. Tag decision and verification

### 6.1 Authorized pre-enhancement source tag (PA `e47c6a21-…`)

| Item | Value |
|------|--------|
| **Tag name** | `SIBOL-PRE-ENHANCEMENT-2026-10-29` |
| **Type** | Annotated (not lightweight) |
| **Target commit** | `c916b0f90c047c740fde74c27fcf1db64281ffe9` |
| **Points at** | `main` tip immediately before 2026-10-30 CASE-LIFECYCLE / isolation commits (§2.1) |
| **Certifies** | **Repository source baseline only** — PA explicitly does **not** certify that all three demonstration phones were built from this commit |
| **Does not capture** | Live Firebase backend state; installed APK/IPA provenance on undocumented handsets |

**Pre-create checks (2026-10-30):**

| Check | Result |
|-------|--------|
| Target commit exists | **Pass** — `c916b0f…`, subject AUTH-006, timestamp 2026-10-27 18:26 +0800 |
| Matches investigation baseline | **Pass** — same SHA as §2.1 |
| Tag absent locally before create | **Pass** |
| Tag absent on `origin` before push | **Pass** |
| Tag not placed on current `HEAD` (`61b8050`) | **Pass** — tag on historical commit only |

**Local verification (after create):**

```text
git rev-parse SIBOL-PRE-ENHANCEMENT-2026-10-29^{}
→ c916b0f90c047c740fde74c27fcf1db64281ffe9
```

**Remote verification (after `git push origin refs/tags/SIBOL-PRE-ENHANCEMENT-2026-10-29`):**

```text
git ls-remote --tags origin refs/tags/SIBOL-PRE-ENHANCEMENT-2026-10-29^{}
→ c916b0f90c047c740fde74c27fcf1db64281ffe9
```

Annotated tag object on `origin`: `f5c514ae127739f97ba7f97b19cf36f818be4dbc` (peels to `c916b0f`).

### 6.2 Unified demo known-good tag (not applied)

| Item | Outcome |
|------|---------|
| Tag | `SIBOL-DEMO-2026-10-29-KNOWN-GOOD` |
| **Created / pushed** | **No** — per PA restriction; not overwritten if it existed |
| **Reason (investigation)** | Documented **Android** last production release install aligns with **`c916b0f`**; documented **iOS** last physical release install aligns with **`ba7c133`** (§5.3). That tag name implied install certification; PA chose **`SIBOL-PRE-ENHANCEMENT-2026-10-29`** for source-only preservation instead. |

## 7. Compiled release artifacts (local machine, not git)

| Artifact | Observation |
|----------|-------------|
| `sibol_app/build/app/outputs/flutter-apk/app-release.apk` | Present; mtime **2026-10-28** (local filesystem). **Git revision not embedded in EDF** for this file; treat as **unverified** against `c916b0f` until rebuild-from-tag or PO attestation. |
| `sibol_app/build/ios/Release-iphoneos/Runner.app` | Present; mtime **2026-10-30** — likely **post–`c916b0f`** tree (CASE-LIFECYCLE session). **Not** evidence of demonstration-phone baseline. |

APK artifacts are gitignored; reproduction requires checkout of target commit and documented `flutter build apk --release` defines (§4).

## 8. Reproduction limitations

- Cannot read installed version or commit from demonstration phones (not connected).
- Cannot match local APK to `c916b0f` without rebuild at that commit or binary provenance record.
- iOS install requires Mac, Personal Team signing, and device trust steps in v0.5.0 milestone §5.
- Live Firebase **Functions/rules/indexes** may differ from tree at `c916b0f` (e.g. REG-005 deploy at `420108b`, DELIVERY-003 callables) while client at `c916b0f` remains compatible — **backend state is not rolled back by source tag**.

## 9. Source preservation vs Firebase / data recovery

| Concern | This work item |
|---------|----------------|
| **Source preservation** | Git annotated tag **`SIBOL-PRE-ENHANCEMENT-2026-10-29`** → **`c916b0f`** on `origin` (§6.1) |
| **Firebase / data recovery** | **Out of scope** — no Firebase reads, exports, deploys, or backups performed or authorized |

## 10. Safety confirmation

| Restriction | Status |
|-------------|--------|
| Firebase operations | **None** |
| Application builds / runs | **None** |
| Demonstration phones (all three) | **Not connected or modified** |
| Destructive Git | **None** |
| Unrelated iOS uncommitted changes | **Preserved** (not staged) |

## 11. References

- [SIBOL_v0.5.0_RELEASE_MILESTONE.md](SIBOL_v0.5.0_RELEASE_MILESTONE.md)
- [SIBOL_DELIVERY_003_EXECUTION_REPORT.md](SIBOL_DELIVERY_003_EXECUTION_REPORT.md)
- [SIBOL_AUTH_006_EXECUTION_REPORT.md](SIBOL_AUTH_006_EXECUTION_REPORT.md)
- [SIBOL_FIREBASE_ISOLATION_001_REMEDIATION_REPORT.md](SIBOL_FIREBASE_ISOLATION_001_REMEDIATION_REPORT.md) — baseline `c916b0f` before isolation commits
- [SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md](SIBOL_CASE_LIFECYCLE_001_IMPLEMENTATION_REPORT.md)
