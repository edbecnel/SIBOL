# SIBOL-REG-001 — REG-B implementation specification

**Work item:** SIBOL-REG-001 / REG-B  
**Handover:** `SIBOL-REG-001-REG-B-AGENT-001`  
**Handover UUID:** `f3c8a271-6b49-4d0e-9a52-7e14c6b8d903`  
**SPEC-REG-001:** Remains **Draft**.

## Scope

Server-authoritative organization administration and staff invitation lifecycle, with Flutter administration screens. No live Firebase deploy.

## Data

| Collection | Client access |
|------------|----------------|
| `organizations` | Read via active membership (unchanged); writes **denied** |
| `organizationMemberships` | Self read (unchanged); writes **denied** |
| `organizationStaffInvitations` | **Denied** (callables only) |
| `auditEvents` | **Denied** (server append) |

Invitation ID: `inv_{22}`; membership ID: `mbr_{orgId}__{accountUid}`.

## Central Administrator

- Flag: `users.isCentralAdmin` (server-written; client update denied).
- Callables: create/list organizations, set org status, appoint org admin, list memberships, suspend/revoke memberships (via shared org-admin paths where applicable).
- Emulator bootstrap: `bootstrapCentralAdminForEmulator` (emulator-gated only).

## Organization Administrator

- Active membership with `org.manage_members` **and** `org.manage_roles` (org administrator).
- Invite staff, approve pending memberships, update staff capabilities (policy-limited), suspend/revoke staff, list/revoke invitations.
- Cannot grant `org.manage_*` to others; cannot self-approve or self-elevate; last active org admin protected.

## Invitation lifecycle

States: `pending` → `accepted` | `expired` | `revoked`. Email bound via SHA-256 hash; 7-day TTL; single-use acceptance transaction.

## Audit

`auditEvents` documents: actor, operation, targets, before/after capability snapshots, server timestamp.

## Flutter

Settings-linked administration routes for Central Admin and Org Admin; invitation acceptance screen. UI gating is not authorization.

## Out of scope (REG-B)

- Production email delivery.
- Live Central Admin bootstrap (PA-gated Admin SDK).
- REG-C teen registration policies.
- SpeakUp Connect.
