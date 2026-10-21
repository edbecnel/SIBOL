# SIBOL-DEMO-001 — Execution report (physical Android demo setup)

> **Handover UUIDs:** `d7e42a91-5c83-4b60-a19f-6e2c8d347b05` (device setup); `7c1f29a4-6b83-4d90-a25e-0f43b718c962` (Teen inspection plan); `e47c2a91-6b83-4d05-9f12-7a38c6e20b54` (Teen walkthrough execution)  
> **Date:** 2026-10-21  
> **Git commit/push:** **Not authorized**  
> **Firebase deploy / Auth config:** **Not authorized**  
> **Teen My Case / My Requests implementation:** **Not authorized**  
> **PA acceptance:** Pending

## 1. PA authorization

Local device setup, demonstration verification, Teen inspection, and requirements capture. No implementation, commit, or Firebase changes under approved handovers.

## 2. Device and connection

| Field | Value |
|-------|--------|
| Model | Realme Note 50 (RMX3834) |
| Android | 13 (API 33) |
| Flutter device ID | `0N14604I2210DB8F` |
| USB data cable | Yes |
| Developer options | Enabled (Build number, Version screen) |
| USB debugging | On |
| ADB authorization | `device` (authorized) |

## 3. Installation

| Field | Value |
|-------|--------|
| Method | Mac → `flutter build apk --debug` + `adb install -r` |
| Working directory | `sibol_app/` |
| Artifact | `build/app/outputs/flutter-apk/app-debug.apk` |
| Gradle | `assembleDebug` ~9.4s (incremental context) |
| Install result | **Success** (Streamed Install) |
| Build type | **Debug** — demo-capable; not a production release build |

Note: `flutter install` without prior release build failed (no `app-release.apk`); debug path used intentionally.

## 4. Firebase Authentication verification

| Check | Result |
|-------|--------|
| Sign-in — Barangay (`barangay.demo@sibol.local`) | **Pass** (physical device, 2026-10-21) |
| Sign-in — Teen (`teen.demo@sibol.local`) | **Pass** (physical device, 2026-10-21; walkthrough re-confirmed) |
| Sign-in — MOPH | Pending |
| Role navigation — Barangay dashboard | **Pass** (case list visible) |
| Sign-out / re-sign-in | Partial (Teen/Barangay sign-out used during rehearsal) |
| Auth persistence across restart | Pending |

## 5. Demonstration rehearsal

| Role / capability | Result |
|-------------------|--------|
| Barangay — list cases (incl. `SIBOL QA Test`) | **Pass** |
| Barangay — case detail (`SIBOL QA Test`) | **Pass** |
| Barangay — follow-up timeline UI | **Pass** (empty state: no follow-ups) |
| Barangay — create / edit | **Deferred** (PO chose Teen focus) |
| Teen — dashboard UI | **Pass** |
| Teen — no Barangay case list | **Pass** |
| Teen — resource cards (tap) | **Pass** — no navigation (static placeholders) |
| Teen — Settings / role label | Pending (optional step) |
| MOPH boundaries | Pending |
| Launcher icon on device | Pending PO visual check |

## 6. Teen implementation inspection (repository baseline)

Accepted by PA handover `7c1f29a4-…`.

| Topic | Finding |
|-------|---------|
| Post-login screen | `Teenager dashboard` at `/teen` only |
| Case/request UI | **Not implemented** — no My Case, no My Requests routes |
| Data access | No Firestore `cases/*` read for teen ([`firestore.rules`](../../firestore.rules), [ADR-0003](../Architecture/ADRs/ADR-0003-Authorization-and-Server-Reporting.md)) |
| Demo teen user | `teen.demo@sibol.local` — not linked to any `demo-case-*` in `users/{uid}` schema |
| Assistance card | Copy-only placeholder; Tranche 1 does not persist teen requests |

## 7. Teen physical walkthrough observations (2026-10-21)

| Step | Observation |
|------|-------------|
| Teen sign-in | **Pass** |
| Dashboard title | **Teenager dashboard** |
| Greeting | **Hello, Demo Teen User** |
| Case names visible | **No** (correct) |
| Intro copy | States dashboard does **not** create official patient records — **confirmed** |
| Three cards | Maternal health information; Support resources; Request for assistance (demo) — **confirmed** |
| Card taps | **No screen change** — matches implementation (not a defect) |

Operator feedback: tap test felt low-value because **desired functionality (Option C) is not built yet** — noted for PA prioritization discussion.

## 8. Product Owner requirements and decisions

### 8.1 Proposed direction (NOT implementation authorization)

Per PA §2 — **Option C (Both):** eventual Teen **My Case** (linked, field-limited disclosure) **and** **My Requests** (assistance requests the teen submitted), plus approved resources.

Architectural constraint: must **not** expose full Barangay `cases` documents to Teen; future limited-disclosure projection or server-authorized fields required.

### 8.2 Confirmed Product Owner decisions

| # | Question | Status |
|---|----------|--------|
| 1 | Is resource-only Teen dashboard acceptable as **temporary** prototype? | **Pending PO confirmation** |
| 2 | Are **both** My Case and My Requests required in eventual Teen experience? | **Proposed Option C** — **pending explicit PO confirmation** |
| 3 | Which case fields may be disclosed to the associated Teen? | **Unresolved** |
| 4 | Prioritize Teen-facing work before remaining Barangay/MOPH phases? | **Unresolved** |

### 8.3 Outstanding requirements (for future authorized work)

- Secure teen↔case linkage (not in current `users` profile).
- Teen-visible field allow-list (reference, status, next appointment, safe progress copy, contacts — PO to confirm).
- Assistance-request collection, rules, and UI (see T2-R07 class in [SIBOL_IMP_002_PLAN.md](SIBOL_IMP_002_PLAN.md)).
- Demo data: optional link `teen.demo@sibol.local` to a fictional seeded case (e.g. `demo-case-002`) — provisioning decision only.

## 9. Fictional Barangay demonstration data (not Teen-visible)

| Case ID | Summary (seed / known) |
|---------|-------------------------|
| `demo-case-001` | Ana Demo Reyes (seed) |
| `demo-case-002` | Bea Demo Santos, age 16, `followUpScheduled` |
| `demo-case-003` | Cara Demo Lim (seed) |
| `demo-case-004` | Dina Demo Cruz (seed) |
| `demo-case-005` | Ella Demo Neri (seed) |
| (dynamic) | **SIBOL QA Test** — T2-3 Android QA; Barangay-only |

## 10. Failures and resolutions

| Issue | Resolution |
|-------|------------|
| Physical device not listed initially | Developer options + USB debugging enabled |
| `flutter install` missing release APK | Built and installed debug APK via `adb` |

## 11. Limitations

- Debug build installed (see §3).
- Case detail footer still says “Read-only view…” while **Edit** (pencil) is available — known UI copy mismatch.
- Demonstration requires network reachability to Firebase (`sibol-286d0`).
- **My Case / My Requests not delivered** — must not be described as operational in demos.
- No passwords or tokens recorded in this document.

## 12. Recommended implementation priorities (EA recommendation only — not PO/PA approval)

1. **PA-authorized work item** for Teen Option C: data model + rules + UI (after PO confirms §8.2).
2. Complete **MOPH** and remaining **Barangay** demo rehearsal on physical device (SIBOL-DEMO-001 open items).
3. UI copy fix: case detail “read-only” footer vs Barangay edit (separate small fix when authorized).

## 13. Emergency demo package (Product Owner — next-day presentation)

**Context (2026-10-21):** PO time-constrained; full Teen Option C **not** buildable without new PA implementation handover. **Deliverable for tomorrow:** credible **privacy + Barangay case management** story on the **installed debug app** (no Mac required during demo).

### 13.1 Pre-flight (5 minutes before audience)

| Check | Action |
|-------|--------|
| Phone charged; Wi‑Fi or mobile data on | Open browser briefly to confirm internet |
| SIBOL installed | Launch from home screen (official icon if SIBOL-UI-001 assets present) |
| Credentials | Password manager ready — **three** demo emails; **do not** display passwords on screen |
| Narrative | All data **fictional**; read yellow banner aloud if asked |

### 13.2 Recommended flow (~8–10 minutes total)

| Order | Role | On phone | What to say (short) |
|-------|------|----------|---------------------|
| 1 | **Barangay** | Sign in `barangay.demo@sibol.local` | “Barangay staff manage **confidential fictional cases** in Firebase with role-based security.” |
| 2 | Barangay | Scroll case list → open **SIBOL QA Test** | “Case detail, status, notes — created during Android QA.” |
| 3 | Barangay | Scroll to **Follow-ups** section | “Timeline is ready; this case has none yet — empty state is normal.” |
| 4 | Barangay | Tap **pencil** → change **Notes** to a clearly fictional line (e.g. “Demo rehearsal 22 Oct — fictional only”) → **Save** | “Edits persist to the cloud.” Re-open case to prove persistence. |
| 5 | Barangay | **Optional 60s:** **New case** → fictional name only (e.g. “Maya Demo Flores”, age 16) → **Create** | Skip if low on time. |
| 6 | Barangay | **Settings** → **Sign out** | “Switching role — same app, different permissions.” |
| 7 | **Teen** | Sign in `teen.demo@sibol.local` | “Adolescents get a **separate** experience. They **do not** see the Barangay case list — by design (Firestore denies `cases` for Teen).” |
| 8 | Teen | Scroll cards; mention taps are placeholders | “Resources and **future** My Case / My Requests are on the roadmap; not in this build.” **Do not** promise assistance submission or emergency dispatch. |
| 9 | Teen | **Sign out** | |
| 10 | **MOPH** | Sign in `moph.demo@sibol.local` | “MOPH view is for **accepted submitted reports** only — placeholder until full reporting workflow.” |
| 11 | MOPH | Read on-screen placeholder text → **Sign out** | “Barangay case drafts are not visible to MOPH.” |

### 13.3 What tomorrow’s demo **is** vs **is not**

| **Is (show this)** | **Is not (do not claim)** |
|--------------------|---------------------------|
| Barangay list, detail, edit, optional create | Teen sees other adolescents’ cases |
| Firebase Auth + role routing on a **physical phone** | Production release / Play Store |
| Privacy split Teen vs Barangay | My Case / My Requests working today |
| Fictional demo data only | Real patient data |
| Debug build usable without USB | Full MOPH reporting pipeline |

### 13.4 If something fails live

| Symptom | First response |
|---------|----------------|
| Sign-in error | Check internet; retry once; do **not** change Firebase in the room |
| Empty case list (Barangay) | Confirm Barangay account (not Teen); check network |
| “Permission denied” on save | Wrong role or rules — stay on Barangay account |

### 13.5 PO decision deferred

Resource-only Teen acceptable for tomorrow? **Use §13.2 narrative** unless PO explicitly rejects — full §8.2 capture can follow async.

## 14. PA acceptance

Pending PO confirmation of tomorrow demo adequacy and Architect review.
