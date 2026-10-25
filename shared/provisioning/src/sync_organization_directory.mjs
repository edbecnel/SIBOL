import { Timestamp } from "firebase-admin/firestore";

import { DEMO_BARANGAY_ORG_ID, DEMO_HOSPITAL_ORG_ID } from "./constants.mjs";

const COLLECTION = "organizationDirectory";

function trimOptional(value) {
  if (typeof value !== "string") return undefined;
  const t = value.trim();
  return t.length > 0 ? t : undefined;
}

export function projectDirectoryFromOrg(orgId, data, updatedAt = Timestamp.now()) {
  const name = trimOptional(data.name);
  if (!name) {
    throw new Error(`Organization ${orgId} is missing name`);
  }
  const type = data.type;
  if (type !== "barangay" && type !== "hospital") {
    throw new Error(`Organization ${orgId} has invalid type`);
  }
  const status = data.status ?? "active";
  if (status !== "pending" && status !== "active" && status !== "suspended") {
    throw new Error(`Organization ${orgId} has invalid status`);
  }
  const geographicSiteLabel = trimOptional(data.legacyBarangayLabel);
  return {
    orgId,
    name,
    type,
    status,
    updatedAt,
    ...(geographicSiteLabel ? { geographicSiteLabel } : {}),
  };
}

/**
 * Idempotent upsert of organizationDirectory from organizations/{orgId}.
 * Does not modify organizations documents.
 */
export async function upsertOrganizationDirectoryForOrg(db, orgId, logger = console) {
  const orgSnap = await db.collection("organizations").doc(orgId).get();
  if (!orgSnap.exists) {
    logger.log(`Skip directory sync: organizations/${orgId} missing`);
    return "skipped";
  }
  const projection = projectDirectoryFromOrg(orgId, orgSnap.data());
  const dirRef = db.collection(COLLECTION).doc(orgId);
  const existed = (await dirRef.get()).exists;
  await dirRef.set(projection, { merge: true });
  logger.log(`${existed ? "Updated" : "Created"} organizationDirectory/${orgId}`);
  return existed ? "updated" : "created";
}

/** Demo emulator org ids for narrow backfill (SIBOL-ORG-NAME-003 A01). */
export const DEMO_DIRECTORY_ORG_IDS = [DEMO_BARANGAY_ORG_ID, DEMO_HOSPITAL_ORG_ID];

export async function upsertDemoOrganizationDirectoryEntries(db, logger = console) {
  const results = {};
  for (const orgId of DEMO_DIRECTORY_ORG_IDS) {
    results[orgId] = await upsertOrganizationDirectoryForOrg(db, orgId, logger);
  }
  return results;
}
