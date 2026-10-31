import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { writeAuditEvent } from "../admin/audit";
import { CAPABILITIES } from "../authz/capabilities";
import {
  assertActiveAccount,
  assertActiveMembership,
  assertActiveOrganization,
  assertCapability,
  assertPasswordChangeNotRequired,
  AuthzError,
} from "../authz/assert";
import { isValidOrgId, membershipIdFor } from "../authz/identifiers";
import { COLLECTIONS } from "../coordination/constants";
import { TARGET_HOSPITAL_ORG_ID } from "../coordination/coordinationStatus";
import {
  validateCategoryCodes,
  validatePurposeCode,
} from "./categoryCatalog";
import {
  AuthorizationStatus,
  DecisionAuthority,
  DISCLOSURE_COLLECTIONS,
} from "./constants";
import {
  disclosureCategoryCatalogVersion,
  disclosureNoticeVersion,
} from "./disclosurePolicy";

export type RequestMophDisclosureAuthorizationInput = {
  assistanceRequestId?: unknown;
  targetHospitalOrgId?: unknown;
  purposeCode?: unknown;
  requestedCategories?: unknown;
  otherEssentialJustification?: unknown;
  decisionAuthority?: unknown;
};

export type RequestMophDisclosureAuthorizationResult = {
  authorizationId: string;
  status: string;
};

function validateAssistanceRequestId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "assistanceRequestId is required.");
  }
  return raw.trim();
}

export async function runRequestMophDisclosureAuthorization(
  db: Firestore,
  authUid: string | undefined,
  data: RequestMophDisclosureAuthorizationInput,
): Promise<RequestMophDisclosureAuthorizationResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const assistanceRequestId = validateAssistanceRequestId(data.assistanceRequestId);
  const targetHospitalOrgId =
    typeof data.targetHospitalOrgId === "string" && data.targetHospitalOrgId.trim()
      ? data.targetHospitalOrgId.trim()
      : TARGET_HOSPITAL_ORG_ID;
  const purposeCode = validatePurposeCode(data.purposeCode);
  const requestedCategories = validateCategoryCodes(
    data.requestedCategories,
    "requestedCategories",
  );
  let otherEssentialJustification: string | undefined;
  if (requestedCategories.includes("other_essential")) {
    if (typeof data.otherEssentialJustification !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "otherEssentialJustification is required for other_essential.",
      );
    }
    const trimmed = data.otherEssentialJustification.trim();
    if (trimmed.length < 10 || trimmed.length > 200) {
      throw new HttpsError(
        "invalid-argument",
        "otherEssentialJustification must be 10–200 characters.",
      );
    }
    otherEssentialJustification = trimmed;
  }

  const decisionAuthority =
    typeof data.decisionAuthority === "string"
      ? data.decisionAuthority.trim()
      : DecisionAuthority.teenSelf;
  if (
    decisionAuthority !== DecisionAuthority.teenSelf &&
    decisionAuthority !== DecisionAuthority.guardianVerified &&
    decisionAuthority !== DecisionAuthority.otherLegalAuthority &&
    decisionAuthority !== DecisionAuthority.pendingVerification
  ) {
    throw new HttpsError("invalid-argument", "decisionAuthority is invalid.");
  }

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const assistanceRef = db
    .collection(COLLECTIONS.teenAssistanceRequests)
    .doc(assistanceRequestId);

  return db.runTransaction(async (tx) => {
    const [userSnap, assistanceSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(assistanceRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may request disclosure authorization.",
      );
    }
    try {
      assertActiveAccount(user);
      assertPasswordChangeNotRequired(user);
    } catch (err) {
      throw new HttpsError(
        err instanceof AuthzError && err.code === "failed-precondition"
          ? "failed-precondition"
          : "permission-denied",
        err instanceof Error ? err.message : "Account is not active.",
      );
    }

    if (!assistanceSnap.exists) {
      throw new HttpsError("not-found", "Assistance request not found.");
    }
    const assistance = assistanceSnap.data()!;
    const assistanceOrgId = assistance.orgId;
    if (typeof assistanceOrgId !== "string" || !isValidOrgId(assistanceOrgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing organization scope.",
      );
    }
    if (assistance.status !== "acknowledged") {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request must be acknowledged before authorization request.",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(assistanceOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(assistanceOrgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), assistanceOrgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this organization.",
      );
    }

    const teenUid = assistance.teenUid;
    if (typeof teenUid !== "string" || !teenUid) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing teen association.",
      );
    }

    const authRef = db
      .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
      .doc();
    const now = new Date();

    tx.set(authRef, {
      assistanceRequestId,
      teenUid,
      orgId: assistanceOrgId,
      targetHospitalOrgId,
      purposeCode,
      requestedCategories,
      authorizedCategories: [],
      noticeVersion: disclosureNoticeVersion(),
      categoryCatalogVersion: disclosureCategoryCatalogVersion(),
      status: AuthorizationStatus.requested,
      decisionAuthority,
      requestedByUid: authUid,
      requestedAt: now,
      ...(otherEssentialJustification
        ? { otherEssentialJustification }
        : {}),
    });

    return { authorizationId: authRef.id, status: AuthorizationStatus.requested };
  }).then(async (result) => {
    await writeAuditEvent(db, {
      actorUid: authUid,
      operation: "disclosure_authorization_requested",
      outcome: "success",
      targetOrgId: undefined,
      targetAccountUid: undefined,
      after: {
        authorizationId: result.authorizationId,
        assistanceRequestId,
        requestedCategories,
        purposeCode,
      },
    });
    return result;
  });
}
