import { Firestore, FieldValue } from "firebase-admin/firestore";
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

export type SyncRegisteredTeenCasesFromProfileInput = {
  caseId?: string;
};

export type SyncRegisteredTeenCasesFromProfileResult = {
  updatedCaseIds: string[];
  syncedAt: string;
};

function teenContactFieldsFromProfile(teen: FirebaseFirestore.DocumentData) {
  return {
    fullName:
      typeof teen.displayName === "string" && teen.displayName.trim()
        ? teen.displayName.trim()
        : undefined,
    dateOfBirth:
      typeof teen.dateOfBirth === "string" && teen.dateOfBirth.trim()
        ? teen.dateOfBirth.trim()
        : undefined,
    barangay:
      typeof teen.assignedBarangay === "string" && teen.assignedBarangay.trim()
        ? teen.assignedBarangay.trim()
        : undefined,
    contactEmail:
      typeof teen.contactEmail === "string" && teen.contactEmail.trim()
        ? teen.contactEmail.trim()
        : undefined,
    contactPhone:
      typeof teen.contactPhone === "string" && teen.contactPhone.trim()
        ? teen.contactPhone.trim()
        : undefined,
    parentGuardianContact:
      typeof teen.parentGuardianContact === "string" &&
      teen.parentGuardianContact.trim()
        ? teen.parentGuardianContact.trim()
        : undefined,
  };
}

function buildCaseContactPatch(
  teen: FirebaseFirestore.DocumentData,
): Record<string, unknown> {
  const fields = teenContactFieldsFromProfile(teen);
  const patch: Record<string, unknown> = {
    teenProfileSyncedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (fields.fullName) {
    patch.fullName = fields.fullName;
    patch.demoName = fields.fullName;
  }
  if (fields.dateOfBirth) patch.dateOfBirth = fields.dateOfBirth;
  if (fields.barangay) patch.barangay = fields.barangay;
  if (fields.contactEmail) patch.contactEmail = fields.contactEmail;
  if (fields.contactPhone) patch.contactPhone = fields.contactPhone;
  if (fields.parentGuardianContact) {
    patch.parentGuardianContact = fields.parentGuardianContact;
  }
  return patch;
}

async function syncCasesForTeen(
  db: Firestore,
  teenUid: string,
  teen: FirebaseFirestore.DocumentData,
  caseFilter?: { caseId: string; orgId: string },
): Promise<string[]> {
  const orgId = teen.selectedBarangayOrgId;
  if (typeof orgId !== "string" || !isValidOrgId(orgId)) {
    throw new AuthzError("Teen organization context is missing.", "failed-precondition");
  }

  const patch = buildCaseContactPatch(teen);
  const updated: string[] = [];

  if (caseFilter) {
    if (caseFilter.orgId !== orgId) {
      throw new AuthzError("Case is not in the teen organization.", "permission-denied");
    }
    const ref = db.collection("cases").doc(caseFilter.caseId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new AuthzError("Case not found.", "not-found");
    }
    const data = snap.data()!;
    if (data.subjectKind !== "registered" || data.teenUid !== teenUid) {
      throw new AuthzError("Case is not linked to this teen account.", "failed-precondition");
    }
    await ref.update(patch);
    updated.push(caseFilter.caseId);
    return updated;
  }

  const snap = await db
    .collection("cases")
    .where("teenUid", "==", teenUid)
    .where("orgId", "==", orgId)
    .where("subjectKind", "==", "registered")
    .get();

  for (const doc of snap.docs) {
    await doc.ref.update(patch);
    updated.push(doc.id);
  }
  return updated;
}

export async function runSyncRegisteredTeenCasesFromProfile(
  db: Firestore,
  authUid: string | undefined,
  data: SyncRegisteredTeenCasesFromProfileInput,
): Promise<SyncRegisteredTeenCasesFromProfileResult> {
  const uid = assertAuthenticated(authUid);
  const caseId =
    typeof data.caseId === "string" && data.caseId.trim()
      ? data.caseId.trim()
      : undefined;

  const actorSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
  if (!actorSnap.exists) {
    throw new AuthzError("User profile not found.", "permission-denied");
  }
  const actor = actorSnap.data()!;
  assertActiveAccount(actor);

  if (actor.role === "teen") {
    const teenSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
    const teen = teenSnap.data()!;
    const updatedCaseIds = await syncCasesForTeen(db, uid, teen);
    return { updatedCaseIds, syncedAt: new Date().toISOString() };
  }

  if (actor.role !== "barangay") {
    throw new AuthzError("Only barangay staff or the linked teen may sync case contact.", "permission-denied");
  }

  if (!caseId) {
    throw new AuthzError("caseId is required for barangay staff sync.", "invalid-argument");
  }

  const caseSnap = await db.collection("cases").doc(caseId).get();
  if (!caseSnap.exists) {
    throw new AuthzError("Case not found.", "not-found");
  }
  const caseData = caseSnap.data()!;
  const orgId = caseData.orgId;
  if (typeof orgId !== "string" || !isValidOrgId(orgId)) {
    throw new AuthzError("Case organization is invalid.", "failed-precondition");
  }
  const teenUid = caseData.teenUid;
  if (typeof teenUid !== "string" || teenUid.length < 1) {
    throw new AuthzError("Case is not linked to a registered teen.", "failed-precondition");
  }

  const membershipRef = db
    .collection(COLLECTIONS.organizationMemberships)
    .doc(membershipIdFor(orgId, uid));
  const orgRef = db.collection(COLLECTIONS.organizations).doc(orgId);
  const [orgSnap, membershipSnap] = await Promise.all([
    orgRef.get(),
    membershipRef.get(),
  ]);
  assertActiveOrganization(orgSnap.data());
  assertActiveMembership(membershipSnap.data(), orgId, uid);
  assertCapability(membershipSnap.data()!, CAPABILITIES.CASE_WRITE);

  const teenSnap = await db.collection(COLLECTIONS.users).doc(teenUid).get();
  if (!teenSnap.exists) {
    throw new AuthzError("Linked teen account not found.", "not-found");
  }
  const teen = teenSnap.data()!;
  if (teen.role !== "teen" || teen.selectedBarangayOrgId !== orgId) {
    throw new AuthzError("Linked teen is not in this organization.", "permission-denied");
  }

  const updatedCaseIds = await syncCasesForTeen(db, teenUid, teen, {
    caseId,
    orgId,
  });
  return { updatedCaseIds, syncedAt: new Date().toISOString() };
}
