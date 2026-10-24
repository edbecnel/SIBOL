import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import { generateAuditEventId } from "./ids";

export type AuditOutcome = "success" | "denied";

export type AuditWriteInput = {
  actorUid: string;
  operation: string;
  outcome: AuditOutcome;
  targetOrgId?: string;
  targetMembershipId?: string;
  targetInvitationId?: string;
  targetAccountUid?: string;
  correlationId?: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
};

export async function writeAuditEvent(
  db: Firestore,
  input: AuditWriteInput,
): Promise<string> {
  const eventId = generateAuditEventId();
  const ref = db.collection("auditEvents").doc(eventId);
  await ref.create({
    eventId,
    actorUid: input.actorUid,
    operation: input.operation,
    outcome: input.outcome,
    targetOrgId: input.targetOrgId ?? null,
    targetMembershipId: input.targetMembershipId ?? null,
    targetInvitationId: input.targetInvitationId ?? null,
    targetAccountUid: input.targetAccountUid ?? null,
    correlationId: input.correlationId ?? null,
    before: input.before ?? null,
    after: input.after ?? null,
    createdAt: FieldValue.serverTimestamp(),
  });
  return eventId;
}

export function capabilitySnapshot(capabilities: readonly string[] | undefined) {
  return { capabilities: [...(capabilities ?? [])].sort() };
}

export function membershipAuditSlice(membership: {
  status?: string;
  capabilities?: string[];
}) {
  return {
    status: membership.status ?? null,
    capabilities: [...(membership.capabilities ?? [])].sort(),
  };
}

export { Timestamp };
