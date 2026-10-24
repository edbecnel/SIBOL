# Tranche 1 verification summary

> **Work items:** SIBOL-IMP-001, SIBOL-T1-CLOSE, post-T1 FB corrections  
> **Last updated:** 2026-10-20  
> **Acceptance:** [TRANCHE_1_ACCEPTANCE_REPORT.md](../Development/TRANCHE_1_ACCEPTANCE_REPORT.md)

## 1. Automated verification

**Command:**

```bash
cd sibol_app && flutter test
```

**Result (2026-10-20):** **28 passed**, 0 failed.

| Test file | Focus |
|-----------|--------|
| `test/case_validation_test.dart` | Fictional case validation |
| `test/sibol_role_test.dart` | Role enum parsing |
| `test/widget_test.dart` | Theme |
| `test/login_screen_test.dart` | Login render + field focus/input |
| `test/app_redirect_test.dart` | Auth redirect matrix |
| `test/auth_profile_provider_test.dart` | Profile provider / retry |
| `test/startup_navigation_test.dart` | Signed-out → Welcome; Sign in / Register as Teen navigation |

```bash
cd sibol_app && flutter analyze
```

**Result:** No analyzer errors; `prefer_const` info hints only.

**Not executed in Tranche 1 closure:**

- Firestore Security Rules unit tests (emulator)
- Cloud Functions integration tests
- Full iOS Device Hub manual UI matrix

## 2. Build verification (engineering agent, delivery period)

| Platform | Command | Result |
|----------|---------|--------|
| Android | `flutter build apk --debug` | Success (see [TRANCHE_1_EXECUTION_REPORT.md](../Development/TRANCHE_1_EXECUTION_REPORT.md) §10) |
| iOS | `flutter build ios --debug --no-codesign` | Success (§11) |

## 3. Live Firebase verification (project owner)

**Project:** `sibol-286d0`  
**Method:** Android emulator, `flutter run`, demonstration accounts (passwords not recorded).

| Role | Sign-in | Expected UI | Owner result |
|------|---------|-------------|--------------|
| Teen | `teen.demo@sibol.local` | Teenager dashboard | Pass |
| Barangay | `barangay.demo@sibol.local` | Case list (5 fictional cases) | Pass |
| MOPH | `moph.demo@sibol.local` | MOPH placeholder dashboard | Pass |

Detailed human procedure: [Records/MVR-0001-tranche1-role-walkthrough.md](Records/MVR-0001-tranche1-role-walkthrough.md).

## 4. iOS notes

- Application builds and runs on iPhone 18 Pro simulator with live Firebase.
- **Device Hub** pointer interaction reported unreliable; keyboard Tab/Return used for barangay sign-in in some sessions.
- Classified as **open environment concern** — not a verified application defect (FB-004 widget tests pass).

## 5. Traceability

- Functional acceptance: [TRANCHE_1_ACCEPTANCE_REPORT.md](../Development/TRANCHE_1_ACCEPTANCE_REPORT.md)  
- Implementation baseline: [TRANCHE_1_EXECUTION_REPORT.md](../Development/TRANCHE_1_EXECUTION_REPORT.md)  

## 6. EDF conformance snapshot (optional)

`adopt-edf.sh validate` on 2026-10-20: overall **27%**, structure **100%**. Full report: `reports/conformance/framework-advisor-20261020-203159.txt` (gitignored). See [ADOPTION_STATUS.md](../../ADOPTION_STATUS.md).
