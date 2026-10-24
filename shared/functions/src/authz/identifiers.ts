const ORG_ID_MAX_LENGTH = 128;
const ORG_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_-]*$/;
const FIREBASE_UID_PATTERN = /^[A-Za-z0-9]{20,128}$/;
const MEMBERSHIP_SEPARATOR = "__";

export function isValidOrgId(orgId: string): boolean {
  if (typeof orgId !== "string") {
    return false;
  }
  if (!orgId.length || orgId.length > ORG_ID_MAX_LENGTH) {
    return false;
  }
  if (orgId === "." || orgId === "..") {
    return false;
  }
  if (orgId.includes(MEMBERSHIP_SEPARATOR) || orgId.includes("/")) {
    return false;
  }
  return ORG_ID_PATTERN.test(orgId);
}

export function isValidAccountUid(accountUid: string): boolean {
  return FIREBASE_UID_PATTERN.test(accountUid);
}

export function membershipIdFor(orgId: string, accountUid: string): string {
  if (!isValidOrgId(orgId)) {
    throw new Error(`invalid orgId: ${orgId}`);
  }
  if (!isValidAccountUid(accountUid)) {
    throw new Error(`invalid accountUid: ${accountUid}`);
  }
  if (orgId.includes(MEMBERSHIP_SEPARATOR)) {
    throw new Error("orgId must not contain membership separator");
  }
  return `mbr_${orgId}${MEMBERSHIP_SEPARATOR}${accountUid}`;
}
