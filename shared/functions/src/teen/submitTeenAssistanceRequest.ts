import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertAuthenticated, AuthzError } from "../authz/assert";
import { isValidOrgId } from "../authz/identifiers";
import {
  claimUserIdempotency,
  completeUserIdempotencyInTransaction,
  initUserIdempotencyInTransaction,
  requestFingerprint,
  userIdempotencyDocId,
} from "../workflow/idempotency";

const ASSISTANCE = "teenAssistanceRequests";
const IDEMPOTENCY = "assistanceSubmissionIdempotency";

const VALID_CATEGORIES = new Set([
  "generalSupport",
  "healthInformation",
  "counselingReferral",
  "barangayServices",
]);

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export type SubmitTeenAssistanceInput = {
  idempotencyKey?: string;
  category?: string;
  description?: string;
};

export async function runSubmitTeenAssistanceRequest(
  db: Firestore,
  authUid: string | undefined,
  data: SubmitTeenAssistanceInput,
) {
  const uid = assertAuthenticated(authUid);
  const idempotencyKey = assertNonEmptyString(data.idempotencyKey, "idempotencyKey");
  const category = assertNonEmptyString(data.category, "category");
  const description = assertNonEmptyString(data.description, "description");

  if (!VALID_CATEGORIES.has(category)) {
    throw new AuthzError("Invalid assistance category.", "invalid-argument");
  }
  if (description.length < 10 || description.length > 500) {
    throw new AuthzError("description must be 10–500 characters.", "invalid-argument");
  }

  const userRef = db.collection("users").doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    throw new AuthzError("Teen profile not found.", "failed-precondition");
  }
  const user = userSnap.data()!;
  if (user.role !== "teen" || user.active === false) {
    throw new AuthzError("Only active teen accounts may submit assistance.", "permission-denied");
  }
  const orgId = user.selectedBarangayOrgId as string | undefined;
  const barangay = user.assignedBarangay as string | undefined;
  if (!orgId || !isValidOrgId(orgId) || !barangay?.trim()) {
    throw new AuthzError("Teen routing profile is incomplete.", "failed-precondition");
  }

  const orgSnap = await db.collection("organizations").doc(orgId).get();
  if (!orgSnap.exists) {
    throw new AuthzError("Barangay organization not found.", "not-found");
  }
  const org = orgSnap.data()!;
  if (org.type !== "barangay" || org.status !== "active") {
    throw new AuthzError("Barangay is not active for assistance.", "failed-precondition");
  }

  const fingerprint = requestFingerprint({
    operation: "submit_teen_assistance",
    category,
    description,
    orgId,
  });

  const idemClaim = await claimUserIdempotency(
    db,
    IDEMPOTENCY,
    uid,
    idempotencyKey,
    "submit_teen_assistance",
    fingerprint,
  );
  if (idemClaim.replay) {
    return idemClaim.response;
  }

  const now = Timestamp.now();
  const requestRef = db.collection(ASSISTANCE).doc();
  const requestId = requestRef.id;
  const idemRef = db.collection(IDEMPOTENCY).doc(userIdempotencyDocId(uid, idempotencyKey));

  const response = await db.runTransaction(async (tx) => {
    initUserIdempotencyInTransaction(tx, idemRef, {
      idempotencyKey,
      actorUid: uid,
      operation: "submit_teen_assistance",
      status: "in_progress",
      requestFingerprint: fingerprint,
      createdAt: now,
    });

    tx.create(requestRef, {
      teenUid: uid,
      barangay,
      orgId,
      category,
      description,
      status: "submitted",
      createdAt: now,
      submissionIdempotencyKey: idempotencyKey,
    });

    const payload = {
      requestId,
      status: "submitted",
      orgId,
      idempotent: false,
    };
    completeUserIdempotencyInTransaction(tx, idemRef, payload, now);
    return payload;
  });

  return response;
}
