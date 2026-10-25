# SIBOL-QA-001 — End-to-End Referral Workflow Acceptance Report

**Work item:** SIBOL-QA-001  
**Test date:** 25 October 2026  
**Documentation baseline:** `fae390c`  
**Related fixes exercised in this session:** SIBOL-GEO-001, SIBOL-ORG-001, SIBOL-ASSIST-001-FIX-001, SIBOL-MOPH-001-FIX-001  

## Environment

| Item | Value |
|------|--------|
| Client | Android emulator `emulator-5554` |
| Firebase project | `sibol-286d0` (local emulators) |
| App flags | `ENVIRONMENT=development`, `USE_FIREBASE_EMULATORS=true` |
| Auth / Firestore / Functions | Host emulators (PO session; not reset during QA) |

## Acceptance status

**ACCEPTED** — Product Owner completed the fictional Teen → Barangay → MOPH referral workflow on device with all checklist steps observed **PASS** (see table below).

This report records **manual Android emulator QA** and **UI-level privacy observations**. It does not replace automated rules, Functions, or integration test suites.

## Workflow results (UI / functional)

| Step | Result |
|------|--------|
| Teen registration with PSGC Barangay selection | PASS |
| Teen assistance request submission | PASS |
| Barangay incoming request visibility | PASS |
| Barangay acknowledgment | PASS |
| Teen acknowledgment status visibility | PASS |
| Barangay minimum-information referral creation | PASS |
| Referral submission to MOPH | PASS |
| MOPH operational account authorization | PASS |
| MOPH referral inbox | PASS |
| MOPH referral detail and staff activity | PASS |
| No teenager identity or original request text in MOPH detail | PASS (UI observation) |

## Evidence identifiers

| Field | Value |
|-------|--------|
| Teen assistance request | `32sQiFj9v8T6R6T3Asih` |
| Teen UID | `pjHSdYK7Vh2qYAnBzu6FmMeWjUMU` |
| Barangay organization | `barangay03` |
| Barangay name (org) | Barangay 3 (Poblacion) |
| Geographic label (request) | Barangay 3, Balingasag |
| PSGC (teen selection) | `1004302022` |
| Referral display reference | `SIBOL-REF-764792470F7CE6C3` |
| Coordination thread | `CxsRXE0ciuhrxXalL0Ay` |
| Category | Counseling referral (demo) |
| MOPH phase (UI) | Referred |

## MOPH authorization clarification

An earlier dashboard failure occurred while signed in as **`moph.org.admin@sibol.local`** (management-only organization administrator; no `coordination.hospital`).

After signing in as **`moph.demo@sibol.local`** (operational hospital staff), the MOPH dashboard loaded and showed the referral.

**PO-verified operational account attributes:**

- `role: moph`
- `primaryOrgId: hospital01`
- Active canonical membership `mbr_hospital01__{uid}`
- Capability `coordination.hospital`

**Conclusion:** The final authorization failure was **account selection** (management-only vs operational), not a demonstrated defect in the operational authorization path after commits through `fae390c`. No further implementation change is required for that observation.

## Implementation commits relevant to this QA arc

| Commit | Scope |
|--------|--------|
| `c8030f1`, `60bdafd` | Teen `assignedBarangay` / PSGC-aligned barangay03 demo naming |
| `998048b`, `bdf8fdc` | Barangay org context and capability-aware dashboard |
| `ad5e74f` | Barangay acknowledgment by `orgId` (not display-label mismatch) |
| `fae390c` | MOPH dashboard Firestore authorization and operational context gating |

Coordination referral creation and thread persistence were validated in this QA run; server path is covered separately by Functions and rules tests (not re-run as part of this PO session).

## UI observations vs independently verified security

| Claim | Basis |
|-------|--------|
| End-to-end workflow usable on emulator | **PO Android UI** (this acceptance) |
| MOPH detail shows minimum-information fields only | **PO UI observation** (no teen name / original assistance description seen) |
| Teen assistance and private binding not readable by MOPH | **Rules / automated tests** (`shared/firestore-rules-test`, coordination scenarios); **not** re-audited live against PO Firestore during this checkpoint |
| Management-only MOPH denied operational inbox | **Rules tests** + PO experience on `moph.org.admin@sibol.local` |
| Operational MOPH inbox and detail | **PO UI** on `moph.demo@sibol.local` after `fae390c` |

## Limitations and untested behavior

- **Production** Firebase and release builds were not exercised.
- **Offline queue** behavior for acknowledgment or referral was not part of this acceptance path.
- **Aggregate barangay reports** on the MOPH dashboard were not required for referral acceptance (inbox may be empty).
- **Second hospital / cross-hospital isolation** not in scope (single demo hospital `hospital01`).
- **Automated regression** counts at `fae390c`: Flutter **123** tests; Firestore rules **106** scenarios (isolated emulator harness — not the PO emulator stack).
- PO emulator data (accounts, request, thread) was **preserved**; no export/import or reseed performed for this document.

## Resume QA (same session data)

```bash
cd /Users/edbecnel/Development/GitHub/SIBOL/sibol_app
flutter run -d emulator-5554 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=USE_FIREBASE_EMULATORS=true
```

Use **`moph.demo@sibol.local`** for hospital coordination QA; use **`moph.org.admin@sibol.local`** only for org-administration scenarios.
