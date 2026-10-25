# SIBOL-ORG-001-FIX-001 — Execution Report

**Work item:** SIBOL-ORG-001-FIX-001  
**Decision:** DEC-ORG-001 ([ADR-REG-005](../Architecture/ADRs/ADR-REG-005-Organization-Management-and-Operational-Capabilities.md))  
**Base HEAD:** `60bdafd`

## 1. Capability-to-dashboard mapping

| Dashboard action | Capability / resolver | Provider |
|------------------|----------------------|----------|
| Case list / detail | `case.read` | `barangayCaseOrgIdProvider` |
| New case (FAB) | `case.write` on case org | `barangayCanWriteCasesProvider` |
| Incoming requests | `coordination.barangay` | `barangayAssistanceOrgIdProvider` |
| Submit report to MOPH | `report.submit` | `barangayReportOrgIdProvider` |
| Submitted reports | `report.submit` | `barangayReportOrgIdProvider` |
| Submitted referrals | `coordination.barangay` | `barangayCoordinationOrgIdProvider` |
| Staff administration card | `org.manage_members` | `orgAdminManagedOrgIdsProvider` |
| Settings → org admin | `org.manage_members` | (unchanged) |

## 2. UI changes

- [`barangay_home_screen.dart`](../../sibol_app/lib/features/cases/presentation/screens/barangay_home_screen.dart): management card, gated operational buttons, case list only when `barangayCanReadCasesProvider`; user-facing copy instead of raw `StateError`.
- [`org_context_providers.dart`](../../sibol_app/lib/features/org/presentation/providers/org_context_providers.dart): capability boolean providers derived from existing org-id providers and `barangayHasCapabilityOnCaseOrg` for write.
- [`org_context_resolver.dart`](../../sibol_app/lib/features/org/domain/org_context_resolver.dart): `barangayGrantsCapability`, `barangayHasCapabilityOnCaseOrg` (resolver rules unchanged).
- [`org_capabilities.dart`](../../sibol_app/lib/features/org/domain/org_capabilities.dart): `orgManageRoles` constant.

## 3. Behaviors

| Persona | Dashboard |
|---------|-----------|
| **Management-only org admin** | Staff administration card; operational buttons disabled with tooltips; explanatory case panel; no case stream subscription |
| **Operational staff** | Operational actions enabled per caps; case list when `case.read`; FAB when `case.write` |
| **Dual-capability** | Management card + operational sections per granted caps |
| **Suspended membership** | No operational org context; explanatory panel |

## 4. Provisioning

No seed changes. [`emulator_seed.mjs`](../../shared/provisioning/src/emulator_seed.mjs) already separates `barangay_org_admin` (org caps) and `barangay_staff` (operational caps). Emulator not reseeded.

## 5. Dual-capability assignment

**Supported today:** org administrator can edit **staff** membership capabilities via `OrgAdminStaffScreen` → `AdminApi.updateMembershipCapabilities` (case.read / case.write in UI). Granting operational caps to **self** is server-dependent and not exercised in this work item; document as operator workflow / follow-up if server blocks self-elevation.

## 6. Tests

| Suite | Result |
|-------|--------|
| Flutter | **113/113 PASS** (includes `barangay_dashboard_capability_test.dart`, extended `org_context_resolver_test.dart`) |
| Functions / rules | Not modified |

## 7. Live QA

No emulator or membership mutations. **Hot restart** recommended so the org admin session loads the new dashboard layout.

**Follow-up:** FIX-002 addresses membership Firestore query denial that prevented the administration card from loading on device ([SIBOL_ORG_001_FIX_002_EXECUTION_REPORT.md](SIBOL_ORG_001_FIX_002_EXECUTION_REPORT.md)).

## 8. References

- [SIBOL_ORG_001_INV_001_INVESTIGATION_REPORT.md](SIBOL_ORG_001_INV_001_INVESTIGATION_REPORT.md)
