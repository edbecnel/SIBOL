import { Auth } from "firebase-admin/auth";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import {
  assertAuthenticated,
  assertCapability,
  AuthzError,
} from "../authz/assert";
import { CAPABILITIES } from "../authz/capabilities";
import { writeAuditEvent } from "./audit";
import {
  assertCanManageOrg,
  loadAccount,
  loadMembershipForOrgAccount,
} from "./context";
import { isOrgAdministrator } from "./policy";

const MIN_PASSWORD_LENGTH = 8;

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

async function assertTargetEligibleForPasswordReset(
  db: Firestore,
  orgId: string,
  targetUid: string,
  actorIsCentralAdmin: boolean,
): Promise<void> {
  const targetAccount = await loadAccount(db, targetUid);
  if (targetAccount.isCentralAdmin === true) {
    throw new AuthzError(
      "Central administrator accounts cannot be reset through this workflow.",
      "permission-denied",
    );
  }

  const membership = await loadMembershipForOrgAccount(db, orgId, targetUid);
  if (membership.status !== "active") {
    throw new AuthzError(
      "Target membership must be active.",
      "failed-precondition",
    );
  }

  if (!actorIsCentralAdmin) {
    if (isOrgAdministrator(membership)) {
      throw new AuthzError(
        "Organization administrator accounts cannot be reset by another organization administrator.",
        "permission-denied",
      );
    }
    const allMemberships = await db
      .collection("organizationMemberships")
      .where("accountUid", "==", targetUid)
      .get();
    for (const doc of allMemberships.docs) {
      if (isOrgAdministrator(doc.data())) {
        throw new AuthzError(
          "Accounts with organization administration privileges cannot be reset by an organization administrator.",
          "permission-denied",
        );
      }
    }
  }
}

export async function runResetStaffMemberPassword(
  db: Firestore,
  auth: Auth,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const actorUid = assertAuthenticated(authUid);
  const account = await loadAccount(db, actorUid);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  const targetAccountUid = assertNonEmptyString(
    data.targetAccountUid,
    "targetAccountUid",
  );
  const newPassword = data.newPassword;
  assertPasswordPolicy(newPassword);

  const manage = await assertCanManageOrg(db, actorUid, account, orgId);
  if (!manage.central && manage.membership) {
    assertCapability(manage.membership, CAPABILITIES.ORG_MANAGE_ROLES);
  }

  if (targetAccountUid === actorUid) {
    throw new AuthzError(
      "You cannot reset your own password through staff administration.",
      "permission-denied",
    );
  }

  await assertTargetEligibleForPasswordReset(
    db,
    orgId,
    targetAccountUid,
    manage.central,
  );

  await auth.updateUser(targetAccountUid, {
    password: newPassword as string,
  });
  await auth.revokeRefreshTokens(targetAccountUid);

  const now = Timestamp.now();
  await db.collection("users").doc(targetAccountUid).set(
    { mustChangePassword: true, passwordResetAt: now },
    { merge: true },
  );

  await writeAuditEvent(db, {
    actorUid,
    operation: "staff_password_reset_by_admin",
    outcome: "success",
    targetOrgId: orgId,
    targetAccountUid,
    after: { mustChangePassword: true },
  });

  return { targetAccountUid, orgId };
}
