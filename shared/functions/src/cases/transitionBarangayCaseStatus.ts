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
import { COLLECTIONS } from "../coordination/constants";
import {
  TERMINAL_COORDINATION_STATUSES,
} from "../coordination/coordinationStatus";
import { appendLifecycleEventInTransaction } from "./appendLifecycleEvent";
import {
  CASE_COLLECTION,
  CaseLifecycleStatus,
  CLOSURE_NOTES_MAX,
  CLOSURE_NOTES_MIN,
  LifecycleEventType,
  REOPEN_REASON_MAX,
  REOPEN_REASON_MIN,
  RESOLUTION_SUMMARY_MAX,
  RESOLUTION_SUMMARY_MIN,
} from "./caseLifecycleConstants";

export type TransitionBarangayCaseStatusInput = {
  caseId?: unknown;
  targetStatus?: unknown;
  resolutionSummary?: unknown;
  closureReason?: unknown;
  closureNotes?: unknown;
  reopenReason?: unknown;
};

export type TransitionBarangayCaseStatusResult = {
  caseId: string;
  caseStatus: string;
};

function validateCaseId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "caseId is required.");
  }
  return raw.trim();
}

function validateBoundedString(
  raw: unknown,
  field: string,
  min: number,
  max: number,
): string {
  if (typeof raw !== "string") {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  const trimmed = raw.trim();
  if (trimmed.length < min || trimmed.length > max) {
    throw new HttpsError(
      "invalid-argument",
      `${field} must be ${min}–${max} characters.`,
    );
  }
  return trimmed;
}

async function loadReferralBlocksClose(
  tx: FirebaseFirestore.Transaction,
  db: Firestore,
  assistanceRequestId: string,
): Promise<void> {
  const registrySnap = await tx.get(
    db.collection(COLLECTIONS.barangayCoordinationRegistry).doc(assistanceRequestId),
  );
  if (!registrySnap.exists) {
    return;
  }
  const threadId = registrySnap.data()?.threadId;
  if (typeof threadId !== "string" || !threadId) {
    return;
  }
  const threadSnap = await tx.get(
    db.collection(COLLECTIONS.caseCoordinationThreads).doc(threadId),
  );
  if (!threadSnap.exists) {
    return;
  }
  const status = threadSnap.data()?.coordinationStatus;
  if (
    typeof status === "string" &&
    !TERMINAL_COORDINATION_STATUSES.has(status)
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Case cannot be closed while a linked hospital referral is still in progress.",
    );
  }
}

export async function runTransitionBarangayCaseStatus(
  db: Firestore,
  authUid: string | undefined,
  data: TransitionBarangayCaseStatusInput,
): Promise<TransitionBarangayCaseStatusResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const caseId = validateCaseId(data.caseId);
  const targetStatus = validateCaseId(data.targetStatus);
  if (
    !Object.values(CaseLifecycleStatus).includes(
      targetStatus as (typeof CaseLifecycleStatus)[keyof typeof CaseLifecycleStatus],
    )
  ) {
    throw new HttpsError("invalid-argument", "Invalid targetStatus.");
  }

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const caseRef = db.collection(CASE_COLLECTION).doc(caseId);

  return db.runTransaction(async (tx) => {
    const [userSnap, caseSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(caseRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may update case lifecycle.",
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

    if (!caseSnap.exists) {
      throw new HttpsError("not-found", "Case not found.");
    }
    const caseDoc = caseSnap.data()!;
    const orgId = caseDoc.orgId;
    if (typeof orgId !== "string" || !isValidOrgId(orgId)) {
      throw new HttpsError("failed-precondition", "Case is missing organization scope.");
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

    if (
      typeof caseDoc.assistanceRequestId !== "string" ||
      !caseDoc.assistanceRequestId
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Lifecycle transitions apply only to assistance-linked cases.",
      );
    }

    const currentStatus = caseDoc.caseStatus as string;
    const now = new Date();

    const updates: Record<string, unknown> = {
      caseStatus: targetStatus,
      updatedAt: now,
    };

    let eventType: string = LifecycleEventType.statusChanged;
    let reasonOrOutcome: string | undefined;

    if (
      targetStatus === CaseLifecycleStatus.inProgress &&
      currentStatus === CaseLifecycleStatus.open
    ) {
      // allowed
    } else if (
      targetStatus === CaseLifecycleStatus.resolved &&
      currentStatus === CaseLifecycleStatus.inProgress
    ) {
      const resolutionSummary = validateBoundedString(
        data.resolutionSummary,
        "resolutionSummary",
        RESOLUTION_SUMMARY_MIN,
        RESOLUTION_SUMMARY_MAX,
      );
      updates.resolutionSummary = resolutionSummary;
      updates.resolvedAt = now;
      updates.resolvedByUid = authUid;
      eventType = LifecycleEventType.resolved;
      reasonOrOutcome = resolutionSummary;
    } else if (
      targetStatus === CaseLifecycleStatus.closed &&
      currentStatus === CaseLifecycleStatus.resolved
    ) {
      await loadReferralBlocksClose(tx, db, caseDoc.assistanceRequestId);
      const closureReason = validateBoundedString(
        data.closureReason,
        "closureReason",
        CLOSURE_NOTES_MIN,
        CLOSURE_NOTES_MAX,
      );
      const closureNotes = validateBoundedString(
        data.closureNotes,
        "closureNotes",
        CLOSURE_NOTES_MIN,
        CLOSURE_NOTES_MAX,
      );
      updates.closureReason = closureReason;
      updates.closureNotes = closureNotes;
      updates.closedAt = now;
      updates.closedByUid = authUid;
      eventType = LifecycleEventType.closed;
      reasonOrOutcome = `${closureReason}: ${closureNotes}`;
    } else if (
      targetStatus === CaseLifecycleStatus.inProgress &&
      (currentStatus === CaseLifecycleStatus.resolved ||
        currentStatus === CaseLifecycleStatus.closed)
    ) {
      const reopenReason = validateBoundedString(
        data.reopenReason,
        "reopenReason",
        REOPEN_REASON_MIN,
        REOPEN_REASON_MAX,
      );
      updates.reopenReason = reopenReason;
      eventType = LifecycleEventType.reopened;
      reasonOrOutcome = reopenReason;
    } else {
      throw new HttpsError(
        "failed-precondition",
        `Cannot transition case from ${currentStatus} to ${targetStatus}.`,
      );
    }

    tx.update(caseRef, updates);

    appendLifecycleEventInTransaction(tx, db, caseId, {
      eventType,
      actorUid: authUid,
      createdAt: now,
      previousStatus: currentStatus,
      newStatus: targetStatus,
      reasonOrOutcome,
    });

    return { caseId, caseStatus: targetStatus };
  });
}
