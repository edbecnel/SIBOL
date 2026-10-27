import { Auth } from "firebase-admin/auth";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertAuthenticated, AuthzError } from "../authz/assert";
import { writeAuditEvent } from "./audit";
import { loadAccount } from "./context";
import {
  denyNonBarangayStaffForTeenRecovery,
  loadTeenForRecovery,
  resolveTeenRecoveryBarangayOrgId,
} from "./teenRecoveryAuthority";

const MIN_PASSWORD_LENGTH = 8;

const GENERIC_DENIED =
  "You are not authorized to reset this teenager's password.";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

function assertPasswordPolicy(password: unknown): void {
  if (typeof password !== "string" || password.length < MIN_PASSWORD_LENGTH) {
    throw new AuthzError(
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
      "invalid-argument",
    );
  }
}

export async function runResetTeenPasswordByBarangayOrgAdmin(
  db: Firestore,
  auth: Auth,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const actorUid = assertAuthenticated(authUid);
  const actorAccount = await loadAccount(db, actorUid);
  denyNonBarangayStaffForTeenRecovery(actorAccount);

  const targetTeenUid = assertNonEmptyString(data.targetTeenUid, "targetTeenUid");
  const newPassword = data.newPassword;
  assertPasswordPolicy(newPassword);

  if (targetTeenUid === actorUid) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }

  const { orgId } = await resolveTeenRecoveryBarangayOrgId(db, actorUid, data);

  const teenBefore = await loadTeenForRecovery(db, targetTeenUid, orgId);

  try {
    await auth.getUser(targetTeenUid);
  } catch {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }

  await auth.updateUser(targetTeenUid, {
    password: newPassword as string,
  });
  await auth.revokeRefreshTokens(targetTeenUid);

  const now = Timestamp.now();
  try {
    await db.collection("users").doc(targetTeenUid).set(
      { mustChangePassword: true, passwordResetAt: now },
      { merge: true },
    );
  } catch (err) {
    throw new AuthzError(
      "Password was updated but account flags could not be saved. Contact support.",
      "failed-precondition",
    );
  }

  const teenAfter = await db.collection("users").doc(targetTeenUid).get();
  const afterData = teenAfter.data();
  if (
    afterData?.selectedBarangayOrgId !== teenBefore.selectedBarangayOrgId ||
    afterData?.role !== "teen"
  ) {
    throw new AuthzError(
      "Password was updated but profile verification failed. Contact support.",
      "failed-precondition",
    );
  }

  await writeAuditEvent(db, {
    actorUid,
    operation: "teen_password_reset_by_org_admin",
    outcome: "success",
    targetOrgId: orgId,
    targetAccountUid: targetTeenUid,
    after: { mustChangePassword: true },
  });

  return { targetTeenUid, managedBarangayOrgId: orgId };
}
