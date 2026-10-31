import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { writeAuditEvent } from "../admin/audit";
import { COLLECTIONS } from "../coordination/constants";
import {
  AuthorizationStatus,
  DISCLOSURE_COLLECTIONS,
} from "./constants";
import { parseAuthorizationDoc } from "./authorizationLoader";

export type WithdrawDisclosureAuthorizationInput = {
  authorizationId?: unknown;
};

export type WithdrawDisclosureAuthorizationResult = {
  authorizationId: string;
  status: string;
};

export async function runWithdrawDisclosureAuthorization(
  db: Firestore,
  authUid: string | undefined,
  data: WithdrawDisclosureAuthorizationInput,
): Promise<WithdrawDisclosureAuthorizationResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  if (typeof data.authorizationId !== "string" || !data.authorizationId.trim()) {
    throw new HttpsError("invalid-argument", "authorizationId is required.");
  }
  const authorizationId = data.authorizationId.trim();

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const authRef = db
    .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
    .doc(authorizationId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, authSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(authRef),
    ]);
    if (!userSnap.exists || userSnap.data()?.role !== "teen") {
      throw new HttpsError("permission-denied", "Only the teenager may withdraw.");
    }
    if (!authSnap.exists) {
      throw new HttpsError("not-found", "Disclosure authorization not found.");
    }
    const auth = parseAuthorizationDoc(authorizationId, authSnap.data()!);
    if (auth.teenUid !== authUid) {
      throw new HttpsError("permission-denied", "Not authorized.");
    }
    if (auth.status !== AuthorizationStatus.approved) {
      throw new HttpsError(
        "failed-precondition",
        "Only approved authorizations may be withdrawn.",
      );
    }

    const now = new Date();
    tx.update(authRef, {
      status: AuthorizationStatus.withdrawn,
      withdrawnAt: now,
      withdrawnByUid: authUid,
    });
    return { authorizationId, status: AuthorizationStatus.withdrawn };
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "disclosure_authorization_withdrawn",
    outcome: "success",
    targetAccountUid: authUid,
    after: { authorizationId },
  });

  return result;
}
