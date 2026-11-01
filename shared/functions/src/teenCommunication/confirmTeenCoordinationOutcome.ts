import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { writeAuditEvent } from "../admin/audit";
import { CAPABILITIES } from "../authz/capabilities";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertCapability,
  assertPasswordChangeNotRequired,
  AuthzError,
} from "../authz/assert";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";
import { COLLECTIONS } from "../coordination/constants";
import { TERMINAL_COORDINATION_STATUSES } from "../coordination/coordinationStatus";
import {
  readTeenCommIdempotencyInTransaction,
  writeTeenMessageInTransaction,
} from "./appendTeenMessage";
import { TeenCommTemplateCode } from "./constants";

export type ConfirmTeenCoordinationOutcomeInput = {
  assistanceRequestId?: unknown;
  idempotencyKey?: unknown;
  followUpTemplateCode?: unknown;
};

export type ConfirmTeenCoordinationOutcomeResult = {
  messageId: string;
  idempotent: boolean;
};

function validateId(raw: unknown, field: string): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return raw.trim();
}

export async function runConfirmTeenCoordinationOutcome(
  db: Firestore,
  authUid: string | undefined,
  data: ConfirmTeenCoordinationOutcomeInput,
): Promise<ConfirmTeenCoordinationOutcomeResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const assistanceRequestId = validateId(
    data.assistanceRequestId,
    "assistanceRequestId",
  );
  const idempotencyKey = validateId(data.idempotencyKey, "idempotencyKey");

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const assistanceRef = db
    .collection(COLLECTIONS.teenAssistanceRequests)
    .doc(assistanceRequestId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, assistanceSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(assistanceRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may confirm coordination outcomes.",
      );
    }
    try {
      assertActiveAccount(user);
      assertPasswordChangeNotRequired(user);
    } catch (err) {
      throw new HttpsError(
        err instanceof AuthzError && err.code === "failed-precondition"
          ? "failed-precondition"
          : "permission-denied",
        err instanceof Error ? err.message : "Account is not active.",
      );
    }

    if (!assistanceSnap.exists) {
      throw new HttpsError("not-found", "Assistance request not found.");
    }
    const assistance = assistanceSnap.data()!;
    const orgId = assistance.orgId;
    if (typeof orgId !== "string" || !isValidOrgId(orgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing organization scope.",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(orgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(orgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), orgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.CASE_WRITE);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this organization.",
      );
    }

    const registrySnap = await tx.get(
      db.collection(COLLECTIONS.barangayCoordinationRegistry).doc(assistanceRequestId),
    );
    if (!registrySnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "No hospital referral is linked to this assistance request.",
      );
    }
    const threadId = registrySnap.data()?.threadId;
    if (typeof threadId !== "string" || !threadId) {
      throw new HttpsError(
        "failed-precondition",
        "Referral linkage is incomplete.",
      );
    }

    const threadSnap = await tx.get(
      db.collection(COLLECTIONS.caseCoordinationThreads).doc(threadId),
    );
    if (!threadSnap.exists) {
      throw new HttpsError("not-found", "Coordination thread not found.");
    }
    const coordinationStatus = threadSnap.data()?.coordinationStatus;
    if (
      typeof coordinationStatus !== "string" ||
      !TERMINAL_COORDINATION_STATUSES.has(coordinationStatus)
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Hospital coordination must reach a final outcome before teenager publication.",
      );
    }
    if (threadSnap.data()?.teenOutcomeConfirmedAt) {
      throw new HttpsError(
        "failed-precondition",
        "Coordination outcome was already confirmed for teenager publication.",
      );
    }

    const teenUid = assistance.teenUid;
    if (typeof teenUid !== "string" || !teenUid) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing teen association.",
      );
    }

    const replay = await readTeenCommIdempotencyInTransaction(
      tx,
      db,
      orgId,
      idempotencyKey,
    );
    if (replay) {
      return replay;
    }

    const caseId =
      typeof assistance.caseId === "string" && assistance.caseId.length > 0
        ? assistance.caseId
        : undefined;

    const writeResult = writeTeenMessageInTransaction(tx, db, {
      assistanceRequestId,
      teenUid,
      orgId,
      templateCode: TeenCommTemplateCode.coordinationOutcomeNeutral,
      idempotencyKey,
      publisherUid: authUid,
      publisherRole: "barangay",
      caseId,
      threadId,
    });

    const now = new Date();
    tx.update(threadSnap.ref, {
      teenOutcomeConfirmedAt: now,
      teenOutcomeConfirmedByUid: authUid,
      pendingTeenOutcomePublication: false,
    });

    if (
      typeof data.followUpTemplateCode === "string" &&
      data.followUpTemplateCode.trim() === TeenCommTemplateCode.followUpContactBarangay
    ) {
      writeTeenMessageInTransaction(tx, db, {
        assistanceRequestId,
        teenUid,
        orgId,
        templateCode: TeenCommTemplateCode.followUpContactBarangay,
        idempotencyKey: `${idempotencyKey}__follow_up`,
        publisherUid: authUid,
        publisherRole: "barangay",
        caseId,
        threadId,
      });
    }

    return writeResult;
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "teen_coordination_outcome_confirmed",
    outcome: "success",
    after: {
      assistanceRequestId,
      messageId: result.messageId,
    },
  });

  return result;
}
