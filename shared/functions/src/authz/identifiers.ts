const ORG_ID_PATTERN = /^org[0-9A-Za-z]{22}$/;
const FIREBASE_UID_PATTERN = /^[A-Za-z0-9]{20,128}$/;
const MEMBERSHIP_SEPARATOR = "__";

export function isValidOrgId(orgId: string): boolean {
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
