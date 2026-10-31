import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { writeAuditEvent } from "../admin/audit";
import {
  rejectLegacyFreeTextFields,
  validateCategoryCodes,
  validateResponseTemplateCode,
} from "../disclosure/categoryCatalog";
import {
  assertAuthorizationActiveForDisclosure,
  assertCategoriesSubset,
  parseAuthorizationDoc,
} from "../disclosure/authorizationLoader";
import { buildAuthorizedProfileDocument } from "../disclosure/buildAuthorizedProfile";
import { DISCLOSURE_COLLECTIONS } from "../disclosure/constants";
import { isIdentifyingDisclosureLegallyActivated } from "../disclosure/disclosurePolicy";
import { generateInformationResponseDescription } from "../disclosure/referralTemplates";
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
import { COLLECTIONS } from "./constants";
import {
  CoordinationStatus,
  phaseForCoordinationStatus,
} from "./coordinationStatus";

export type BarangayRespondToMophInformationRequestInput = Record<string, unknown> & {
  threadId?: unknown;
  responseTemplateCode?: unknown;
  disclosedCategoryCodes?: unknown;
  authorizationId?: unknown;
  responseSummary?: unknown;
};

export type BarangayRespondToMophInformationRequestResult = {
  threadId: string;
  coordinationStatus: string;
};

function validateThreadId(raw: unknown): string {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("invalid-argument", "threadId is required.");
  }
  return raw.trim();
}

export async function runBarangayRespondToMophInformationRequest(
  db: Firestore,
  authUid: string | undefined,
  data: BarangayRespondToMophInformationRequestInput,
): Promise<BarangayRespondToMophInformationRequestResult> {
  if (!authUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  rejectLegacyFreeTextFields(data as Record<string, unknown>);
  if ("responseSummary" in data && data.responseSummary != null) {
    throw new HttpsError(
      "invalid-argument",
      "responseSummary is not accepted; use structured response fields.",
    );
  }

  const threadId = validateThreadId(data.threadId);
  const responseTemplateCode = validateResponseTemplateCode(
    data.responseTemplateCode,
  );
  const disclosedCategoryCodes =
    data.disclosedCategoryCodes == null ||
    (Array.isArray(data.disclosedCategoryCodes) &&
      data.disclosedCategoryCodes.length === 0)
      ? []
      : validateCategoryCodes(data.disclosedCategoryCodes, "disclosedCategoryCodes");

  if (disclosedCategoryCodes.length > 0) {
    if (!isIdentifyingDisclosureLegallyActivated()) {
      throw new HttpsError(
        "failed-precondition",
        "Identifying disclosure is not legally activated in this environment.",
      );
    }
    if (typeof data.authorizationId !== "string" || !data.authorizationId.trim()) {
      throw new HttpsError(
        "invalid-argument",
        "authorizationId is required when disclosing authorized categories.",
      );
    }
  }

  const userRef = db.collection(COLLECTIONS.users).doc(authUid);
  const threadRef = db.collection(COLLECTIONS.caseCoordinationThreads).doc(threadId);

  const result = await db.runTransaction(async (tx) => {
    const [userSnap, threadSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(threadRef),
    ]);

    if (!userSnap.exists) {
      throw new HttpsError("permission-denied", "User profile not found.");
    }
    const user = userSnap.data()!;
    if (user.role !== "barangay") {
      throw new HttpsError(
        "permission-denied",
        "Only barangay personnel may respond to hospital information requests.",
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

    if (!threadSnap.exists) {
      throw new HttpsError("not-found", "Coordination thread not found.");
    }
    const thread = threadSnap.data()!;
    const barangayOrgId = thread.orgId;
    if (typeof barangayOrgId !== "string" || !isValidOrgId(barangayOrgId)) {
      throw new HttpsError(
        "failed-precondition",
        "Coordination thread is missing organization scope.",
      );
    }

    const orgRef = db.collection(COLLECTIONS.organizations).doc(barangayOrgId);
    const membershipRef = db
      .collection(COLLECTIONS.organizationMemberships)
      .doc(membershipIdFor(barangayOrgId, authUid));
    const [orgSnap, membershipSnap] = await Promise.all([
      tx.get(orgRef),
      tx.get(membershipRef),
    ]);
    try {
      assertActiveOrganization(orgSnap.data());
      assertActiveMembership(membershipSnap.data(), barangayOrgId, authUid);
      assertCapability(membershipSnap.data()!, CAPABILITIES.COORDINATION_BARANGAY);
    } catch (err) {
      throw new HttpsError(
        "permission-denied",
        err instanceof Error ? err.message : "Not authorized for this organization.",
      );
    }

    const currentStatus = thread.coordinationStatus;
    if (currentStatus !== CoordinationStatus.additionalInformationRequested) {
      throw new HttpsError(
        "failed-precondition",
        "Hospital has not requested additional information for this referral.",
      );
    }

    const bindingSnap = await tx.get(
      threadRef.collection("private").doc("binding"),
    );
    if (!bindingSnap.exists) {
      throw new HttpsError("failed-precondition", "Coordination binding missing.");
    }
    const teenUid = bindingSnap.data()!.teenUid as string;
    const assistanceRequestId = bindingSnap.data()!.assistanceRequestId as string;

    let authorizationId: string | undefined;
    if (disclosedCategoryCodes.length > 0) {
      authorizationId = (data.authorizationId as string).trim();
      const authRef = db
        .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
        .doc(authorizationId);
      const authSnap = await tx.get(authRef);
      if (!authSnap.exists) {
        throw new HttpsError("not-found", "Disclosure authorization not found.");
      }
      const loaded = parseAuthorizationDoc(authorizationId, authSnap.data()!);
      assertAuthorizationActiveForDisclosure(
        loaded,
        assistanceRequestId,
        thread.targetHospitalOrgId as string,
        { linkedThreadId: threadId },
      );
      assertCategoriesSubset(disclosedCategoryCodes, loaded.authorizedCategories);

      const teenSnap = await tx.get(db.collection(COLLECTIONS.users).doc(teenUid));
      const patch = buildAuthorizedProfileDocument(
        teenUid,
        teenSnap.data() ?? {},
        disclosedCategoryCodes,
        loaded.otherEssentialJustification,
      );
      tx.set(
        threadRef.collection("authorizedDisclosure").doc("profile"),
        {
          ...patch,
          categoryCodes: disclosedCategoryCodes,
          authorizationId,
          updatedAt: new Date(),
        },
        { merge: true },
      );
    }

    const now = new Date();
    const nextStatus = CoordinationStatus.informationProvided;
    const phase = phaseForCoordinationStatus(nextStatus);
    const eventRef = threadRef.collection("staffEvents").doc();
    const body = generateInformationResponseDescription(
      responseTemplateCode,
      disclosedCategoryCodes.length > 0,
    );

    tx.update(threadRef, {
      coordinationStatus: nextStatus,
      phase,
      updatedAt: now,
      lastStaffEventAt: now,
    });

    tx.set(eventRef, {
      eventType: "barangay_information_response",
      body,
      responseTemplateCode,
      disclosedCategoryCodes,
      structuredResponse: true,
      actorUid: authUid,
      createdAt: now,
      previousStatus: currentStatus,
      newStatus: nextStatus,
    });

    return { threadId, coordinationStatus: nextStatus };
  });

  await writeAuditEvent(db, {
    actorUid: authUid,
    operation: "coordination_information_response",
    outcome: "success",
    after: {
      threadId: result.threadId,
      responseTemplateCode: data.responseTemplateCode,
      disclosedCategoryCount: Array.isArray(data.disclosedCategoryCodes)
        ? data.disclosedCategoryCodes.length
        : 0,
    },
  });

  return result;
}
