# SIBOL-REG-001 — REG-A implementation specification

> **Status:** Active — implementation baseline for increment REG-A only  
> **Handover:** `SIBOL-REG-001-REG-A-AGENT-001`  
> **Work item:** SIBOL-REG-001  
> **Date:** 2026-10-24

## 1. Governance disposition (A0 gate)

| Question | Disposition |
|----------|-------------|
| May implementation proceed while [SPEC-REG-001](../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md) remains **Draft**? | **Yes.** [WORK_ITEM_DOCUMENTATION_PROCEDURE.md](WORK_ITEM_DOCUMENTATION_PROCEDURE.md) permits implementation against PA-authorized handover with traceability to accepted architecture ADRs. This document is the **increment-specific** normative baseline for REG-A. |
| Does REG-A AGENT handover promote SPEC-REG-001 to effective? | **No.** SPEC remains Draft until a separate PA/PO approval transition is recorded. |
| Architecture authority | [ADR-REG-001](../Architecture/ADRs/ADR-REG-001-Organization-Identity-and-Membership.md), [ADR-REG-002](../Architecture/ADRs/ADR-REG-002-Administrative-Authorization-and-Provisioning.md) — **Accepted (architecture)** via `SIBOL-REG-001-ARCH-DOC-001` |
| DEC traceability | DEC-001–DEC-008 implemented **partially** in REG-A (foundation only); see §3 |

**PA authorization scope (this handover):** Packages A0–A7 in repository only. **Not authorized:** Firebase deploy (DEPLOY-R1), M1 backfill, M2 case rules, admin UI, registration UI, SpeakUp Connect.

## 2. Traceability matrix (REG-A subset)

| SPEC-REG-001 section | REG-A action |
|----------------------|--------------|
| §3 Organization types | Schema `organizations.type` |
| §4 Security invariants | Partial — membership/org rules only; **cases unchanged** |
| §5 Organization lifecycle | Schema `status`; no creation UI |
| §7 Membership lifecycle | Schema + rules read paths |
| §8 Admin hierarchy | `isCentralAdmin` documented; **not writable by client**; bootstrap REG-B |
| §4.1 Cross-barangay cases | **Unresolved in REG-A** — acknowledged gap |

## 3. Technical decisions (locked for REG-A)

| Topic | Decision |
|-------|----------|
| Organization path | `organizations/{orgId}` |
| `orgId` format | `org` + 22 alphanumeric characters — regex `^org[0-9A-Za-z]{22}$` |
| Membership path | `organizationMemberships/{membershipId}` |
| `membershipId` | `mbr_{orgId}__{accountUid}` |
| Authorization | `capabilities[]` closed enum; admin caps ⊄ case caps |
| Central admin | `users.isCentralAdmin` server-only (client update blocked) |
| Org context | Resource / `contextOrgId` + membership; **no `activeOrgId` in REG-A** |

## 4. Capability vocabulary

See [`shared/reg/src/capabilities.mjs`](../../shared/reg/src/capabilities.mjs) and rules helper `capabilityGranted`.

## 5. Firestore rules scope (REG-A)

**Add:** `organizations`, `organizationMemberships`, `auditEvents`  
**Unchanged:** `users` (except implicit deny of new privileged fields via existing `displayName`-only update), `cases`, assistance, reports, coordination.

## 6. Authz module crosswalk (rules ↔ TypeScript)

| Capability | Rules function | TS `assertCapability` |
|------------|----------------|----------------------|
| (membership active) | `hasActiveMembership(orgId)` | `assertActiveMembership` |
| `case.read` | `capabilityGranted(orgId, 'case.read')` | same string |
| `org.manage_members` | `capabilityGranted(orgId, 'org.manage_members')` | same string |

Full list in `shared/reg/src/capabilities.mjs`.

## 7. Verification

| Gate | Command |
|------|---------|
| REG identifiers | `cd shared/reg && npm test` |
| Authz unit | `cd shared/functions && node --test test/authz.test.mjs` |
| Rules | `cd shared/firestore-rules-test && npm test` |
| Flutter | `cd sibol_app && flutter test && flutter analyze` |

MVR-REG scenarios for M2 — **NOT RUN** in REG-A.

## 8. Related documents

- [SPEC-REG-001](../Specifications/SPEC-REG-001-Registration-and-Organization-Authorization.md) (Draft)
- [CONTRACT-REG-001](../../shared/docs/CONTRACT-REG-001-Registration-and-Administration-Services.md) (Proposed)
- Revised plan: `reg-a_foundation_plan_fefecd35.plan.md` (Cursor plans)
