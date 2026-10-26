# Teen assistance request submitter identity (SIBOL-P0-ID-001)

## Snapshot fields

`teenAssistanceRequests/{requestId}` may include server-maintained optional fields:

| Field | Source |
|-------|--------|
| `submitterDisplayName` | `users/{teenUid}.displayName` at submit or refresh |
| `submitterAccountEmail` | Firebase Auth email for `teenUid` at submit or refresh |

`teenUid` remains the authoritative association. Clients cannot create assistance documents or modify identity snapshot fields.

## Callable refresh

`regResolveAssistanceRequestSubmitter({ requestId })` — Barangay staff with `coordination.barangay` on the request `orgId` may refresh the snapshot from authoritative sources. Updates only identity fields when values differ.

## Offline limitation

Firestore offline persistence may retain previously read request documents on a device. Revocation of server authorization does not guarantee immediate removal of cached snapshots from disconnected clients.

## MOPH

Teen identity is not added to MOPH coordination referral thread documents by this contract.
