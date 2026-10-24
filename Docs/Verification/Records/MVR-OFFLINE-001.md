# MVR-OFFLINE-001 — Essential offline verification

**Work item:** SIBOL-OFFLINE-001 · **Handover:** AGENT-001

| ID | Scenario | Type | Result |
|----|----------|------|--------|
| O-01 | Pending operation JSON round-trip | Auto | **PASS** (`pending_operation_test.dart`) |
| O-02 | Teen assistance idempotent server create | Auto | **PASS** (`assistance_submission.test.mjs`) |
| O-03 | Offline save UX (no false delivery) | Manual | **NR** |
| O-04 | Restart app recover queue | Manual/device | **NR** |
| O-05 | Reconnect sync submit | Manual/device | **NR** |
| O-06 | Sign-out with pending ops | Manual | **NR** |
| O-07 | Conflict referral already exists | Auto (sync logic) | **PASS** (code path; integration NR) |
