import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { randomBytes } from "node:crypto";
import { writeAuditEvent } from "../admin/audit";
import {
  rejectLegacyFreeTextFields,
  validateCoordinationNeedCodes,
  validatePurposeCode,
} from "../disclosure/categoryCatalog";
import { buildAuthorizedProfileDocument } from "../disclosure/buildAuthorizedProfile";
import {
  assertAuthorizationAvailableForNewReferral,
  parseAuthorizationDoc,
} from "../disclosure/authorizationLoader";
import { DisclosureMode, DISCLOSURE_COLLECTIONS } from "../disclosure/constants";
import { isIdentifyingDisclosureLegallyActivated } from "../disclosure/disclosurePolicy";
import { generateReferralSummaryDescription } from "../disclosure/referralTemplates";
import {
  COLLECTIONS,
  TEEN_PROGRESS,
} from "./constants";
import {
  CoordinationStatus,
  TARGET_HOSPITAL_ORG_ID,
} from "./coordinationStatus";
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

export type CreateCoordinationReferralInput = Record<string, unknown> & {
  assistanceRequestId?: unknown;
  disclosureMode?: unknown;
  authorizationId?: unknown;
  referralPurposeCode?: unknown;
  coordinationNeedCodes?: unknown;
  /** @deprecated Rejected for new submissions (C1). */
  barangayReferralSummary?: unknown;
};

export type CreateCoordinationReferralResult = {
  threadId: string;
  displayRef: string;
  disclosureMode: string;
};

function generateDisplayRef(): string {
  const suffix = randomBytes(8).toString("hex").toUpperCase();
  return `SIBOL-REF-${suffix}`;
}

function validateAssistanceRequestId(raw: unknown): string {
  if (typeof raw !== "string" || raw.trim().length < 1) {
    throw new HttpsError(
      "invalid-argument",
      "assistanceRequestId is required.",
    );
  }
  return raw.trim();
}

function validateDisclosureMode(raw: unknown): string {
  if (raw !== DisclosureMode.minimum && raw !== DisclosureMode.authorized) {
    throw new HttpsError(
      "invalid-argument",
      "disclosureMode must be minimum or authorized.",
    );
  }
  return raw;
}

export async function runCreateCoordinationReferral(
  db: Firestore,
  authUid: string | undefined,
  data: CreateCoordinationReferralInput,
): Promise<CreateCoordinationReferralResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  rejectLegacyFreeTextFields(data as Record<string, unknown>);
  if ("barangayReferralSummary" in data && data.barangayReferralSummary != null) {
    throw new HttpsError(
      "invalid-argument",
      "barangayReferralSummary is not accepted; use structured referral fields.",
    );
  }

  const assistanceRequestId = validateAssistanceRequestId(data.assistanceRequestId);
  const disclosureMode = validateDisclosureMode(data.disclosureMode);
  const referralPurposeCode = validatePurposeCode(data.referralPurposeCode);
  const coordinationNeedCodes = validateCoordinationNeedCodes(
    data.coordinationNeedCodes,
  );
  const generatedSummary = generateReferralSummaryDescription(
    referralPurposeCode,
    coordinationNeedCodes,
  );

  let authorizationId: string | undefined;
  if (disclosureMode === DisclosureMode.authorized) {
    if (!isIdentifyingDisclosureLegallyActivated()) {
      throw new HttpsError(
        "failed-precondition",
        "Identifying disclosure to MOPH is not legally activated in this environment.",
      );
    }
    if (typeof data.authorizationId !== "string" || !data.authorizationId.trim()) {
      throw new HttpsError(
        "invalid-argument",
        "authorizationId is required for authorized disclosure mode.",
      );
    }
    authorizationId = data.authorizationId.trim();
  }

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const assistanceRef = db
    .collection(COLLECTIONS.teenAssistanceRequests)
    .doc(assistanceRequestId);
  const registryRef = db
    .collection(COLLECTIONS.barangayCoordinationRegistry)
    .doc(assistanceRequestId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, assistanceSnap, registrySnap] = await Promise.all([
      tx.get(userRef),
      tx.get(assistanceRef),
      tx.get(registryRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may create referrals.",
      );
    }
    try {
      assertActiveAccount(user);
      assertPasswordChangeNotRequired(user);
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      const message =
        err instanceof Error ? err.message : "Account is not active.";
      const code =
        err instanceof AuthzError && err.code === "failed-precondition"
          ? "failed-precondition"
          : "permission-denied";
      throw new HttpsError(code, message);
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

    const assignedBarangay =
      typeof assistance.barangay === "string" ? assistance.barangay : "";
    if (assignedBarangay.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing barangay label.",
      );
    }
    if (assistance.status !== "acknowledged") {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request must be acknowledged before referral.",
      );
    }

    if (registrySnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "A coordination referral already exists for this assistance request.",
      );
    }

    const teenUid = assistance.teenUid;
    if (typeof teenUid !== "string" || teenUid.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request is missing teen association.",
      );
    }

    const category = assistance.category;
    if (typeof category !== "string" || category.length < 1) {
      throw new HttpsError(
        "failed-precondition",
        "Assistance request category is invalid.",
      );
    }

    let authorizationNoticeVersion: string | undefined;
    let authorizedCategories: string[] = [];
    let otherEssentialJustification: string | undefined;

    if (disclosureMode === DisclosureMode.authorized && authorizationId) {
      const authRef = db
        .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
        .doc(authorizationId);
      const authSnap = await tx.get(authRef);
      if (!authSnap.exists) {
        throw new HttpsError("not-found", "Disclosure authorization not found.");
      }
      const loaded = parseAuthorizationDoc(authorizationId, authSnap.data()!);
      assertAuthorizationAvailableForNewReferral(
        loaded,
        assistanceRequestId,
        TARGET_HOSPITAL_ORG_ID,
      );
      authorizedCategories = loaded.authorizedCategories;
      authorizationNoticeVersion = authSnap.data()!.noticeVersion as string | undefined;
      otherEssentialJustification = loaded.otherEssentialJustification;
    }

    let authorizedProfile: Record<string, unknown> | undefined;
    if (disclosureMode === DisclosureMode.authorized && authorizationId) {
      const teenSnap = await tx.get(db.collection(COLLECTIONS.users).doc(teenUid));
      if (!teenSnap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Teen profile not found for authorized disclosure.",
        );
      }
      authorizedProfile = buildAuthorizedProfileDocument(
        teenUid,
        teenSnap.data()!,
        authorizedCategories,
        otherEssentialJustification,
      );
    }

    const threadRef = db.collection(COLLECTIONS.caseCoordinationThreads).doc();
    const threadId = threadRef.id;
    const displayRef = generateDisplayRef();

    const now = new Date();
    const eventRef = threadRef.collection("staffEvents").doc();

    const existingCaseId =
      typeof assistance.caseId === "string" && assistance.caseId.length > 0
        ? assistance.caseId
        : undefined;

    tx.set(threadRef, {
      barangay: assignedBarangay,
      orgId: assistanceOrgId,
      displayRef,
      category,
      barangayReferralSummary: generatedSummary,
      referralPurposeCode,
      coordinationNeedCodes,
      disclosureMode,
      assistanceRequestId,
      ...(existingCaseId ? { caseId: existingCaseId } : {}),
      ...(authorizationId ? { authorizationId } : {}),
      ...(authorizationNoticeVersion
        ? { authorizationNoticeVersion }
        : {}),
      structuredReferral: true,
      phase: "referred",
      coordinationStatus: CoordinationStatus.submitted,
      targetHospitalOrgId: TARGET_HOSPITAL_ORG_ID,
      createdAt: now,
      updatedAt: now,
      lastStaffEventAt: now,
      createdByUid: authUid,
    });

    tx.set(threadRef.collection("private").doc("binding"), {
      teenUid,
      assistanceRequestId,
      createdAt: now,
      createdByUid: authUid,
    });

    if (disclosureMode === DisclosureMode.authorized && authorizationId && authorizedProfile) {
      tx.set(threadRef.collection("authorizedDisclosure").doc("profile"), {
        ...authorizedProfile,
        categoryCodes: authorizedCategories,
        authorizationId,
        createdAt: now,
      });
      tx.update(
        db
          .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
          .doc(authorizationId),
        { referralThreadId: threadId },
      );
    }

    tx.set(registryRef, {
      threadId,
      barangay: assignedBarangay,
      orgId: assistanceOrgId,
      teenUid,
      active: true,
      createdAt: now,
    });

    tx.set(eventRef, {
      eventType: "referral_submitted",
      body: "Barangay submitted a structured hospital coordination referral for MOPH review.",
      actorUid: authUid,
      createdAt: now,
    });

    tx.set(
      db
        .collection(COLLECTIONS.teenCoordinationLinks)
        .doc(teenUid)
        .collection("links")
        .doc(assistanceRequestId),
      {
        threadId,
        progressCode: TEEN_PROGRESS.code,
        progressLabel: TEEN_PROGRESS.label,
        updatedAt: now,
        barangay: assignedBarangay,
      },
    );

    return { threadId, displayRef, disclosureMode };
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "coordination_referral_created",
    outcome: "success",
    after: {
      threadId: result.threadId,
      assistanceRequestId,
      disclosureMode: result.disclosureMode,
      authorizationId: authorizationId ?? null,
      referralPurposeCode,
      coordinationNeedCodes,
    },
  });

  return result;
}
