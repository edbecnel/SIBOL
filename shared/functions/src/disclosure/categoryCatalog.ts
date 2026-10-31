import { HttpsError } from "firebase-functions/v2/https";

export const DisclosureCategoryCodes = {
  legalName: "legal_name",
  dateOfBirthOrAge: "date_of_birth_or_age",
  contactPhone: "contact_phone",
  contactEmail: "contact_email",
  otherEssential: "other_essential",
} as const;

const ALL_CATEGORY_CODES = new Set(Object.values(DisclosureCategoryCodes));

export const ReferralPurposeCodes = {
  hospitalCoordination: "hospital_coordination",
  followUpSupport: "follow_up_support",
  careNavigation: "care_navigation",
} as const;

export const CoordinationNeedCodes = {
  scheduleCoordination: "schedule_coordination",
  assessServiceNeed: "assess_service_need",
  arrangeFollowUp: "arrange_follow_up",
} as const;

export const ResponseTemplateCodes = {
  administrativeUpdate: "administrative_update",
  schedulingConfirmation: "scheduling_confirmation",
  categoryDisclosure: "category_disclosure",
} as const;

const PURPOSE_SET = new Set(Object.values(ReferralPurposeCodes));
const NEED_SET = new Set(Object.values(CoordinationNeedCodes));
const RESPONSE_TEMPLATE_SET = new Set(Object.values(ResponseTemplateCodes));

export function validateCategoryCodes(raw: unknown, field: string): string[] {
  if (!Array.isArray(raw) || raw.length < 1) {
    throw new HttpsError(
      "invalid-argument",
      `${field} must be a non-empty array of category codes.`,
    );
  }
  const out: string[] = [];
  for (const item of raw) {
    if (typeof item !== "string" || !ALL_CATEGORY_CODES.has(item as never)) {
      throw new HttpsError(
        "invalid-argument",
        `${field} contains an invalid category code.`,
      );
    }
    if (item === DisclosureCategoryCodes.otherEssential && raw.length > 1) {
      throw new HttpsError(
        "invalid-argument",
        "other_essential must be requested alone.",
      );
    }
    out.push(item);
  }
  return [...new Set(out)];
}

export function validatePurposeCode(raw: unknown): string {
  if (typeof raw !== "string" || !PURPOSE_SET.has(raw as never)) {
    throw new HttpsError("invalid-argument", "referralPurposeCode is invalid.");
  }
  return raw;
}

export function validateCoordinationNeedCodes(raw: unknown): string[] {
  if (!Array.isArray(raw) || raw.length < 1) {
    throw new HttpsError(
      "invalid-argument",
      "coordinationNeedCodes must be a non-empty array.",
    );
  }
  const out: string[] = [];
  for (const item of raw) {
    if (typeof item !== "string" || !NEED_SET.has(item as never)) {
      throw new HttpsError(
        "invalid-argument",
        "coordinationNeedCodes contains an invalid code.",
      );
    }
    out.push(item);
  }
  return [...new Set(out)];
}

export function validateResponseTemplateCode(raw: unknown): string {
  if (typeof raw !== "string" || !RESPONSE_TEMPLATE_SET.has(raw as never)) {
    throw new HttpsError(
      "invalid-argument",
      "responseTemplateCode is invalid.",
    );
  }
  return raw;
}

/** Reject legacy / bypass fields on coordination payloads (C1, C2, C3). */
export function rejectLegacyFreeTextFields(data: Record<string, unknown>): void {
  const forbidden = [
    "barangayReferralSummary",
    "responseSummary",
    "administrativeNote",
    "note",
    "body",
  ];
  for (const key of forbidden) {
    if (key in data && data[key] !== undefined && data[key] !== null) {
      throw new HttpsError(
        "invalid-argument",
        `Field ${key} is not accepted; use structured coordination fields.`,
      );
    }
  }
}
