# CONTRACT-REG-002 — Teen password recovery (prototype)

> **Status:** Implemented in repository (SIBOL-REG-002) — **not deployed** to `sibol-286d0` until authorized  
> **Plan handover:** `c42a8e71-9f35-4d60-b218-7a5c90e3f146`  
> **Implementation handover:** `e7a4c219-6b53-4d80-9f21-3c85b0e6a742`

## Product Owner decisions

| ID | Decision |
|----|----------|
| DEC-REG002-01 | Barangay org admins may list **display name** and **Auth sign-in email** only for teens in their barangay (recovery scope). |
| DEC-REG002-02 | Central Administrator may reset teen passwords for an **explicitly selected** active barangay org. |
| DEC-REG002-03 | Prototype `mustChangePassword` enforcement remains **Flutter-primary**; comprehensive REG-001 hardening is deferred. |

## Callables

### `regListTeensForBarangayOrgAdminRecovery`

**Auth:** Barangay org administrator (`org.manage_members` + `org.manage_roles`) or Central Administrator.

**Input:**

```json
{
  "managedBarangayOrgId": "string (required for central; required when actor manages multiple barangays)"
}
```

**Output:**

```json
{
  "managedBarangayOrgId": "barangay03",
  "organizationName": "Barangay 3 (Poblacion)",
  "teens": [
    { "teenUid": "…", "displayName": "…", "signInEmail": "…" }
  ]
}
```

**Authorization:** Server validates org type `barangay`, active org, and `users.selectedBarangayOrgId == managedBarangayOrgId`. Max **100** teens per response.

### `regResetTeenPasswordByBarangayOrgAdmin`

**Input:**

```json
{
  "managedBarangayOrgId": "string (when required)",
  "targetTeenUid": "string",
  "newPassword": "string (min 8)"
}
```

**Effects:** Updates Firebase Auth password, revokes refresh tokens, sets `mustChangePassword: true` and `passwordResetAt`. Writes `auditEvents` operation `teen_password_reset_by_org_admin`. Does **not** change `selectedBarangayOrgId` or create accounts.

## Production email recovery

Routine production recovery should use Firebase **`sendPasswordResetEmail`** (already exposed on the welcome/login flow). Administrator-issued temporary passwords are a **prototype break-glass** path only.

Production hardening backlog: rate limiting, identity verification, audit review, REG-001 server-side `mustChangePassword` enforcement, enumeration-safe messaging.

## Privacy

Recovery listing must not return `contactEmail`, `contactPhone`, case fields, or assistance content.
