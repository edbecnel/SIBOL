import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { randomBytes } from "node:crypto";
import {
  COLLECTIONS,
  SUMMARY_MAX,
  SUMMARY_MIN,
  TEEN_PROGRESS,
} from "./constants";
import { CAPABILITIES } from "../authz/capabilities";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertCapability,
} from "../authz/assert";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";

export type CreateCoordinationReferralInput = {
  assistanceRequestId?: unknown;
  barangayReferralSummary?: unknown;
};

export type CreateCoordinationReferralResult = {
  threadId: string;
  displayRef: string;
};

function generateDisplayRef(): string {
  const suffix = randomBytes(8).toString("hex").toUpperCase();
  return `SIBOL-REF-${suffix}`;
}

function validateSummary(raw: unknown): string {
  if (typeof raw !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "barangayReferralSummary must be a string.",
    );
  }
  const trimmed = raw.trim();
  if (trimmed.length < SUMMARY_MIN || trimmed.length > SUMMARY_MAX) {
    throw new HttpsError(
      "invalid-argument",
      `barangayReferralSummary must be ${SUMMARY_MIN}–${SUMMARY_MAX} characters.`,
    );
  }
  return trimmed;
}

function validateAssistanceRequestId(raw: unknown): string {
  if (typeof raw !== "string" || raw.trim().length < 1) {
    throw new HttpsError(
      "invalid-argument",
      "assistanceRequestId is required.",
    );
  }
  return raw.trim();
}

export async function runCreateCoordinationReferral(
  db: Firestore,
  authUid: string | undefined,
  data: CreateCoordinationReferralInput,
): Promise<CreateCoordinationReferralResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const assistanceRequestId = validateAssistanceRequestId(data.assistanceRequestId);
  const barangayReferralSummary = validateSummary(data.barangayReferralSummary);

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const assistanceRef = db
    .collection(COLLECTIONS.teenAssistanceRequests)
    .doc(assistanceRequestId);
  const registryRef = db
    .collection(COLLECTIONS.barangayCoordinationRegistry)
    .doc(assistanceRequestId);

  return db.runTransaction(async (tx) => {
    const [userSnap, assistanceSnap, registrySnap] = await Promise.all([
      tx.get(userRef),
      tx.get(assistanceRef),
      tx.get(registryRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may create referrals.",
      );
    }
    try {
      assertActiveAccount(user);
    } catch {
      throw new HttpsError("permission-denied", "Account is not active.");
    }

    if (!assistanceSnap.exists) {
      throw new HttpsError("not-found", "Assistance request not found.");
    }
    const assistance = assistanceSnap.data()!;
    const assistanceOrgId = assistance.orgId;
    if (typeof assistanceOrgId !== "string" || !isValidOrgId(assistanceOrgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing organization scope.",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(assistanceOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(assistanceOrgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), assistanceOrgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this organization.",
      );
    }

    const assignedBarangay =
      typeof assistance.barangay === "string" ? assistance.barangay : "";
    if (assignedBarangay.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing barangay label.",
      );
    }
    if (assistance.status !== "acknowledged") {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request must be acknowledged before referral.",
      );
    }

    if (registrySnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "A coordination referral already exists for this assistance request.",
      );
    }

    const teenUid = assistance.teenUid;
    if (typeof teenUid !== "string" || teenUid.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing teen association.",
      );
    }

    const category = assistance.category;
    if (typeof category !== "string" || category.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request category is invalid.",
      );
    }

    const threadRef = db.collection(COLLECTIONS.caseCoordinationThreads).doc();
    const threadId = threadRef.id;
    const displayRef = generateDisplayRef();
    if (displayRef === authUid) {
      throw new HttpsError("internal", "Could not generate display reference.");
    }

    const now = new Date();
    const eventRef = threadRef.collection("staffEvents").doc();

    tx.set(threadRef, {
      barangay: assignedBarangay,
      orgId: assistanceOrgId,
      displayRef,
      category,
      barangayReferralSummary,
      phase: "referred",
      createdAt: now,
      updatedAt: now,
      lastStaffEventAt: now,
      createdByUid: authUid,
    });

    tx.set(threadRef.collection("private").doc("binding"), {
      teenUid,
      assistanceRequestId,
      createdAt: now,
      createdByUid: authUid,
    });

    tx.set(registryRef, {
      threadId,
      barangay: assignedBarangay,
      orgId: assistanceOrgId,
      teenUid,
      active: true,
      createdAt: now,
    });

    tx.set(eventRef, {
      eventType: "referral_submitted",
      body: "Barangay submitted a hospital coordination referral for MOPH review.",
      actorUid: authUid,
      createdAt: now,
    });

    tx.set(
      db
        .collection(COLLECTIONS.teenCoordinationLinks)
        .doc(teenUid)
        .collection("links")
        .doc(assistanceRequestId),
      {
        threadId,
        progressCode: TEEN_PROGRESS.code,
        progressLabel: TEEN_PROGRESS.label,
        updatedAt: now,
        barangay: assignedBarangay,
      },
    );

    return { threadId, displayRef };
  });
}
