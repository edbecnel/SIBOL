# Project Charter

> **Documentation path:** [Project Index](PROJECT_INDEX.md) → Project Charter

> **Status:** Draft
> **Owner:** _To be assigned_
> **Applies To:** SIBOL project governance and scope
> **Last Reviewed:** 2026-10-16

## Mission

**SIBOL** is an engineering project repository. This charter will be updated as the product or system definition matures. Documentation is governed by EDF Core so requirements, architecture, and reference material remain discoverable as the project grows.

## Goals

- Capture authoritative engineering documentation in a consistent, Git-native structure.
- Preserve existing reference material (including imagery under `Docs/Reference/`) without conflating artifacts with governed prose.
- Enable safe collaboration between human contributors and AI-assisted tooling.

## Non-Goals

- Replacing specialized engineering tools (CAD, simulation, firmware IDEs) with Markdown.
- Achieving full EDF reference parity on day one (AI handbook, governance domain, and profile-specific paths are adopted incrementally).

## Scope

### In Scope

- EDF Core documentation domains under `docs/` (filesystem: `Docs/` on this machine).
- Reference photographs and related material in `Docs/Reference/`.
- Architecture decisions, specifications, and user-facing guides as they are authored.

### Out of Scope

- Relocating pre-bootstrap content without an ADR and explicit approval.
- Software Engineering profile folders (`docs/API`, `docs/Database`, `docs/Deployment`, `docs/Developer_Handbook`) until the project is confirmed as a software deliverable.

## Stakeholders

| Role | Name / team |
|------|-------------|
| Project owner | _TBD_ |
| Maintainers | _TBD_ |
| Contributors | _TBD_ |

## Constraints

- **Documentation framework:** EDF Core (`edf-adoption.yaml` profile `core`).
- **Preservation:** Existing `Docs/Reference/` JPEG assets remain in place ([ADR-0001](docs/Architecture/ADRs/ADR-0001-Docs-Path-and-Reference-Imagery.md)).
- **Platform note:** macOS default volume is often case-insensitive; `Docs/` and `docs/` refer to the same directory here.

## Related Documents

- [Project Index](PROJECT_INDEX.md)
- [Architecture](docs/Architecture/README.md)
- [Specifications](docs/Specifications/README.md)
- [Reference imagery](docs/Reference/README.md)
