# SIBOL-REG-001 — Academic prototype closure (functional acceptance)

**Handover UUID:** `b4e81c62-7d39-4a50-9f26-c3a108e75d92`  
**Work item:** SIBOL-REG-001 — Registration, organization authorization, direct staff provisioning, password management  
**Implementation baseline (REG-FIX):** Git `19bfc20` on `main`  
**Offline-QA tag (unchanged):** `sibol-prototype-2026-10-26-offline-qa` → `807a324`  
**PA authorization:** Functional acceptance and EDF closure only — **no** source or Firebase changes under this handover.

## Closure classification

| Dimension | Status |
|-----------|--------|
| **Academic prototype (REG-001 scope)** | **Functionally accepted and closed** |
| **Production security readiness** | **Not accepted** — deferred remediation required (see below) |

SIBOL is **not** approved for production deployment or use with real adolescent health information until identified authorization vulnerabilities are corrected and independently verified.

## PA decision and rationale

The Project Architect accepts completed SIBOL-REG-001 **functional** QA for the academic demonstration prototype. The Product Owner’s technical representative confirmed successful operation of Barangay and MOPH staff provisioning, organization-scoped staff management, staff identity display, administrator-initiated password resets, mandatory password-change routing, persistent password-change confirmation, and sign-in after password changes.

A separate mandatory-password security investigation (`e5a91c73-8b46-4f20-9d62-3a7c58e104bf`) identified legitimate backend authorization gaps. The PA and user agreed to **defer** comprehensive remediation within the current prototype commitment, because SIBOL uses fictional accounts and local emulator demonstration data only. **Deferral does not classify those findings as acceptable for production.**

## Evidence provenance

Manual results below were **reported and observed through PA/user-led QA** on the local Firebase emulator (`sibol-286d0`) and Android emulator. This closure record does **not** claim new automated test runs, screenshots, or machine-generated timestamps for these sessions.

### Accepted manual functional QA

| Test | Result | Notes |
|------|--------|--------|
| UI-01 | **PASS** | Ordinary MOPH Settings access and authorization |
| UI-02 | **PASS** | Ordinary Barangay Settings access and authorization |
| UI-04 | **PASS** | Barangay administrator Staff Management access |
| SP-01 | **PASS** | Barangay staff provisioning and login |
| SP-02 | **PASS** | MOPH staff provisioning and operational access |
| MF-01 | **PASS** | MOPH administrator dashboard |
| MF-06/07 | **PASS** | MOPH Add Staff restricted to `coordination.hospital` |
| PR-01 | **PASS** | Barangay administrator password reset and mandatory password change |
| PC-01 | **PASS** | Change Password screen |
| PC-02 | **PASS** | Persistent password-change confirmation (OK to dismiss) |
| PC-03 | **PASS** | Barangay administrator login after password change |
| MF-08 | **PASS** | MOPH staff reset authorization |
| MF-09 | **PASS** | MOPH password-reset dialog |
| MF-10 | **PASS** | MOPH staff password reset |
| MF-11 | **PASS** | Mandatory password-change routing |
| MF-12 | **PASS** | MOPH mandatory password change |
| MF-13 | **PASS** | MOPH login using new password |

### Verified scenarios (operator-reported)

**Barangay:** Organization administrator reset password for `maria.qa.staff@sibol.local`. Staff signed in with temporary password, completed mandatory change, signed out, and signed in with the new password.

**MOPH:** MOPH administrator reset password for `moph.qa.staff@sibol.local`. Staff signed in with temporary password, was routed to mandatory change, completed change, signed out, and signed in with the new password; normal MOPH dashboard without repeated mandatory prompt.

**Persistent confirmation:** Success dialog remained until operator dismissed with OK.

## Traceability

| Topic | Record |
|-------|--------|
| REG-001 architecture / REG-A–C | [SIBOL_REG_001_REG_A_EXECUTION_REPORT.md](SIBOL_REG_001_REG_A_EXECUTION_REPORT.md), [SIBOL_REG_001_REG_B_EXECUTION_REPORT.md](SIBOL_REG_001_REG_B_EXECUTION_REPORT.md), [SIBOL_REG_001_REG_C_EXECUTION_REPORT.md](SIBOL_REG_001_REG_C_EXECUTION_REPORT.md) |
| Direct provisioning + REG-FIX implementation | [SIBOL_REG_001_DIRECT_PROVISIONING_EXECUTION_REPORT.md](SIBOL_REG_001_DIRECT_PROVISIONING_EXECUTION_REPORT.md) |
| Offline QA baseline | [SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md](SIBOL_OFFLINE_QA_001_EXECUTION_REPORT.md), tag `sibol-prototype-2026-10-26-offline-qa` |
| Mandatory-password security investigation | [SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md](SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md) |
| Production staff onboarding (deferred) | [SIBOL_REG_001_PRODUCTION_STAFF_ONBOARDING_DEFERRED.md](SIBOL_REG_001_PRODUCTION_STAFF_ONBOARDING_DEFERRED.md) |

## Deferred security findings (unresolved)

**Status:** **DEFERRED — FUTURE PRODUCTION SECURITY REQUIREMENT**

**Investigation handover:** `e5a91c73-8b46-4f20-9d62-3a7c58e104bf`

Findings (not mitigated for production):

1. Firestore operational rules do not enforce `mustChangePassword`.
2. Most protected Cloud Functions do not enforce that flag.
3. `regAcknowledgeMandatoryPasswordChange` can clear the restriction without independently verifying that the password was changed.
4. Flutter routing is a UI restriction, not a backend authorization boundary.
5. Offline caches and short-lived authentication tokens have additional limitations.

Full analysis and proposed remediation architecture: [SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md](SIBOL_REG_001_MANDATORY_PASSWORD_SECURITY_INVESTIGATION.md).

**Future work:** Implement via a **separately approved** work item before any production deployment; do not reopen REG-001 prototype functional scope for that effort.

## Remaining academic-prototype work (outside REG-001)

REG-001 registration and password-management implementation is **closed**. Other open register items (e.g. SIBOL-INT-001 operator scenarios, SIBOL-DEMO-*, T2-3 Android write QA) remain governed by their own work items and are **not** reopened or blocked by this closure.

## Completion (this handover)

- Documentation only; application code, Cloud Functions, Firestore rules, emulators, and production Firebase **unchanged**.
- Closure documentation commit published on `main` (see EA completion report for SHA).
