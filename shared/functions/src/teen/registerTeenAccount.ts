import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertAuthenticated, AuthzError } from "../authz/assert";
import { isValidOrgId } from "../authz/identifiers";
import { writeAuditEvent } from "../admin/audit";
import {
  resolveTeenOnboardingStatus,
  TEEN_ONBOARDING_POLICY,
} from "./onboardingPolicy";
import {
  resolveBarangayOrgIdFromPsgc,
  resolveLegacyTeenOrgId,
} from "./resolveBarangayOrg";
import { allowLegacyTeenOrgBinding } from "../geo/demoFlags";
import { resolveTeenAssignedBarangayLabel } from "./teenAssignedBarangay";
import { resolveTeenIdentityFields } from "./teenIdentityFields";

const STAFF_ROLES = new Set(["barangay", "moph"]);

export type RegisterTeenInput = {
  selectedBarangayPsgcCode?: string;
  psgcVersion?: string;
  psgcRegionCode?: string;
  psgcProvinceCode?: string | null;
  psgcCityMunCode?: string;
  selectedBarangayOrgId?: string;
  displayName?: string;
  dateOfBirth?: string;
  contactEmail?: string;
  contactPhone?: string;
  privacyConsentAcknowledged?: boolean;
};

async function resolveTargetOrgId(
  db: Firestore,
  data: RegisterTeenInput,
): Promise<string> {
  const psgcCode = data.selectedBarangayPsgcCode?.trim();
  if (psgcCode) {
    const version = data.psgcVersion?.trim();
    if (!version) {
      throw new AuthzError("psgcVersion is required.", "invalid-argument");
    }
    return resolveBarangayOrgIdFromPsgc(db, version, {
      psgcRegionCode: data.psgcRegionCode?.trim() ?? "",
      psgcProvinceCode: data.psgcProvinceCode ?? null,
      psgcCityMunCode: data.psgcCityMunCode?.trim() ?? "",
      psgcBarangayCode: psgcCode,
    });
  }
  const legacyOrgId = data.selectedBarangayOrgId?.trim();
  if (legacyOrgId && allowLegacyTeenOrgBinding()) {
    return resolveLegacyTeenOrgId(db, legacyOrgId);
  }
  if (legacyOrgId && isValidOrgId(legacyOrgId)) {
    throw new AuthzError(
      "Use geographic Barangay selection. Legacy org binding is disabled.",
      "invalid-argument",
    );
  }
  throw new AuthzError(
    "selectedBarangayPsgcCode or authorized legacy binding is required.",
    "invalid-argument",
  );
}

export async function runRegisterTeenAccount(
  db: Firestore,
  authUid: string | undefined,
  authEmailVerified: boolean,
  data: RegisterTeenInput,
) {
  const uid = assertAuthenticated(authUid);
  const orgId = await resolveTargetOrgId(db, data);

  if (data.privacyConsentAcknowledged !== true) {
    throw new AuthzError(
      "Privacy notice acknowledgment is required.",
      "invalid-argument",
    );
  }

  if (
    TEEN_ONBOARDING_POLICY.requireEmailVerificationBeforeProfile &&
    !authEmailVerified
  ) {
    throw new AuthzError(
      "Verify your email before completing registration.",
      "failed-precondition",
    );
  }

  const userRef = db.collection("users").doc(uid);
  const orgRef = db.collection("organizations").doc(orgId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, orgSnap] = await Promise.all([tx.get(userRef), tx.get(orgRef)]);

    if (userSnap.exists) {
      const existing = userSnap.data()!;
      if (existing.isCentralAdmin === true || STAFF_ROLES.has(existing.role)) {
        throw new AuthzError(
          "This account already has staff access. Sign in instead.",
          "failed-precondition",
        );
      }
      if (existing.role === "teen") {
        if (existing.active === false) {
          throw new AuthzError("Account is suspended.", "permission-denied");
        }
        const sameOrg = existing.selectedBarangayOrgId === orgId;
        if (!sameOrg) {
          throw new AuthzError(
            "Barangay selection cannot be changed by repeating registration.",
            "failed-precondition",
          );
        }
        return {
          created: false,
          uid,
          onboardingStatus: existing.onboardingStatus ?? "complete",
          selectedBarangayOrgId: existing.selectedBarangayOrgId ?? orgId,
          idempotent: true,
        };
      }
      throw new AuthzError(
        "Account profile already exists with a different role.",
        "already-exists",
      );
    }

    if (!orgSnap.exists) {
      throw new AuthzError("Selected Barangay is not available.", "not-found");
    }
    const org = orgSnap.data()!;
    if (org.orgId && org.orgId !== orgSnap.id) {
      throw new AuthzError("Organization record invalid.", "failed-precondition");
    }
    if (org.type !== "barangay" || org.status !== "active") {
      throw new AuthzError(
        "Selected Barangay is not active for assistance routing.",
        "failed-precondition",
      );
    }

    const identity = resolveTeenIdentityFields(data);
    const onboardingStatus = resolveTeenOnboardingStatus(authEmailVerified);
    const assignedBarangay = resolveTeenAssignedBarangayLabel(org, data);
    const now = Timestamp.now();
    tx.create(userRef, {
      role: "teen",
      displayName: identity.displayName,
      dateOfBirth: identity.dateOfBirth,
      ...(identity.contactEmail ? { contactEmail: identity.contactEmail } : {}),
      ...(identity.contactPhone ? { contactPhone: identity.contactPhone } : {}),
      active: true,
      createdAt: now,
      selectedBarangayOrgId: orgId,
      assignedBarangay,
      onboardingStatus,
      privacyNoticeVersion: TEEN_ONBOARDING_POLICY.privacyNoticeVersion,
      privacyConsentAt: now,
    });

    return {
      created: true,
      uid,
      onboardingStatus,
      selectedBarangayOrgId: orgId,
      idempotent: false,
    };
  });

  if (result.created) {
    await writeAuditEvent(db, {
      actorUid: uid,
      operation: "teen_registered",
      outcome: "success",
      targetOrgId: orgId,
      targetAccountUid: uid,
      after: {
        role: "teen",
        onboardingStatus: result.onboardingStatus,
      },
    });
  }

  return result;
}
