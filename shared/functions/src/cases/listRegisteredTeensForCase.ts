import { Firestore } from "firebase-admin/firestore";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertAuthenticated,
  assertCapability,
  AuthzError,
} from "../authz/assert";
import { CAPABILITIES } from "../authz/capabilities";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";
import { COLLECTIONS } from "../coordination/constants";

export type ListRegisteredTeensForCaseInput = {
  orgId?: string;
};

export type RegisteredTeenListEntry = {
  teenUid: string;
  displayName: string;
};

export async function runListRegisteredTeensForCase(
  db: Firestore,
  authUid: string | undefined,
  data: ListRegisteredTeensForCaseInput,
): Promise<{ teens: RegisteredTeenListEntry[] }> {
  const uid = assertAuthenticated(authUid);
  const orgId = data.orgId;
  if (typeof orgId !== "string" || !isValidOrgId(orgId)) {
    throw new AuthzError("orgId is required.", "invalid-argument");
  }

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
      "Only barangay personnel may list registered teens for cases.",
      "permission-denied",
    );
  }
  assertActiveAccount(staffUser);
  assertActiveOrganization(orgSnap.data());
  assertActiveMembership(membershipSnap.data(), orgId, uid);
  assertCapability(membershipSnap.data()!, CAPABILITIES.CASE_WRITE);

  const snap = await db
    .collection(COLLECTIONS.users)
    .where("role", "==", "teen")
    .where("selectedBarangayOrgId", "==", orgId)
    .where("active", "==", true)
    .limit(100)
    .get();

  const teens = snap.docs.map((doc) => {
    const row = doc.data();
    return {
      teenUid: doc.id,
      displayName:
        typeof row.displayName === "string" && row.displayName.trim()
          ? row.displayName.trim()
          : "Teen",
    };
  });

  teens.sort((a, b) => a.displayName.localeCompare(b.displayName));
  return { teens };
}
