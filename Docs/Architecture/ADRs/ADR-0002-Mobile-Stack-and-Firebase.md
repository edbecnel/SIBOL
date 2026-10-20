# ADR-0002: Mobile stack and Firebase backend

> **Status:** Accepted  
> **Date:** 2026-10-20  
> **Work item:** SIBOL-IMP-001

## Context

SIBOL requires a working Android/iOS academic prototype with fictional data, offline-capable record access, and simulated reporting.

## Decision

- Use **Flutter/Dart** for native **Android and iOS** only.
- Use **Firebase** (Authentication, Cloud Firestore, Cloud Functions for trusted operations).
- Use **Riverpod** and **go_router** following adapted SpeakUp Connect patterns.
- **Flutter Web is prohibited.**
- Future browser access will use a separate web-native stack (`sibol_web/` placeholder).

## Consequences

- New dedicated Firebase project required (not SpeakUp Connect).
- EDF software-engineering documentation expanded under `Docs/Development/` and `Docs/Specifications/`.

## Related

- [ADR-0003](ADR-0003-Authorization-and-Server-Reporting.md)
- [ADR-0004](ADR-0004-Offline-Sync-and-Common-Core-Boundaries.md)
