/** Canonical demonstration organization identifiers (immutable). */
export const DEMO_BARANGAY_ORG_ID = "barangay03";
export const DEMO_HOSPITAL_ORG_ID = "hospital01";

/** Secondary barangay for cross-org isolation tests (not a production demo org). */
export const DEMO_OTHER_BARANGAY_ORG_ID = "barangay99";

/**
 * Organization ID validation (REG / INT-001-AMEND-001).
 *
 * - Case-sensitive, stable when organization names change.
 * - Must not contain "/" (path injection) or "__" (membership ID separator).
 * - Alphanumeric plus underscore and hyphen; 1–128 characters.
 * - Accepts canonical demo IDs and server-generated Firestore document IDs.
 */
export const ORG_ID_MAX_LENGTH = 128;

const ORG_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]*$/;

export function isValidOrgId(orgId) {
  if (typeof orgId !== "string") {
    return false;
  }
  if (!orgId.length || orgId.length > ORG_ID_MAX_LENGTH) {
    return false;
  }
  if (orgId === "." || orgId === "..") {
    return false;
  }
  if (orgId.includes("__")) {
    return false;
  }
  if (orgId.includes("/")) {
    return false;
  }
  return ORG_ID_PATTERN.test(orgId);
}
