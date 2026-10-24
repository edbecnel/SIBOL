# SEC-REVIEW-001 — Barangay directory callable access (deferred)

> **Disposition:** R-01 **DEFER** — no authentication change in SIBOL-ORG-IDENTITY-001 tranche  
> **Work item:** SIBOL-ORG-IDENTITY-001  
> **Callable:** `regListBarangayDirectory` (VERIFIED: unauthenticated allowed today)

## Scope of review (when scheduled)

1. **Enumeration** — unauthenticated caller can list active barangay org names/ids.
2. **Privacy** — what fields are exposed; alignment with teen PSGC-first flow.
3. **Abuse** — rate limiting, App Check, callable quotas.
4. **Registration dependency** — teen target design should not require directory once PSGC resolution ships.

## Current planning position

- **No code or policy change** authorized under ORG-IDENTITY M0–M3 without separate PA approval.
- Teen registration amendment steers primary path to PSGC UI + identity-key resolution.

## Recommended review triggers

- Before production deploy of REG-C to public users.
- If directory remains unauthenticated after teen PSGC flow ships.

## Owner

Project Architect + Product Owner (privacy).

## Status

| Item | State |
|------|--------|
| Review executed | **No** |
| Findings | N/A |
| Remediation | N/A |
