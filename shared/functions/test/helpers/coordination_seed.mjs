import { Timestamp } from "firebase-admin/firestore";

export const site = "Barangay 3, Balingasag";
export const orgId = "barangay03";
export const otherOrgId = "barangay99";
export const hospitalOrgId = "hospital01";

export function membershipDoc(org, uid, caps, status = "active") {
  const now = Timestamp.now();
  return {
    membershipId: `mbr_${org}__${uid}`,
    orgId: org,
    accountUid: uid,
    status,
    capabilities: caps,
    createdAt: now,
    updatedAt: now,
  };
}

export async function seedBaseOrgs(db) {
  const now = Timestamp.now();
  for (const [id, type, name] of [
    [orgId, "barangay", site],
    [otherOrgId, "barangay", "Other Demo Barangay"],
    [hospitalOrgId, "hospital", "Demo Hospital"],
  ]) {
    await db.collection("organizations").doc(id).set({
      orgId: id,
      type,
      name,
      status: "active",
      ...(type === "barangay" && id === orgId ? { legacyBarangayLabel: site } : {}),
      createdAt: now,
      updatedAt: now,
    });
  }
}

export async function seedAcknowledgedAssistance(
  db,
  assistanceRequestId,
  {
    teenUid,
    barangayUid,
    org = orgId,
    status = "acknowledged",
  },
) {
  const now = Timestamp.now();
  await db.collection("teenAssistanceRequests").doc(assistanceRequestId).set({
    teenUid,
    barangay: site,
    orgId: org,
    category: "generalSupport",
    description: "Fictional assistance request for coordination tests.",
    status,
    createdAt: now,
    ...(status === "acknowledged"
      ? { acknowledgedAt: now, acknowledgedByUid: barangayUid }
      : {}),
  });
}

export async function seedCoordinationReferralForAssistance(
  db,
  assistanceRequestId,
  {
    teenUid,
    barangayUid,
    org = orgId,
    coordinationStatus = "received",
    threadId = `thread-${assistanceRequestId}`,
  },
) {
  const now = Timestamp.now();
  await db.collection("caseCoordinationThreads").doc(threadId).set({
    barangay: site,
    orgId: org,
    displayRef: `SIBOL-REF-${assistanceRequestId}`,
    category: "generalSupport",
    barangayReferralSummary: "Structured fictional referral for tests.",
    referralPurposeCode: "hospital_coordination",
    coordinationNeedCodes: ["schedule_coordination"],
    disclosureMode: "minimum",
    structuredReferral: true,
    phase: "awaitingMoph",
    coordinationStatus,
    targetHospitalOrgId: hospitalOrgId,
    assistanceRequestId,
    createdAt: now,
    updatedAt: now,
    lastStaffEventAt: now,
    createdByUid: barangayUid,
  });
  await db
    .collection("caseCoordinationThreads")
    .doc(threadId)
    .collection("private")
    .doc("binding")
    .set({
      teenUid,
      assistanceRequestId,
      createdAt: now,
      createdByUid: barangayUid,
    });
  await db.collection("barangayCoordinationRegistry").doc(assistanceRequestId).set({
    threadId,
    barangay: site,
    orgId: org,
    teenUid,
    active: true,
    createdAt: now,
  });
  return threadId;
}
