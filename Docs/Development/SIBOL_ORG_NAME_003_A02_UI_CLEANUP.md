# SIBOL-ORG-NAME-003 A02 — Remove redundant geographic site display

**Handover UUID:** `a1c74e39-6d82-4b50-9f13-e5c270a648bd`  
**PA decision:** Canonical organization names from `organizationDirectory/{orgId}` are sufficient for workflow UI; separate “Geographic site” / “Historical site label” rows are removed.

## UI

- `OrganizationIdentityDetailRows` shows a single **Barangay organization** row (directory `name` only).
- Missing `orgId` or directory failure → **Organization identity unavailable** / **Organization name unavailable** (not legacy site strings as the official name).

## Unchanged

- Firestore schemas, rules, projection, and historical `barangay` / `geographicSiteLabel` fields on records.
- Case create still stores functional case site label internally; teen registration and PSGC pickers unchanged.
