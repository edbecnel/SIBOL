# MVR-REG-001 — REG-C repository registration & privacy matrix

**Handover UUID:** `c6f18a42-9e73-4b05-a2d8-61f0c9e735ab`  
**Not** legal/privacy compliance sign-off.

| Scenario | Evidence | Executed |
|----------|----------|----------|
| Teen profile create (server) | `teen.registration.test.mjs` | Yes |
| Duplicate idempotent submit | `teen.registration.test.mjs` | Yes |
| Invalid / inactive Barangay | `teen.registration.test.mjs` | Yes |
| Staff account protection | `teen.registration.test.mjs` | Yes |
| Suspended teen denial | `teen.registration.test.mjs` | Yes |
| Unauthenticated denial | `teen.registration.test.mjs` | Yes |
| Consent required | `teen.registration.test.mjs` | Yes |
| Barangay directory (active only) | `teen.registration.test.mjs` | Yes |
| Audit `teen_registered` | `teen.registration.test.mjs` | Yes |
| Client users create denied | `firestore.rules` | Yes (unchanged) |
| Password confirmation validation | `teen_registration_validation_test.dart` | Yes |
| Auth without profile → registration route | `app_redirect_test.dart` | Yes |
| Assistance gate restricted onboarding | `assistance_request_form_screen.dart` | Yes (UI) |
