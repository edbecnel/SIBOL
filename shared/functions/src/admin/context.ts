import { Firestore } from "firebase-admin/firestore";
import {
  AccountDoc,
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertAuthenticated,
  assertCapability,
  AuthzError,
  MembershipDoc,
  OrganizationDoc,
} from "../authz/assert";
import { CAPABILITIES } from "../authz/capabilities";
import { membershipIdFor } from "../authz/identifiers";
import { isOrgAdministrator } from "./policy";

export async function loadAccount(
  db: Firestore,
  uid: string,
): Promise<AccountDoc & { uid: string }> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new AuthzError("Account not found.", "permission-denied");
  }
  return { uid, ...(snap.data() as AccountDoc) };
}

export async function loadOrganization(
  db: Firestore,
  orgId: string,
): Promise<OrganizationDoc & { orgId: string; type?: string; name?: string }> {
  const snap = await db.collection("organizations").doc(orgId).get();
  if (!snap.exists) {
    throw new AuthzError("Organization not found.", "not-found");
  }
  const data = snap.data() as OrganizationDoc & {
    orgId?: string;
    type?: string;
    name?: string;
  };
  return { orgId, ...data };
}

export async function loadMembership(
  db: Firestore,
  membershipId: string,
): Promise<MembershipDoc & { membershipId: string }> {
  const snap = await db.collection("organizationMemberships").doc(membershipId).get();
  if (!snap.exists) {
    throw new AuthzError("Membership not found.", "not-found");
  }
  return { membershipId, ...(snap.data() as MembershipDoc) };
}

export async function loadMembershipForOrgAccount(
  db: Firestore,
  orgId: string,
  accountUid: string,
): Promise<MembershipDoc & { membershipId: string }> {
  const membershipId = membershipIdFor(orgId, accountUid);
  return loadMembership(db, membershipId);
}

export async function listMembershipsForOrg(
  db: Firestore,
  orgId: string,
): Promise<Array<MembershipDoc & { membershipId: string }>> {
  const snap = await db
    .collection("organizationMemberships")
    .where("orgId", "==", orgId)
    .get();
  return snap.docs.map((d) => ({
    membershipId: d.id,
    ...(d.data() as MembershipDoc),
  }));
}

export function assertCentralAdministrator(account: AccountDoc): void {
  if (account.isCentralAdmin !== true) {
    throw new AuthzError("Central Administrator required.", "permission-denied");
  }
}

export async function assertOrgAdministrator(
  db: Firestore,
  actorUid: string,
  orgId: string,
): Promise<MembershipDoc & { membershipId: string }> {
  let membership: MembershipDoc & { membershipId: string };
  try {
    membership = await loadMembershipForOrgAccount(db, orgId, actorUid);
  } catch (err) {
    if (err instanceof AuthzError && err.code === "not-found") {
      throw new AuthzError(
        "Organization Administrator membership required.",
        "permission-denied",
      );
    }
    throw err;
  }
  assertActiveMembership(membership, orgId, actorUid);
  if (!isOrgAdministrator(membership)) {
    throw new AuthzError(
      "Organization Administrator membership required.",
      "permission-denied",
    );
  }
  return membership;
}

export async function assertCanManageOrg(
  db: Firestore,
  actorUid: string,
  account: AccountDoc,
  orgId: string,
): Promise<{ central: boolean; membership?: MembershipDoc & { membershipId: string } }> {
  assertAuthenticated(actorUid);
  assertActiveAccount(account);
  const org = await loadOrganization(db, orgId);
  assertActiveOrganization(org);
  if (account.isCentralAdmin === true) {
    return { central: true };
  }
  const membership = await assertOrgAdministrator(db, actorUid, orgId);
  assertCapability(membership, CAPABILITIES.ORG_MANAGE_MEMBERS);
  return { central: false, membership };
}
