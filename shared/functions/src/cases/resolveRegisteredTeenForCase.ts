import { Firestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { CAPABILITIES } from "../authz/capabilities";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertAuthenticated,
  assertCapability,
  AuthzError,
} from "../authz/assert";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";
import { COLLECTIONS } from "../coordination/constants";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export type ResolveRegisteredTeenForCaseInput = {
  orgId?: string;
  teenUid?: string;
};

export type ResolveRegisteredTeenForCaseResult = {
  teenUid: string;
  fullName: string;
  dateOfBirth?: string;
  barangay?: string;
  contactEmail?: string;
  contactPhone?: string;
  parentGuardianContact?: string;
  linkedAccountEmail?: string;
  resolvedAt: string;
};

export async function runResolveRegisteredTeenForCase(
  db: Firestore,
  authUid: string | undefined,
  data: ResolveRegisteredTeenForCaseInput,
): Promise<ResolveRegisteredTeenForCaseResult> {
  const uid = assertAuthenticated(authUid);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  if (!isValidOrgId(orgId)) {
    throw new AuthzError("Invalid organization.", "invalid-argument");
  }
  const teenUid = assertNonEmptyString(data.teenUid, "teenUid");

  const staffUserRef = db.collection(COLLECTIONS.users).doc(uid);
  const orgRef = db.collection(COLLECTIONS.organizations).doc(orgId);
  const membershipRef = db
    .collection(COLLECTIONS.organizationMemberships)
    .doc(membershipIdFor(orgId, uid));

  const [staffSnap, orgSnap, membershipSnap] = await Promise.all([
    staffUserRef.get(),
    orgRef.get(),
    membershipRef.get(),
  ]);

  if (!staffSnap.exists) {
    throw new AuthzError("User profile not found.", "permission-denied");
  }
  const staffUser = staffSnap.data()!;
  if (staffUser.role !== "barangay") {
    throw new AuthzError(
      "Only barangay personnel may link registered teens to cases.",
      "permission-denied",
    );
  }
  assertActiveAccount(staffUser);
  assertActiveOrganization(orgSnap.data());
  assertActiveMembership(membershipSnap.data(), orgId, uid);
  assertCapability(membershipSnap.data()!, CAPABILITIES.CASE_WRITE);

  const teenRef = db.collection(COLLECTIONS.users).doc(teenUid);
  const teenSnap = await teenRef.get();
  if (!teenSnap.exists) {
    throw new AuthzError("Teen account not found.", "not-found");
  }
  const teen = teenSnap.data()!;
  if (teen.role !== "teen" || teen.active === false) {
    throw new AuthzError("Selected account is not an active teen user.", "failed-precondition");
  }
  const teenOrgId = teen.selectedBarangayOrgId;
  if (typeof teenOrgId !== "string" || teenOrgId !== orgId) {
    throw new AuthzError(
      "Teen is not associated with this Barangay organization.",
      "permission-denied",
    );
  }

  let linkedAccountEmail: string | undefined;
  try {
    const authUser = await getAuth().getUser(teenUid);
    linkedAccountEmail = authUser.email;
  } catch {
    linkedAccountEmail = undefined;
  }

  const contactEmail =
    typeof teen.contactEmail === "string" && teen.contactEmail.trim()
      ? teen.contactEmail.trim()
      : undefined;
  const contactPhone =
    typeof teen.contactPhone === "string" && teen.contactPhone.trim()
      ? teen.contactPhone.trim()
      : undefined;
  const hasContact =
    (contactEmail && contactEmail.length > 3) ||
    (contactPhone && contactPhone.replace(/\D/g, "").length >= 7) ||
    (linkedAccountEmail && linkedAccountEmail.length > 3);
  if (!hasContact) {
    throw new AuthzError(
      "Teen profile must include at least one contact method before case linkage.",
      "failed-precondition",
    );
  }

  const dateOfBirth =
    typeof teen.dateOfBirth === "string" && teen.dateOfBirth.trim()
      ? teen.dateOfBirth.trim()
      : undefined;

  return {
    teenUid,
    fullName:
      typeof teen.displayName === "string" && teen.displayName.trim()
        ? teen.displayName.trim()
        : "Teen",
    dateOfBirth,
    barangay:
      typeof teen.assignedBarangay === "string" ? teen.assignedBarangay : undefined,
    contactEmail,
    contactPhone,
    parentGuardianContact:
      typeof teen.parentGuardianContact === "string"
        ? teen.parentGuardianContact.trim()
        : undefined,
    linkedAccountEmail,
    resolvedAt: new Date().toISOString(),
  };
}
