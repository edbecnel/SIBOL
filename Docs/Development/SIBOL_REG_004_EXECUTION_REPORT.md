# SIBOL-REG-004 — Teen date-of-birth input correction

**Handover UUID:** `b7e4c291-6a83-4d50-9f12-8c0d75e3a946`  
**Firebase:** `sibol-286d0` (no backend changes)

## Root cause

The Teen Registration date-of-birth field used `TextInputType.datetime`, which on Android opens a numeric-oriented keyboard **without a dash key**, while the label requires `YYYY-MM-DD`. Users could not enter the displayed format without switching keyboards.

## Implementation

| Component | Change |
|-----------|--------|
| `iso_date_digits_input_formatter.dart` | `IsoDateDigitsInputFormatter` — up to 8 digits auto-formatted as `YYYY-MM-DD`; strips non-digits; preserves cursor by digit index |
| `app_text_field.dart` | Optional `inputFormatters` |
| `teen_registration_screen.dart` | `TextInputType.number` + formatter on DOB field |

Submission unchanged: `CaseDateOfBirth.parse(...).toStorageString()` → `YYYY-MM-DD` callable payload.

Validation unchanged: `CaseDateOfBirth.validateForAdolescentCase` (calendar dates, future rejection, ages 13–19).

## Tests

| Suite | Result |
|-------|--------|
| `iso_date_digits_input_formatter_test.dart` | **Pass** — formatting, alpha strip, digit cap, backspace, leap day, Feb 30, future date, storage string |
| `teen_registration_validation_test.dart` | **Pass** |
| `teen_registration_screen_test.dart` | **Pass** |

## APK / device

Release APK built with `ENVIRONMENT=production`, `USE_FIREBASE_EMULATORS=false`; `adb install -r` on Galaxy S9 (data preserved). App launch verified via intent.

**Not performed:** Signed-in registration or live account creation. PO should confirm DOB typing on **Welcome → Teen registration** manually.

## Classification

**PARTIAL** — Code, tests, and APK install complete; interactive DOB field verification on device pending PO manual check.
