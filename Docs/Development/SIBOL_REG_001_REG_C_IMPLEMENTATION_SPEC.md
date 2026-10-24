# SIBOL-REG-001 — REG-C implementation specification

**Handover:** `SIBOL-REG-001-REG-C-AGENT-001`  
**Handover UUID:** `c6f18a42-9e73-4b05-a2d8-61f0c9e735ab`  
**SPEC-REG-001:** Remains **Draft**.

## Scope

Teen self-registration via Firebase Auth + server profile creation; Barangay directory for routing; provisional onboarding policy (PO fields pending).

## Server

| Callable | Purpose |
|----------|---------|
| `regListBarangayDirectory` | Public list of active barangay orgs (`orgId`, `name`) |
| `regRegisterTeenAccount` | Create teen `users/{uid}` only; no memberships |

Policy: `shared/functions/src/teen/onboardingPolicy.ts` (email gates default **off** for demo).

## Client

Multi-step `TeenRegistrationScreen`, email verification / complete routes, password reset, login entry points. Assistance gated when `!profile.teenAssistanceAllowed`.

## Explicit non-goals (PO pending)

DOB, government ID, parental consent workflow, legal consent text, retention/deletion, production email policy.

## Contract

[CONTRACT-REG-C-Teen-Registration.md](../../shared/docs/CONTRACT-REG-C-Teen-Registration.md)
