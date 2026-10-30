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
  assertMophTransitionAllowed,
  CoordinationStatus,
  phaseForCoordinationStatus,
} from "./coordinationStatus";

export type UpdateMophCoordinationStatusInput = {
  threadId?: unknown;
  targetStatus?: unknown;
  note?: unknown;
};

export type UpdateMophCoordinationStatusResult = {
  threadId: string;
  coordinationStatus: string;
};

function validateThreadId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "threadId is required.");
  }
  return raw.trim();
}

function validateStatus(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "targetStatus is required.");
  }
  const value = raw.trim();
  if (!Object.values(CoordinationStatus).includes(value as (typeof CoordinationStatus)[keyof typeof CoordinationStatus])) {
    throw new HttpsError("invalid-argument", "Invalid targetStatus.");
  }
  return value;
}

function validateOptionalNote(raw: unknown): string | undefined {
  if (raw == null || raw === "") {
    return undefined;
  }
  if (typeof raw !== "string") {
    throw new HttpsError("invalid-argument", "note must be a string.");
  }
  const trimmed = raw.trim();
  if (trimmed.length > 500) {
    throw new HttpsError("invalid-argument", "note must be at most 500 characters.");
  }
  return trimmed.length > 0 ? trimmed : undefined;
}

function assertMophHospitalAccess(
  user: FirebaseFirestore.DocumentData,
  targetHospitalOrgId: string,
): string {
  if (user.role !== "moph") {
    throw new HttpsError("permission-denied", "Only MOPH personnel may update referrals.");
  }
  const primaryOrgId = user.primaryOrgId;
  if (typeof primaryOrgId !== "string" || !isValidOrgId(primaryOrgId)) {
    throw new HttpsError(
      "failed-precondition",
      "MOPH profile is missing primary hospital organization.",
    );
  }
  if (primaryOrgId !== targetHospitalOrgId) {
    throw new HttpsError(
      "permission-denied",
      "Referral is addressed to a different hospital organization.",
    );
  }
  return primaryOrgId;
}

export async function runUpdateMophCoordinationStatus(
  db: Firestore,
  authUid: string | undefined,
  data: UpdateMophCoordinationStatusInput,
): Promise<UpdateMophCoordinationStatusResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const threadId = validateThreadId(data.threadId);
  const targetStatus = validateStatus(data.targetStatus);
  const note = validateOptionalNote(data.note);

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
    const targetHospitalOrgId = thread.targetHospitalOrgId;
    if (typeof targetHospitalOrgId !== "string" || !isValidOrgId(targetHospitalOrgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Referral is missing hospital destination.",
      );
    }

    const hospitalOrgId = assertMophHospitalAccess(user, targetHospitalOrgId);

    const orgRef = db.collection(COLLECTIONS.organizations).doc(hospitalOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(hospitalOrgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), hospitalOrgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_HOSPITAL);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this hospital.",
      );
    }

    const currentStatus =
      typeof thread.coordinationStatus === "string"
        ? thread.coordinationStatus
        : CoordinationStatus.submitted;

    try {
      assertMophTransitionAllowed(currentStatus, targetStatus);
    } catch (err) {
      throw new HttpsError(
        "failed-precondition",
        err instanceof Error ? err.message : "Invalid status transition.",
      );
    }

    const now = new Date();
    const phase = phaseForCoordinationStatus(targetStatus);
    const eventRef = threadRef.collection("staffEvents").doc();

    tx.update(threadRef, {
      coordinationStatus: targetStatus,
      phase,
      updatedAt: now,
      lastStaffEventAt: now,
    });

    const body =
      note ??
      `Hospital coordination status updated to ${targetStatus}.`;

    tx.set(eventRef, {
      eventType: "coordination_status_changed",
      body,
      actorUid: authUid,
      createdAt: now,
      previousStatus: currentStatus,
      newStatus: targetStatus,
    });

    return { threadId, coordinationStatus: targetStatus };
  });
}
