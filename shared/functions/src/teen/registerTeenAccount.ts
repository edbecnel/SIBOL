import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertAuthenticated, AuthzError } from "../authz/assert";
import { isValidOrgId } from "../authz/identifiers";
import { writeAuditEvent } from "../admin/audit";
import {
  resolveTeenOnboardingStatus,
  TEEN_ONBOARDING_POLICY,
} from "./onboardingPolicy";

const STAFF_ROLES = new Set(["barangay", "moph"]);

export type RegisterTeenInput = {
  selectedBarangayOrgId: string;
  displayName?: string;
  privacyConsentAcknowledged?: boolean;
};

export async function runRegisterTeenAccount(
  db: Firestore,
  authUid: string | undefined,
  authEmailVerified: boolean,
  data: RegisterTeenInput,
) {
  const uid = assertAuthenticated(authUid);
  const orgId = data.selectedBarangayOrgId?.trim();
  if (!orgId || !isValidOrgId(orgId)) {
    throw new AuthzError("selectedBarangayOrgId is invalid.", "invalid-argument");
  }
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

  const displayName =
    typeof data.displayName === "string" && data.displayName.trim().length >= 2
      ? data.displayName.trim()
      : "Teen account";

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
        return {
          created: false,
          uid,
          onboardingStatus: existing.onboardingStatus ?? "complete",
          selectedBarangayOrgId: existing.selectedBarangayOrgId ?? orgId,
          idempotent: sameOrg,
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
    if (org.type !== "barangay" || org.status !== "active") {
      throw new AuthzError(
        "Selected Barangay is not active for assistance routing.",
        "failed-precondition",
      );
    }

    const onboardingStatus = resolveTeenOnboardingStatus(authEmailVerified);
    const now = Timestamp.now();
    tx.create(userRef, {
      role: "teen",
      displayName,
      active: true,
      createdAt: now,
      selectedBarangayOrgId: orgId,
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
