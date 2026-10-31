# CONTRACT-DISCLOSURE-001 — MOPH disclosure authorization

**Work item:** SIBOL-CONSENT-REFERRAL-001  
**ADR:** [ADR-0006](../../Docs/Architecture/ADRs/ADR-0006-Disclosure-Authorization.md)

## Callables

| Callable | Role |
|----------|------|
| `regRequestMophDisclosureAuthorization` | Barangay — create `requested` authorization |
| `regRecordTeenDisclosureDecision` | Teen — `approved` or `declined` |
| `regWithdrawDisclosureAuthorization` | Teen — withdraw `approved` authorization |

## Collection: `disclosureAuthorizations/{authorizationId}`

Server write only. Key fields: `assistanceRequestId`, `teenUid`, `orgId`, `targetHospitalOrgId`, `purposeCode`, `requestedCategories[]`, `authorizedCategories[]`, `noticeVersion`, `categoryCatalogVersion`, `status`, `decisionAuthority`, timestamps, optional `referralThreadId`, `otherEssentialJustification`.

## Referral extension: `createCoordinationReferral`

**Required (new clients):**

```json
{
  "assistanceRequestId": "string",
  "disclosureMode": "minimum | authorized",
  "referralPurposeCode": "hospital_coordination | follow_up_support | care_navigation",
  "coordinationNeedCodes": ["schedule_coordination", "..."],
  "authorizationId": "required when disclosureMode is authorized"
}
```

**Rejected:** `barangayReferralSummary`, `administrativeNote`, and other legacy narrative fields.

**Minimum mode:** no free-text note fields (C2). MOPH-visible `barangayReferralSummary` on thread header is **server-generated** from templates.

## Information response: `regBarangayRespondToMophInformationRequest`

```json
{
  "threadId": "string",
  "responseTemplateCode": "administrative_update | scheduling_confirmation | category_disclosure",
  "disclosedCategoryCodes": [],
  "authorizationId": "required when disclosedCategoryCodes non-empty"
}
```

**Rejected:** `responseSummary`.

## Legal gate

Identifying disclosure requires `SIBOL_DISCLOSURE_LEGAL_GATE=true` on Functions runtime (emulator tests set this explicitly).

## Audit

Operations: `disclosure_authorization_requested`, `disclosure_authorization_decision`, `disclosure_authorization_withdrawn`, `coordination_referral_created`, `coordination_information_response` — payloads use category codes and ids, not field values.
