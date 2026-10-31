import type { Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import {
  AuthorizationStatus,
  DISCLOSURE_COLLECTIONS,
  type AuthorizationStatusValue,
} from "./constants";

export type LoadedAuthorization = {
  authorizationId: string;
  assistanceRequestId: string;
  teenUid: string;
  orgId: string;
  targetHospitalOrgId: string;
  purposeCode: string;
  requestedCategories: string[];
  authorizedCategories: string[];
  status: AuthorizationStatusValue;
  decisionAuthority: string;
  otherEssentialJustification?: string;
  validUntil?: Date;
  referralThreadId?: string;
};

export async function loadAuthorization(
  db: Firestore,
  authorizationId: string,
): Promise<LoadedAuthorization> {
  const snap = await db
    .collection(DISCLOSURE_COLLECTIONS.disclosureAuthorizations)
    .doc(authorizationId)
    .get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Disclosure authorization not found.");
  }
  const data = snap.data()!;
  return parseAuthorizationDoc(authorizationId, data);
}

export function parseAuthorizationDoc(
  authorizationId: string,
  data: FirebaseFirestore.DocumentData,
): LoadedAuthorization {
  const status = data.status as AuthorizationStatusValue;
  return {
    authorizationId,
    assistanceRequestId: String(data.assistanceRequestId ?? ""),
    teenUid: String(data.teenUid ?? ""),
    orgId: String(data.orgId ?? ""),
    targetHospitalOrgId: String(data.targetHospitalOrgId ?? ""),
    purposeCode: String(data.purposeCode ?? ""),
    requestedCategories: Array.isArray(data.requestedCategories)
      ? data.requestedCategories.map(String)
      : [],
    authorizedCategories: Array.isArray(data.authorizedCategories)
      ? data.authorizedCategories.map(String)
      : [],
    status,
    decisionAuthority: String(data.decisionAuthority ?? ""),
    otherEssentialJustification:
      typeof data.otherEssentialJustification === "string"
        ? data.otherEssentialJustification
        : undefined,
    validUntil:
      data.validUntil?.toDate instanceof Function
        ? data.validUntil.toDate()
        : undefined,
    referralThreadId:
      typeof data.referralThreadId === "string" ? data.referralThreadId : undefined,
  };
}

export function assertAuthorizationActiveForDisclosure(
  auth: LoadedAuthorization,
  assistanceRequestId: string,
  targetHospitalOrgId: string,
  options?: { linkedThreadId?: string },
): void {
  if (auth.assistanceRequestId !== assistanceRequestId) {
    throw new HttpsError(
      "failed-precondition",
      "Authorization does not match this assistance request.",
    );
  }
  if (auth.targetHospitalOrgId !== targetHospitalOrgId) {
    throw new HttpsError(
      "failed-precondition",
      "Authorization does not match the target hospital.",
    );
  }
  if (auth.status !== AuthorizationStatus.approved) {
    throw new HttpsError(
      "failed-precondition",
      "Disclosure authorization is not approved.",
    );
  }
  if (auth.validUntil && auth.validUntil.getTime() < Date.now()) {
    throw new HttpsError(
      "failed-precondition",
      "Disclosure authorization has expired.",
    );
  }
  if (auth.referralThreadId) {
    const linked = options?.linkedThreadId;
    if (!linked || auth.referralThreadId !== linked) {
      throw new HttpsError(
        "failed-precondition",
        "Disclosure authorization is linked to another referral.",
      );
    }
  }
}

export function assertAuthorizationAvailableForNewReferral(
  auth: LoadedAuthorization,
  assistanceRequestId: string,
  targetHospitalOrgId: string,
): void {
  assertAuthorizationActiveForDisclosure(auth, assistanceRequestId, targetHospitalOrgId);
  if (auth.referralThreadId) {
    throw new HttpsError(
      "failed-precondition",
      "Disclosure authorization was already consumed by a referral.",
    );
  }
}

export function assertCategoriesSubset(
  requested: readonly string[],
  authorized: readonly string[],
): void {
  for (const code of requested) {
    if (!authorized.includes(code)) {
      throw new HttpsError(
        "failed-precondition",
        `Category ${code} is not authorized for disclosure.`,
      );
    }
  }
}
