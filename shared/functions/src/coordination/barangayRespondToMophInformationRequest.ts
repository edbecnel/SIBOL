import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
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
import { COLLECTIONS } from "./constants";
import {
  CoordinationStatus,
  MOPH_RESPONSE_MAX,
  MOPH_RESPONSE_MIN,
  phaseForCoordinationStatus,
} from "./coordinationStatus";

export type BarangayRespondToMophInformationRequestInput = {
  threadId?: unknown;
  responseSummary?: unknown;
};

export type BarangayRespondToMophInformationRequestResult = {
  threadId: string;
  coordinationStatus: string;
};

function validateThreadId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "threadId is required.");
  }
  return raw.trim();
}

function validateResponseSummary(raw: unknown): string {
  if (typeof raw !== "string") {
    throw new HttpsError("invalid-argument", "responseSummary is required.");
  }
  const trimmed = raw.trim();
  if (trimmed.length < MOPH_RESPONSE_MIN || trimmed.length > MOPH_RESPONSE_MAX) {
    throw new HttpsError(
      "invalid-argument",
      `responseSummary must be ${MOPH_RESPONSE_MIN}–${MOPH_RESPONSE_MAX} characters.`,
    );
  }
  return trimmed;
}

export async function runBarangayRespondToMophInformationRequest(
  db: Firestore,
  authUid: string | undefined,
  data: BarangayRespondToMophInformationRequestInput,
): Promise<BarangayRespondToMophInformationRequestResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const threadId = validateThreadId(data.threadId);
  const responseSummary = validateResponseSummary(data.responseSummary);

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const threadRef = db.collection(COLLECTIONS.caseCoordinationThreads).doc(threadId);

  return db.runTransaction(async (tx) => {
    const [userSnap, threadSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(threadRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may respond to hospital information requests.",
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

    if (!threadSnap.exists) {
      throw new HttpsError("not-found", "Coordination thread not found.");
    }
    const thread = threadSnap.data()!;
    const barangayOrgId = thread.orgId;
    if (typeof barangayOrgId !== "string" || !isValidOrgId(barangayOrgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Coordination thread is missing organization scope.",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(barangayOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(barangayOrgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), barangayOrgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this organization.",
      );
    }

    const currentStatus = thread.coordinationStatus;
    if (currentStatus !== CoordinationStatus.additionalInformationRequested) {
      throw new HttpsError(
        "failed-precondition",
        "Hospital has not requested additional information for this referral.",
      );
    }

    const now = new Date();
    const nextStatus = CoordinationStatus.informationProvided;
    const phase = phaseForCoordinationStatus(nextStatus);
    const eventRef = threadRef.collection("staffEvents").doc();

    tx.update(threadRef, {
      coordinationStatus: nextStatus,
      phase,
      updatedAt: now,
      lastStaffEventAt: now,
    });

    tx.set(eventRef, {
      eventType: "barangay_information_response",
      body: responseSummary,
      actorUid: authUid,
      createdAt: now,
      previousStatus: currentStatus,
      newStatus: nextStatus,
    });

    return { threadId, coordinationStatus: nextStatus };
  });
}
