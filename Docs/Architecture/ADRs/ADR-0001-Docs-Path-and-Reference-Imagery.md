# ADR-0001-Docs-Path-and-Reference-Imagery

[Home](../../../README.md) › [Project Index](../../../PROJECT_INDEX.md) › [Architecture](../README.md) › [Architecture Decision Records](README.md) › ADR-0001 Docs Path and Reference Imagery

| | |
|---|---|
| **Status** | Accepted |
| **Date** | 2026-10-16 |
| **Decision Makers** | Project owner (pending assignment); bootstrap performed with owner request |
| **Supersedes** | None |
| **Superseded By** | None |
| **Related** | [edf-project-context.yaml](../../../edf-project-context.yaml), EDF ADR-0006 (documentation vs artifacts) |

---

# Context

Before EDF bootstrap, the repository contained a `Docs/Reference/` folder with JPEG reference photographs. EDF canonical structure expects lowercase `docs/`. On a case-insensitive filesystem (typical macOS default), `Docs` and `docs` resolve to the same directory.

---

# Decision

1. **Preserve** all pre-bootstrap JPEG files in `Docs/Reference/` without relocation.
2. **Treat** the on-disk path `Docs/` as the project's documentation root, equivalent to EDF's `docs/` convention for navigation and tooling on this platform.
3. **Classify** JPEG files as **engineering artifacts** (reference imagery), not governed prose; link to them from [docs/Reference/README.md](../../Reference/README.md) rather than embedding binaries in Markdown.
4. **Document** this extension in `edf-project-context.yaml` under `extensions`.

Renaming `Docs` → `docs` on a case-insensitive volume is deferred until the repository is used on a case-sensitive host (for example Linux CI) where a deliberate migration plan is required.

---

# Consequences

- Framework Advisor may report "Markdown outside canonical locations" when displaying `Docs/` with capital **D**; links using lowercase `docs/` remain valid on macOS.
- Future Linux clones may need a one-time path normalization ADR if both `Docs` and `docs` ever coexist.
