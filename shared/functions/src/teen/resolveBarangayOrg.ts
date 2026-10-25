import { Firestore } from "firebase-admin/firestore";
import { AuthzError } from "../authz/assert";
import { barangayIdentityKey, loadPsgcBundle, validateBarangaySelection } from "../geo/psgc";
import {
  allowDemoIdentity,
  allowLegacyTeenOrgBinding,
  LEGACY_TEEN_ORG_ALLOWLIST,
} from "../geo/demoFlags";
import { DEMO_PSGC_BARANGAY_TO_ORG } from "../geo/demoPsgcShim";
import { DEMO_BARANGAY_ORG_ID } from "../reg/constants";

const IDENTITY_KEYS = "organizationIdentityKeys";

export function syntheticDemoBarangayKey(orgId: string): string {
  return `synthetic:demo:${orgId}`;
}

export async function resolveBarangayOrgIdFromPsgc(
  db: Firestore,
  psgcVersion: string,
  selection: {
    psgcRegionCode: string;
    psgcProvinceCode?: string | null;
    psgcCityMunCode: string;
    psgcBarangayCode: string;
  },
): Promise<string> {
  const bundle = loadPsgcBundle(psgcVersion);
  const validated = validateBarangaySelection(bundle, {
    psgcVersion,
    ...selection,
  });
  if (!validated.ok) {
    throw new AuthzError(validated.error, "invalid-argument");
  }

  if (allowDemoIdentity()) {
    const demoOrgId = DEMO_PSGC_BARANGAY_TO_ORG[selection.psgcBarangayCode];
    if (demoOrgId) {
      return resolveLegacyTeenOrgId(db, demoOrgId);
    }
  }

  const identityKey = barangayIdentityKey(selection.psgcBarangayCode);
  const keySnap = await db.collection(IDENTITY_KEYS).doc(identityKey).get();
  if (!keySnap.exists) {
    throw new AuthzError("Selected Barangay is not registered in SIBOL yet.", "not-found");
  }
  const keyData = keySnap.data()!;
  if (keyData.identityKind === "synthetic_demo" && !allowDemoIdentity()) {
    throw new AuthzError("Selected Barangay is not available.", "permission-denied");
  }
  const orgId = keyData.orgId as string;
  const orgSnap = await db.collection("organizations").doc(orgId).get();
  if (!orgSnap.exists) {
    throw new AuthzError("Organization record missing.", "failed-precondition");
  }
  const org = orgSnap.data()!;
  if (org.type !== "barangay") {
    throw new AuthzError("Invalid organization type.", "failed-precondition");
  }
  if (org.orgId !== orgId) {
    throw new AuthzError("Organization id mismatch.", "failed-precondition");
  }
  if (org.psgcBarangayCode && org.psgcBarangayCode !== selection.psgcBarangayCode) {
    throw new AuthzError("Organization geographic identity mismatch.", "failed-precondition");
  }
  if (org.status !== "active") {
    throw new AuthzError(
      "Selected Barangay is not active for assistance routing.",
      "failed-precondition",
    );
  }
  return orgId;
}

export async function resolveLegacyTeenOrgId(
  db: Firestore,
  orgId: string,
): Promise<string> {
  if (!allowLegacyTeenOrgBinding()) {
    throw new AuthzError("Legacy org binding is not allowed.", "invalid-argument");
  }
  if (!LEGACY_TEEN_ORG_ALLOWLIST.has(orgId)) {
    throw new AuthzError("Organization is not allowlisted for legacy binding.", "invalid-argument");
  }
  const orgSnap = await db.collection("organizations").doc(orgId).get();
  if (!orgSnap.exists) {
    throw new AuthzError("Selected Barangay is not available.", "not-found");
  }
  const org = orgSnap.data()!;
  if (org.type !== "barangay" || org.status !== "active") {
    throw new AuthzError(
      "Selected Barangay is not active for assistance routing.",
      "failed-precondition",
    );
  }
  return orgId;
}

export { DEMO_BARANGAY_ORG_ID };
