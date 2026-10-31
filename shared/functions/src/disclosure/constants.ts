export const DISCLOSURE_COLLECTIONS = {
  disclosureAuthorizations: "disclosureAuthorizations",
} as const;

export const DISCLOSURE_NOTICE_VERSION = "2026-consent-pending-legal";
export const DISCLOSURE_CATEGORY_CATALOG_VERSION = "2026-consent-v1";

export const AuthorizationStatus = {
  requested: "requested",
  approved: "approved",
  declined: "declined",
  withdrawn: "withdrawn",
  expired: "expired",
  superseded: "superseded",
} as const;

export type AuthorizationStatusValue =
  (typeof AuthorizationStatus)[keyof typeof AuthorizationStatus];

export const DecisionAuthority = {
  teenSelf: "teen_self",
  guardianVerified: "guardian_verified",
  otherLegalAuthority: "other_legal_authority",
  pendingVerification: "pending_verification",
} as const;

export const DisclosureMode = {
  minimum: "minimum",
  authorized: "authorized",
} as const;
