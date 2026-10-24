import { Timestamp } from "firebase-admin/firestore";

export const site = "Barangay Tres, Balingasag";
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
