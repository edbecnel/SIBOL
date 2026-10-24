import { isValidOrgId } from "./org_id.mjs";

const MEMBERSHIP_PREFIX = "mbr_";
const MEMBERSHIP_SEPARATOR = "__";

const FIREBASE_UID_PATTERN = /^[A-Za-z0-9]{20,128}$/;

export function isValidAccountUid(accountUid) {
  return typeof accountUid === "string" && FIREBASE_UID_PATTERN.test(accountUid);
}

/**
 * @param {string} orgId
 * @param {string} accountUid
 * @returns {string}
 */
export function membershipIdFor(orgId, accountUid) {
  if (!isValidOrgId(orgId)) {
    throw new Error(`invalid orgId: ${orgId}`);
  }
  if (!isValidAccountUid(accountUid)) {
    throw new Error(`invalid accountUid: ${accountUid}`);
  }
  if (orgId.includes(MEMBERSHIP_SEPARATOR)) {
    throw new Error("orgId must not contain membership separator");
  }
  return `${MEMBERSHIP_PREFIX}${orgId}${MEMBERSHIP_SEPARATOR}${accountUid}`;
}

/**
 * @param {string} membershipId
 * @returns {{ orgId: string, accountUid: string } | null}
 */
export function parseMembershipId(membershipId) {
  if (typeof membershipId !== "string" || !membershipId.startsWith(MEMBERSHIP_PREFIX)) {
    return null;
  }
  const rest = membershipId.slice(MEMBERSHIP_PREFIX.length);
  const sep = rest.indexOf(MEMBERSHIP_SEPARATOR);
  if (sep < 0) {
    return null;
  }
  const orgId = rest.slice(0, sep);
  const accountUid = rest.slice(sep + MEMBERSHIP_SEPARATOR.length);
  if (!isValidOrgId(orgId) || !isValidAccountUid(accountUid)) {
    return null;
  }
  return { orgId, accountUid };
}

export function membershipIdMatchesPayload(membershipId, orgId, accountUid) {
  try {
    return membershipIdFor(orgId, accountUid) === membershipId;
  } catch {
    return false;
  }
}
