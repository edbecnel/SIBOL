# SIBOL-REG-001 — REG-A execution report

> **Handover:** `SIBOL-REG-001-REG-A-AGENT-001`  
> **Work item:** SIBOL-REG-001 increment REG-A  
> **Git start:** `21b2c02999c38c0a2926d6fd0cddf3a0c8c18879`  
> **Date:** 2026-10-24

## 1. A0 governance evidence

| Item | Result |
|------|--------|
| Implementation spec | [SIBOL_REG_001_REG_A_IMPLEMENTATION_SPEC.md](SIBOL_REG_001_REG_A_IMPLEMENTATION_SPEC.md) |
| SPEC-REG-001 remains Draft | **Yes** — not promoted |
| ADR-REG-001/002 authority | Architecture accepted; REG-A implements foundation subset |
| Deploy authorized | **No** — rules changed in repo only |

## 2. Implementation summary (A1–A6)

| Package | Deliverable |
|---------|-------------|
| A1 | `shared/reg/`, `shared/contracts/organization*.schema.json` |
| A2 | `shared/functions/src/authz/*`, `test/authz.test.mjs` |
| A3 | `organizations_memberships.rules.test.mjs` |
| A4 | `firestore.rules` REG-A matches; `isCentralAdmin` client write blocked |
| A5 | Regression — see §3 |
| A6 | `sibol_app/lib/features/org/` read-only repository |

## 3. Verification (executed)

| Suite | Command | Result |
|-------|---------|--------|
| REG identifiers | `cd shared/reg && npm test` | **6/6 pass** |
| Authz unit | `cd shared/functions && node --test test/authz.test.mjs` | **5/5 pass** |
| Coordination callable | `cd shared/functions && npm test` | **10/10 pass** (incl. emulator) |
| Firestore rules | `cd shared/firestore-rules-test && npm test` | **77/77 pass** (66 prior + 11 REG-A) |
| Flutter tests | `cd sibol_app && flutter test` | **74/74 pass** |
| Flutter analyze | `cd sibol_app && flutter analyze` | **0 errors**; 2 warnings (pre-existing), info hints |

MVR-REG-001 scenarios — **NOT RUN** (plan only).

## 4. Security disposition

- **Cross-barangay `cases/*` access:** **Still present** — unchanged in REG-A.
- **REG-A adds:** org/membership read gates; audit deny-all; membership client write deny.
- **M1/M2:** Separate PA handovers required.

## 5. Capability vocabulary (final)

`org.manage_members`, `org.manage_roles`, `case.read`, `case.write`, `report.submit`, `coordination.barangay`, `coordination.hospital` — see `shared/reg/src/capabilities.mjs`.

## 6. orgId format

`^org[0-9A-Za-z]{22}$` (25 characters total).

## 7. PA acceptance

**Pending** operator/PA review.

## 8. Git record

| Field | Value |
|-------|-------|
| Start HEAD | `21b2c02999c38c0a2926d6fd0cddf3a0c8c18879` |
| End HEAD | `a287e53e7be170eca97976038f099694e6bb4ae6` |
| Commits | `3244e2c` (foundation), `a287e53` (docs) |
| Push | `origin/main` success |
