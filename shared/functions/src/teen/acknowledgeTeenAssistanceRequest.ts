import {
  DocumentData,
  DocumentSnapshot,
  Firestore,
  Timestamp,
} from "firebase-admin/firestore";
import { CAPABILITIES } from "../authz/capabilities";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertAuthenticated,
  assertCapability,
  AuthzError,
} from "../authz/assert";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";
import { COLLECTIONS } from "../coordination/constants";
import {
  claimUserIdempotency,
  completeUserIdempotencyInTransaction,
  initUserIdempotencyInTransaction,
  requestFingerprint,
  userIdempotencyDocId,
} from "../workflow/idempotency";

const IDEMPOTENCY = "assistanceAcknowledgmentIdempotency";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export type AcknowledgeTeenAssistanceInput = {
  idempotencyKey?: string;
  requestId?: string;
  orgId?: string;
};

export type AcknowledgeTeenAssistanceResult = {
  requestId: string;
  status: "acknowledged";
  orgId: string;
  idempotent: boolean;
};

function assertBarangayAuthorization(
  user: DocumentData,
  orgSnap: DocumentSnapshot,
  membershipSnap: DocumentSnapshot,
  assistanceOrgId: string,
  authUid: string,
): void {
  if (user.role !== "barangay") {
    throw new AuthzError(
      "Only barangay personnel may acknowledge assistance requests.",
      "permission-denied",
    );
  }
  assertActiveAccount(user);
  assertActiveOrganization(orgSnap.data());
  assertActiveMembership(membershipSnap.data(), assistanceOrgId, authUid);
  assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);
}

export async function runAcknowledgeTeenAssistanceRequest(
  db: Firestore,
  authUid: string | undefined,
  data: AcknowledgeTeenAssistanceInput,
): Promise<AcknowledgeTeenAssistanceResult> {
  const uid = assertAuthenticated(authUid);
  const idempotencyKey = assertNonEmptyString(data.idempotencyKey, "idempotencyKey");
  const requestId = assertNonEmptyString(data.requestId, "requestId");
  const orgId = assertNonEmptyString(data.orgId, "orgId");

  if (!isValidOrgId(orgId)) {
    throw new AuthzError("Invalid organization id.", "invalid-argument");
  }

  const fingerprint = requestFingerprint({
    operation: "acknowledge_teen_assistance",
    requestId,
    orgId,
  });

  const idemClaim = await claimUserIdempotency(
    db,
    IDEMPOTENCY,
    uid,
    idempotencyKey,
    "acknowledge_teen_assistance",
    fingerprint,
  );
  if (idemClaim.replay) {
    const replay = idemClaim.response as AcknowledgeTeenAssistanceResult;
    return { ...replay, idempotent: true };
  }

  const idemRef = db.collection(IDEMPOTENCY).doc(userIdempotencyDocId(uid, idempotencyKey));
  const assistanceRef = db.collection(COLLECTIONS.teenAssistanceRequests).doc(requestId);
  const userRef = db.collection(COLLECTIONS.users).doc(uid);
  const now = Timestamp.now();

  return db.runTransaction(async (tx) => {
    const assistanceSnap = await tx.get(assistanceRef);
    if (!assistanceSnap.exists) {
      throw new AuthzError("Assistance request not found.", "not-found");
    }
    const assistance = assistanceSnap.data()!;
    const assistanceOrgId = assistance.orgId;
    if (typeof assistanceOrgId !== "string" || assistanceOrgId !== orgId) {
      throw new AuthzError(
        "Request is not assigned to your organization.",
        "permission-denied",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(assistanceOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(assistanceOrgId, uid));
    const [userSnap, orgSnap, membershipSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);

    if (!userSnap.exists) {
      throw new AuthzError("User profile not found.", "permission-denied");
    }
    try {
      assertBarangayAuthorization(
        userSnap.data()!,
        orgSnap,
        membershipSnap,
        assistanceOrgId,
        uid,
      );
    } catch (err) {
      if (err instanceof AuthzError) {
        throw err;
      }
      throw new AuthzError(
        err instanceof Error ? err.message : "Not authorized.",
        "permission-denied",
      );
    }

    const status = assistance.status;
    if (status === "acknowledged") {
      const ackBy = assistance.acknowledgedByUid;
      const ackKey = assistance.acknowledgmentIdempotencyKey;
      if (ackKey === idempotencyKey) {
        const payload: AcknowledgeTeenAssistanceResult = {
          requestId,
          status: "acknowledged",
          orgId: assistanceOrgId,
          idempotent: true,
        };
        initUserIdempotencyInTransaction(tx, idemRef, {
          idempotencyKey,
          actorUid: uid,
          operation: "acknowledge_teen_assistance",
          status: "in_progress",
          requestFingerprint: fingerprint,
          createdAt: now,
        });
        completeUserIdempotencyInTransaction(tx, idemRef, payload, now);
        return payload;
      }
      if (ackBy === uid) {
        throw new AuthzError(
          "acknowledgment-conflict: duplicate acknowledgment operation.",
          "failed-precondition",
        );
      }
      throw new AuthzError(
        "acknowledgment-conflict: already acknowledged by another user.",
        "failed-precondition",
      );
    }

    if (status !== "submitted") {
      throw new AuthzError(
        "Assistance request cannot be acknowledged in its current state.",
        "failed-precondition",
      );
    }

    initUserIdempotencyInTransaction(tx, idemRef, {
      idempotencyKey,
      actorUid: uid,
      operation: "acknowledge_teen_assistance",
      status: "in_progress",
      requestFingerprint: fingerprint,
      createdAt: now,
    });

    tx.update(assistanceRef, {
      status: "acknowledged",
      acknowledgedAt: now,
      acknowledgedByUid: uid,
      acknowledgmentIdempotencyKey: idempotencyKey,
    });

    const payload: AcknowledgeTeenAssistanceResult = {
      requestId,
      status: "acknowledged",
      orgId: assistanceOrgId,
      idempotent: false,
    };
    completeUserIdempotencyInTransaction(tx, idemRef, payload, now);
    return payload;
  });
}
