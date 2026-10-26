import { Firestore } from "firebase-admin/firestore";
import {
  assertAuthenticated,
  AuthzError,
} from "../authz/assert";
import { writeAuditEvent } from "./audit";
import { loadAccount } from "./context";

export async function runAcknowledgeMandatoryPasswordChange(
  db: Firestore,
  authUid: string | undefined,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  if (account.mustChangePassword !== true) {
    throw new AuthzError(
      "No mandatory password change is pending for this account.",
      "failed-precondition",
    );
  }

  await db.collection("users").doc(uid).set(
    { mustChangePassword: false },
    { merge: true },
  );

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "mandatory_password_change_completed",
    outcome: "success",
    targetAccountUid: uid,
  });

  return { acknowledged: true };
}
