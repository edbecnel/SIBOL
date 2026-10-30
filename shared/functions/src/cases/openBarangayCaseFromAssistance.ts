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
  claimUserIdempotency,
  completeUserIdempotencyInTransaction,
  initUserIdempotencyInTransaction,
  requestFingerprint,
  userIdempotencyDocId,
} from "../workflow/idempotency";
import { appendLifecycleEventInTransaction } from "./appendLifecycleEvent";
import {
  ASSISTANCE_CASE_BINDINGS,
  CASE_COLLECTION,
  CASE_OPEN_IDEMPOTENCY,
  CaseLifecycleStatus,
  LifecycleEventType,
} from "./caseLifecycleConstants";
import { Timestamp } from "firebase-admin/firestore";

export type OpenBarangayCaseFromAssistanceInput = {
  assistanceRequestId?: unknown;
  idempotencyKey?: unknown;
  assignedCoordinatorUid?: unknown;
};

export type OpenBarangayCaseFromAssistanceResult = {
  caseId: string;
  assistanceRequestId: string;
  idempotent: boolean;
};

function validateId(raw: unknown, field: string): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", `${field} is required.`);
  }
  return raw.trim();
}

function computeAgeFromDob(dateOfBirth: string): number {
  const [y, m, d] = dateOfBirth.split("-").map(Number);
  const today = new Date();
  let age = today.getFullYear() - y;
  const monthDiff = today.getMonth() + 1 - m;
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < d)) {
    age -= 1;
  }
  return age;
}

export async function runOpenBarangayCaseFromAssistance(
  db: Firestore,
  authUid: string | undefined,
  data: OpenBarangayCaseFromAssistanceInput,
): Promise<OpenBarangayCaseFromAssistanceResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const assistanceRequestId = validateId(
    data.assistanceRequestId,
    "assistanceRequestId",
  );
  const idempotencyKey = validateId(data.idempotencyKey, "idempotencyKey");
  const fingerprint = requestFingerprint({
    assistanceRequestId,
    idempotencyKey,
  });

  const idempotencyRef = db
    .collection(CASE_OPEN_IDEMPOTENCY)
    .doc(userIdempotencyDocId(authUid, idempotencyKey));

  const claimed = await claimUserIdempotency(
    db,
    CASE_OPEN_IDEMPOTENCY,
    authUid,
    idempotencyKey,
    "openBarangayCaseFromAssistance",
    fingerprint,
  );
  if (claimed.replay) {
    const response = claimed.response as OpenBarangayCaseFromAssistanceResult;
    return { ...response, idempotent: true };
  }

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const assistanceRef = db
    .collection(COLLECTIONS.teenAssistanceRequests)
    .doc(assistanceRequestId);
  const bindingRef = db
    .collection(ASSISTANCE_CASE_BINDINGS)
    .doc(assistanceRequestId);

  try {
    return await db.runTransaction(async (tx) => {
      const [userSnap, assistanceSnap, bindingSnap] = await Promise.all([
        tx.get(userRef),
        tx.get(assistanceRef),
        tx.get(bindingRef),
      ]);

      if (!userSnap.exists) {
        throw new HttpsError("permission-denied", "User profile not found.");
      }
      const user = userSnap.data()!;
      if (user.role !== "barangay") {
        throw new HttpsError(
          "permission-denied",
          "Only barangay personnel may open cases.",
        );
      }
      try {
        assertActiveAccount(user);
        assertPasswordChangeNotRequired(user);
      } catch (err) {
        if (err instanceof HttpsError) throw err;
        throw new HttpsError(
          err instanceof AuthzError && err.code === "failed-precondition"
            ? "failed-precondition"
            : "permission-denied",
          err instanceof Error ? err.message : "Account is not active.",
        );
      }

      if (bindingSnap.exists) {
        const binding = bindingSnap.data()!;
        const caseId = binding.caseId as string;
        const response: OpenBarangayCaseFromAssistanceResult = {
          caseId,
          assistanceRequestId,
          idempotent: true,
        };
        completeUserIdempotencyInTransaction(
          tx,
          idempotencyRef,
          response,
          Timestamp.fromDate(new Date()),
        );
        return response;
      }

      if (!assistanceSnap.exists) {
        throw new HttpsError("not-found", "Assistance request not found.");
      }
      const assistance = assistanceSnap.data()!;
      if (assistance.status !== "acknowledged") {
        throw new HttpsError(
          "failed-precondition",
          "Assistance request must be acknowledged before opening a case.",
        );
      }
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
        assertCapability(membershipSnap.data()!, CAPABILITIES.CASE_WRITE);
      } catch (err) {
        throw new HttpsError(
          "permission-denied",
          err instanceof Error ? err.message : "Not authorized for this organization.",
        );
      }

      if (typeof assistance.caseId === "string" && assistance.caseId.length > 0) {
        throw new HttpsError(
          "failed-precondition",
          "Assistance request is already linked to a case.",
        );
      }

      const teenUid = assistance.teenUid;
      if (typeof teenUid !== "string" || teenUid.length < 1) {
        throw new HttpsError(
          "failed-precondition",
          "Assistance request is missing teen association.",
        );
      }

      const teenSnap = await tx.get(db.collection(COLLECTIONS.users).doc(teenUid));
      if (!teenSnap.exists) {
        throw new HttpsError("failed-precondition", "Teen profile not found.");
      }
      const teen = teenSnap.data()!;
      const displayName =
        typeof teen.displayName === "string" && teen.displayName.trim().length >= 2
          ? teen.displayName.trim()
          : "Teen assistance case";
      const dateOfBirth =
        typeof teen.dateOfBirth === "string" ? teen.dateOfBirth : "2008-01-01";
      const age = computeAgeFromDob(dateOfBirth);
      const barangay =
        typeof assistance.barangay === "string" ? assistance.barangay : "";

      let assignedCoordinatorUid = authUid;
      if (data.assignedCoordinatorUid != null) {
        if (
          typeof data.assignedCoordinatorUid !== "string" ||
          !data.assignedCoordinatorUid.trim()
        ) {
          throw new HttpsError(
            "invalid-argument",
            "assignedCoordinatorUid must be a non-empty string when provided.",
          );
        }
        assignedCoordinatorUid = data.assignedCoordinatorUid.trim();
      }

      const now = new Date();
      const caseRef = db.collection(CASE_COLLECTION).doc();
      const caseId = caseRef.id;

      const caseDoc: Record<string, unknown> = {
        orgId: assistanceOrgId,
        demoName: displayName,
        fullName: displayName,
        age,
        barangay,
        caseStatus: CaseLifecycleStatus.open,
        registeredAt: now,
        createdAt: now,
        updatedAt: now,
        reportStatus: "notSubmitted",
        subjectKind: "registered",
        caseCompleteness: "active",
        dateOfBirth,
        teenUid,
        assistanceRequestId,
        openedByUid: authUid,
        openedAt: now,
        assignedCoordinatorUid,
        notes: "",
      };
      if (typeof teen.contactEmail === "string" && teen.contactEmail.length >= 5) {
        caseDoc.contactEmail = teen.contactEmail;
      }
      if (typeof teen.contactPhone === "string" && teen.contactPhone.length >= 7) {
        caseDoc.contactPhone = teen.contactPhone;
      }
      if (
        typeof teen.linkedAccountEmail === "string" &&
        teen.linkedAccountEmail.length >= 3
      ) {
        caseDoc.linkedAccountEmail = teen.linkedAccountEmail;
      } else if (typeof teen.contactEmail === "string") {
        caseDoc.linkedAccountEmail = teen.contactEmail;
      }

      tx.set(bindingRef, {
        caseId,
        orgId: assistanceOrgId,
        assistanceRequestId,
        createdAt: now,
        createdByUid: authUid,
      });

      tx.set(caseRef, caseDoc);

      tx.update(assistanceRef, { caseId });

      appendLifecycleEventInTransaction(tx, db, caseId, {
        eventType: LifecycleEventType.caseOpened,
        actorUid: authUid,
        createdAt: now,
        newStatus: CaseLifecycleStatus.open,
        assignedCoordinatorUid,
        reasonOrOutcome: `Case opened from assistance request ${assistanceRequestId}.`,
      });

      appendLifecycleEventInTransaction(tx, db, caseId, {
        eventType: LifecycleEventType.coordinatorAssigned,
        actorUid: authUid,
        createdAt: now,
        assignedCoordinatorUid,
      });

      const response: OpenBarangayCaseFromAssistanceResult = {
        caseId,
        assistanceRequestId,
        idempotent: false,
      };

      initUserIdempotencyInTransaction(tx, idempotencyRef, {
        idempotencyKey,
        actorUid: authUid,
        operation: "openBarangayCaseFromAssistance",
        status: "in_progress",
        requestFingerprint: fingerprint,
        createdAt: Timestamp.fromDate(now),
      });
      completeUserIdempotencyInTransaction(
        tx,
        idempotencyRef,
        response,
        Timestamp.fromDate(now),
      );

      return response;
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    throw new HttpsError(
      "internal",
      err instanceof Error ? err.message : "Could not open case.",
    );
  }
}
