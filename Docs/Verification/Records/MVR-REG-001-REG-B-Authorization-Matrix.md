# MVR-REG-001 — REG-B repository authorization matrix

**Scope:** Emulator/unit tests. **Not** production MVR execution.

| Scenario | Evidence | Executed |
|----------|----------|----------|
| Central Admin create organization | `admin.operations.test.mjs` | Yes |
| Non-central create denied | `admin.operations.test.mjs` | Yes |
| Org Admin list own org memberships | `admin.operations.test.mjs` | Yes |
| Cross-org list denied | `admin.operations.test.mjs` | Yes |
| Staff invite → accept → approve | `admin.operations.test.mjs` | Yes |
| Self-approve denied | `admin.operations.test.mjs` | Yes |
| Self capability change denied | `admin.operations.test.mjs` | Yes |
| Org admin cannot grant org.manage_* | `admin.operations.test.mjs` | Yes |
| Duplicate invitation | `admin.operations.test.mjs` | Yes |
| Wrong recipient accept | `admin.operations.test.mjs` | Yes |
| Revoked / expired / replay invitation | `admin.operations.test.mjs` | Yes |
| Last org admin protection | `admin.operations.test.mjs` | Yes |
| Suspended org blocks invite | `admin.operations.test.mjs` | Yes |
| Audit on organization create | `admin.operations.test.mjs` | Yes |
| Emulator-only central bootstrap | `admin.operations.test.mjs` | Yes |
| Client invitation read/write denied | `staff_invitations.rules.test.mjs` | Yes |
| Client audit denied | `organizations_memberships.rules.test.mjs` | Yes |
