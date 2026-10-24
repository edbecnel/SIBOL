# CONTRACT-OFFLINE-001 — Pending operations (draft)

## Client queue record

| Field | Type | Notes |
|-------|------|--------|
| `operationId` | string | Durable idempotency key for server call |
| `ownerUid` | string | Must match signed-in user at sync time |
| `kind` | enum | `teenAssistanceSubmit`, `barangayAcknowledge`, `barangayReferral` |
| `state` | enum | See implementation spec |
| `payload` | map | Kind-specific; no secrets |

## Teen assistance sync

**Callable:** `regSubmitTeenAssistanceRequest`

**Input:** `idempotencyKey` (= `operationId`), `category`, `description`

**Output:** `requestId`, `status`, `orgId`

## UX contract

- Offline save MUST display “not delivered to Barangay/MOPH”.
- Server confirmation REQUIRED before success navigation to server-backed detail (teen assistance).
