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
import {
  GetAccountEmailFn,
  identitySnapshotsEqual,
  resolveSubmitterIdentityFromAuthoritativeSources,
  storedIdentityFromAssistance,
  SubmitterIdentitySnapshot,
} from "./submitterIdentity";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export type ResolveAssistanceRequestSubmitterInput = {
  requestId?: string;
};

export type ResolveAssistanceRequestSubmitterResult = {
  requestId: string;
  submitterDisplayName?: string;
  submitterAccountEmail?: string;
  snapshotUpdated: boolean;
};

async function defaultGetAccountEmail(uid: string): Promise<string | undefined> {
  try {
    const authUser = await getAuth().getUser(uid);
    return authUser.email;
  } catch {
    return undefined;
  }
}

export async function runResolveAssistanceRequestSubmitter(
  db: Firestore,
  authUid: string | undefined,
  data: ResolveAssistanceRequestSubmitterInput,
  deps?: { getAccountEmail?: GetAccountEmailFn },
): Promise<ResolveAssistanceRequestSubmitterResult> {
  const uid = assertAuthenticated(authUid);
  const requestId = assertNonEmptyString(data.requestId, "requestId");
  const getAccountEmail = deps?.getAccountEmail ?? defaultGetAccountEmail;

  const assistanceRef = db.collection(COLLECTIONS.teenAssistanceRequests).doc(requestId);
  const assistanceSnap = await assistanceRef.get();
  if (!assistanceSnap.exists) {
    throw new AuthzError("Assistance request not found.", "not-found");
  }
  const assistance = assistanceSnap.data()!;
  const assistanceOrgId = assistance.orgId;
  if (typeof assistanceOrgId !== "string" || !isValidOrgId(assistanceOrgId)) {
    throw new AuthzError("Assistance request is not routable.", "failed-precondition");
  }

  const teenUid = assistance.teenUid;
  if (typeof teenUid !== "string" || teenUid.length < 1) {
    throw new AuthzError(
      "Assistance request is missing teen association.",
      "failed-precondition",
    );
  }

  const userRef = db.collection(COLLECTIONS.users).doc(uid);
  const orgRef = db.collection(COLLECTIONS.organizations).doc(assistanceOrgId);
  const membershipRef = db
    .collection(COLLECTIONS.organizationMemberships)
    .doc(membershipIdFor(assistanceOrgId, uid));

  const [userSnap, orgSnap, membershipSnap] = await Promise.all([
    userRef.get(),
    orgRef.get(),
    membershipRef.get(),
  ]);

  if (!userSnap.exists) {
    throw new AuthzError("User profile not found.", "permission-denied");
  }
  const user = userSnap.data()!;
  if (user.role !== "barangay") {
    throw new AuthzError(
      "Only barangay personnel may resolve assistance submitter identity.",
      "permission-denied",
    );
  }
  assertActiveAccount(user);
  assertActiveOrganization(orgSnap.data());
  assertActiveMembership(membershipSnap.data(), assistanceOrgId, uid);
  assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);

  const resolved = await resolveSubmitterIdentityFromAuthoritativeSources(
    db,
    teenUid,
    getAccountEmail,
  );

  const stored = storedIdentityFromAssistance(assistance);
  let snapshotUpdated = false;

  if (!identitySnapshotsEqual(stored, resolved)) {
    const updatePayload: SubmitterIdentitySnapshot = {};
    if (resolved.submitterDisplayName !== undefined) {
      updatePayload.submitterDisplayName = resolved.submitterDisplayName;
    }
    if (resolved.submitterAccountEmail !== undefined) {
      updatePayload.submitterAccountEmail = resolved.submitterAccountEmail;
    }
    if (Object.keys(updatePayload).length > 0) {
      await assistanceRef.update(updatePayload);
      snapshotUpdated = true;
    }
  }

  return {
    requestId,
    ...resolved,
    snapshotUpdated,
  };
}
