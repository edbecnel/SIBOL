import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { writeAuditEvent } from "../admin/audit";
import { COLLECTIONS } from "../coordination/constants";
import {
  AuthorizationStatus,
  DecisionAuthority,
  DISCLOSURE_COLLECTIONS,
} from "./constants";
import { parseAuthorizationDoc } from "./authorizationLoader";

export type RecordTeenDisclosureDecisionInput = {
  authorizationId?: unknown;
  decision?: unknown;
};

export type RecordTeenDisclosureDecisionResult = {
  authorizationId: string;
  status: string;
};

function validateAuthorizationId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "authorizationId is required.");
  }
  return raw.trim();
}

function validateDecision(raw: unknown): "approved" | "declined" {
  if (raw !== "approved" && raw !== "declined") {
    throw new HttpsError(
      "invalid-argument",
      "decision must be approved or declined.",
    );
  }
  return raw;
}

export async function runRecordTeenDisclosureDecision(
  db: Firestore,
  authUid: string | undefined,
  data: RecordTeenDisclosureDecisionInput,
): Promise<RecordTeenDisclosureDecisionResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const authorizationId = validateAuthorizationId(data.authorizationId);
  const decision = validateDecision(data.decision);

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const authRef = db
    .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
    .doc(authorizationId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, authSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(authRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "teen") {
      throw new HttpsError(
        "permission-denied",
        "Only the teenager may record this authorization decision.",
      );
    }
    if (!user.active) {
      throw new HttpsError("failed-precondition", "Account is not active.");
    }

    if (!authSnap.exists) {
      throw new HttpsError("not-found", "Disclosure authorization not found.");
    }
    const auth = parseAuthorizationDoc(authorizationId, authSnap.data()!);

    if (auth.teenUid !== authUid) {
      throw new HttpsError(
        "permission-denied",
        "This authorization request belongs to another account.",
      );
    }
    if (auth.status !== AuthorizationStatus.requested) {
      throw new HttpsError(
        "failed-precondition",
        "This authorization request is no longer pending.",
      );
    }

    if (decision === "approved") {
      if (auth.decisionAuthority === DecisionAuthority.pendingVerification) {
        throw new HttpsError(
          "failed-precondition",
          "Decision authority verification is pending; approval is not available.",
        );
      }
      if (
        auth.decisionAuthority === DecisionAuthority.guardianVerified ||
        auth.decisionAuthority === DecisionAuthority.otherLegalAuthority
      ) {
        throw new HttpsError(
          "failed-precondition",
          "Guardian or legal-authority approval is not available in this version.",
        );
      }
    }

    const now = new Date();
    const nextStatus =
      decision === "approved"
        ? AuthorizationStatus.approved
        : AuthorizationStatus.declined;

    tx.update(authRef, {
      status: nextStatus,
      decidedAt: now,
      decidedByUid: authUid,
      authorizedCategories:
        decision === "approved" ? auth.requestedCategories : [],
    });

    return { authorizationId, status: nextStatus };
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "disclosure_authorization_decision",
    outcome: "success",
    targetAccountUid: authUid,
    after: {
      authorizationId,
      status: result.status,
    },
  });

  return result;
}
