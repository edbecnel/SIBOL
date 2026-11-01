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
import {
  readTeenCommIdempotencyInTransaction,
  writeTeenMessageInTransaction,
} from "./appendTeenMessage";
import {
  BARANGAY_SELECTABLE_FOLLOW_UP_TEMPLATES,
  BARANGAY_SELECTABLE_PROGRESS_TEMPLATES,
  parseTeenCommTemplateCode,
  type TeenCommTemplateCodeValue,
} from "./constants";

export type PublishTeenAssistanceCommunicationInput = {
  assistanceRequestId?: unknown;
  templateCode?: unknown;
  idempotencyKey?: unknown;
  communicationKind?: unknown;
};

export type PublishTeenAssistanceCommunicationResult = {
  messageId: string;
  idempotent: boolean;
};

function validateId(raw: unknown, field: string): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return raw.trim();
}

function allowedBarangayTemplate(
  code: TeenCommTemplateCodeValue,
  kind: string,
): void {
  if (kind === "follow_up") {
    if (!BARANGAY_SELECTABLE_FOLLOW_UP_TEMPLATES.includes(code)) {
      throw new HttpsError(
        "invalid-argument",
        "templateCode is not allowed for follow-up communication.",
      );
    }
    return;
  }
  if (!BARANGAY_SELECTABLE_PROGRESS_TEMPLATES.includes(code)) {
    throw new HttpsError(
      "invalid-argument",
      "templateCode is not allowed for progress communication.",
    );
  }
}

export async function runPublishTeenAssistanceCommunication(
  db: Firestore,
  authUid: string | undefined,
  data: PublishTeenAssistanceCommunicationInput,
): Promise<PublishTeenAssistanceCommunicationResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const assistanceRequestId = validateId(
    data.assistanceRequestId,
    "assistanceRequestId",
  );
  const idempotencyKey = validateId(data.idempotencyKey, "idempotencyKey");
  const kind =
    typeof data.communicationKind === "string" &&
    data.communicationKind.trim() === "follow_up"
      ? "follow_up"
      : "progress";

  let templateCode: TeenCommTemplateCodeValue;
  try {
    templateCode = parseTeenCommTemplateCode(data.templateCode);
  } catch {
    throw new HttpsError("invalid-argument", "templateCode is invalid.");
  }
  allowedBarangayTemplate(templateCode, kind);

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
        "Only barangay personnel may publish teenager communications.",
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

    const registrySnap = await tx.get(
      db.collection(COLLECTIONS.barangayCoordinationRegistry).doc(assistanceRequestId),
    );
    const threadId =
      registrySnap.exists && typeof registrySnap.data()?.threadId === "string"
        ? (registrySnap.data()!.threadId as string)
        : undefined;
    const caseId =
      typeof assistance.caseId === "string" && assistance.caseId.length > 0
        ? assistance.caseId
        : undefined;

    return writeTeenMessageInTransaction(tx, db, {
      assistanceRequestId,
      teenUid,
      orgId,
      templateCode,
      idempotencyKey,
      publisherUid: authUid,
      publisherRole: "barangay",
      caseId,
      threadId,
    });
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "teen_assistance_communication_published",
    outcome: "success",
    after: {
      assistanceRequestId,
      messageId: result.messageId,
      templateCode: data.templateCode,
      communicationKind: kind,
    },
  });

  return result;
}
