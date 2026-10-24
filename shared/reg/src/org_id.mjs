/** Canonical orgId: "org" + 22 alphanumeric characters (no "__"). */
export const ORG_ID_PATTERN = /^org[0-9A-Za-z]{22}$/;

export const ORG_ID_LENGTH = 25;

export function isValidOrgId(orgId) {
  return typeof orgId === "string" && ORG_ID_PATTERN.test(orgId);
}
