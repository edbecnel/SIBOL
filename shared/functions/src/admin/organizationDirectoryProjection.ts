import type { Firestore, Transaction } from "firebase-admin/firestore";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

export const ORGANIZATION_DIRECTORY_COLLECTION = "organizationDirectory";

export type OrganizationDirectoryDoc = {
  orgId: string;
  name: string;
  type: "barangay" | "hospital";
  status: "pending" | "active" | "suspended";
  updatedAt: Timestamp | FieldValue;
  geographicSiteLabel?: string;
};

function trimOptionalString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function assertOrgType(value: unknown): "barangay" | "hospital" {
  if (value === "barangay" || value === "hospital") return value;
  throw new Error("Invalid organization type for directory projection.");
}

function assertOrgStatus(value: unknown): "pending" | "active" | "suspended" {
  if (value === "pending" || value === "active" || value === "suspended") {
    return value;
  }
  throw new Error("Invalid organization status for directory projection.");
}

/**
 * Build a limited identity projection from an authoritative organizations document.
 */
export function projectOrganizationDirectoryFromOrgData(
  orgId: string,
  data: Record<string, unknown>,
  updatedAt: Timestamp = Timestamp.now(),
): OrganizationDirectoryDoc {
  const name = trimOptionalString(data.name);
  if (!name) {
    throw new Error(`Organization ${orgId} is missing a valid name.`);
  }
  const geographicSiteLabel = trimOptionalString(data.legacyBarangayLabel);
  return {
    orgId,
    name,
    type: assertOrgType(data.type),
    status: assertOrgStatus(data.status ?? "active"),
    updatedAt,
    ...(geographicSiteLabel ? { geographicSiteLabel } : {}),
  };
}

export function organizationDirectoryRef(db: Firestore, orgId: string) {
  return db.collection(ORGANIZATION_DIRECTORY_COLLECTION).doc(orgId);
}

export function setOrganizationDirectoryInTransaction(
  tx: Transaction,
  db: Firestore,
  orgId: string,
  data: Record<string, unknown>,
  updatedAt: Timestamp = Timestamp.now(),
) {
  const projection = projectOrganizationDirectoryFromOrgData(orgId, data, updatedAt);
  tx.set(organizationDirectoryRef(db, orgId), projection, { merge: true });
}

export async function upsertOrganizationDirectoryFromOrgSnapshot(
  db: Firestore,
  orgId: string,
): Promise<"created" | "updated" | "skipped"> {
  const orgSnap = await db.collection("organizations").doc(orgId).get();
  if (!orgSnap.exists || !orgSnap.data()) {
    return "skipped";
  }
  const projection = projectOrganizationDirectoryFromOrgData(orgId, orgSnap.data()!);
  const dirRef = organizationDirectoryRef(db, orgId);
  const existing = await dirRef.get();
  await dirRef.set(projection, { merge: true });
  return existing.exists ? "updated" : "created";
}
