import { Firestore } from "firebase-admin/firestore";
import {
  AccountDoc,
  assertActiveAccount,
  AuthzError,
} from "../authz/assert";
import { isValidOrgId } from "../authz/identifiers";
import {
  assertCanManageOrg,
  loadAccount,
  loadMembershipForOrgAccount,
  loadOrganization,
} from "./context";
import { isOrgAdministrator } from "./policy";

export const TEEN_RECOVERY_LIST_LIMIT = 100;

const GENERIC_DENIED =
  "You are not authorized to perform teen account recovery for this organization.";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export async function listBarangayOrgIdsManagedByOrgAdmin(
  db: Firestore,
  actorUid: string,
): Promise<string[]> {
  const snap = await db
    .collection("organizationMemberships")
    .where("accountUid", "==", actorUid)
    .where("status", "==", "active")
    .get();

  const orgIds: string[] = [];
  for (const doc of snap.docs) {
    const membership = doc.data();
    if (!isOrgAdministrator(membership)) continue;
    const orgId = membership.orgId;
    if (typeof orgId !== "string" || !isValidOrgId(orgId)) continue;
    try {
      const org = await loadOrganization(db, orgId);
      if (org.type === "barangay" && org.status === "active") {
        orgIds.push(orgId);
      }
    } catch {
      // skip invalid org records
    }
  }
  return [...new Set(orgIds)].sort();
}

export async function assertActiveBarangayOrganization(
  db: Firestore,
  orgId: string,
): Promise<{ orgId: string; name?: string }> {
  const org = await loadOrganization(db, orgId);
  if (org.type !== "barangay") {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
  if (org.status !== "active") {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
  return { orgId, name: org.name };
}

/**
 * Resolves the barangay org scope for teen recovery and verifies actor authority.
 */
export async function resolveTeenRecoveryBarangayOrgId(
  db: Firestore,
  actorUid: string,
  data: Record<string, unknown>,
): Promise<{ orgId: string; central: boolean; organizationName?: string }> {
  const account = await loadAccount(db, actorUid);
  assertActiveAccount(account);

  const requestedOrgId =
    typeof data.managedBarangayOrgId === "string"
      ? data.managedBarangayOrgId.trim()
      : "";

  if (account.isCentralAdmin === true) {
    const orgId = assertNonEmptyString(
      requestedOrgId || data.managedBarangayOrgId,
      "managedBarangayOrgId",
    );
    if (!isValidOrgId(orgId)) {
      throw new AuthzError(GENERIC_DENIED, "permission-denied");
    }
    await assertCanManageOrg(db, actorUid, account, orgId);
    const barangay = await assertActiveBarangayOrganization(db, orgId);
    return { orgId, central: true, organizationName: barangay.name };
  }

  const managed = await listBarangayOrgIdsManagedByOrgAdmin(db, actorUid);
  if (managed.length === 0) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }

  let orgId: string;
  if (managed.length === 1) {
    orgId = managed[0]!;
    if (requestedOrgId && requestedOrgId !== orgId) {
      throw new AuthzError(GENERIC_DENIED, "permission-denied");
    }
  } else {
    orgId = assertNonEmptyString(
      requestedOrgId || data.managedBarangayOrgId,
      "managedBarangayOrgId",
    );
    if (!managed.includes(orgId)) {
      throw new AuthzError(GENERIC_DENIED, "permission-denied");
    }
  }

  await assertCanManageOrg(db, actorUid, account, orgId);
  const membership = await loadMembershipForOrgAccount(db, orgId, actorUid);
  if (!isOrgAdministrator(membership)) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }

  const barangay = await assertActiveBarangayOrganization(db, orgId);
  return { orgId, central: false, organizationName: barangay.name };
}

export type TeenProfileForRecovery = {
  uid: string;
  role?: string;
  active?: boolean;
  selectedBarangayOrgId?: string;
  displayName?: string;
  assignedBarangay?: string;
  contactEmail?: string;
  contactPhone?: string;
};

export async function loadTeenForRecovery(
  db: Firestore,
  targetTeenUid: string,
  orgId: string,
): Promise<TeenProfileForRecovery> {
  if (targetTeenUid === orgId) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }

  const snap = await db.collection("users").doc(targetTeenUid).get();
  if (!snap.exists) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
  const teen = snap.data() as TeenProfileForRecovery;
  if (teen.role !== "teen" || teen.active !== true) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
  if (teen.selectedBarangayOrgId !== orgId) {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
  return { ...teen, uid: targetTeenUid };
}

export function denyNonBarangayStaffForTeenRecovery(
  account: AccountDoc & { role?: string },
): void {
  if (account.isCentralAdmin === true) return;
  if (account.role === "moph") {
    throw new AuthzError(GENERIC_DENIED, "permission-denied");
  }
}
