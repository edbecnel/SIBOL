import { Capability, hasCapability } from "./capabilities";
import { isValidOrgId, membershipIdFor } from "./identifiers";

export type AccountDoc = {
  active?: boolean;
  isCentralAdmin?: boolean;
};

export type OrganizationDoc = {
  status?: string;
};

export type MembershipDoc = {
  orgId?: string;
  accountUid?: string;
  status?: string;
  capabilities?: string[];
};

export class AuthzError extends Error {
  constructor(
    message: string,
    readonly code:
      | "unauthenticated"
      | "permission-denied"
      | "failed-precondition"
      | "invalid-argument" = "permission-denied",
  ) {
    super(message);
    this.name = "AuthzError";
  }
}

export function assertAuthenticated(authUid: string | undefined): string {
  if (!authUid) {
    throw new AuthzError("Sign in required.", "unauthenticated");
  }
  return authUid;
}

export function assertActiveAccount(account: AccountDoc | undefined): void {
  if (!account || account.active !== true) {
    throw new AuthzError("Account is not active.", "permission-denied");
  }
}

export function assertActiveOrganization(org: OrganizationDoc | undefined): void {
  if (!org || org.status !== "active") {
    throw new AuthzError("Organization is not active.", "permission-denied");
  }
}

export function assertActiveMembership(
  membership: MembershipDoc | undefined,
  orgId: string,
  accountUid: string,
): void {
  if (!membership) {
    throw new AuthzError("Membership not found.", "permission-denied");
  }
  if (membership.status !== "active") {
    throw new AuthzError("Membership is not active.", "permission-denied");
  }
  if (membership.orgId !== orgId || membership.accountUid !== accountUid) {
    throw new AuthzError("Membership scope mismatch.", "permission-denied");
  }
}

export function assertContextOrgId(contextOrgId: unknown, resourceOrgId: string): void {
  if (typeof contextOrgId !== "string" || !isValidOrgId(contextOrgId)) {
    throw new AuthzError("contextOrgId is required.", "invalid-argument");
  }
  if (contextOrgId !== resourceOrgId) {
    throw new AuthzError("contextOrgId does not match resource org.", "permission-denied");
  }
}

export function assertCapability(
  membership: MembershipDoc,
  required: Capability,
): void {
  if (!hasCapability(membership.capabilities, required)) {
    throw new AuthzError(`Missing capability: ${required}`, "permission-denied");
  }
}

export function expectedMembershipId(orgId: string, accountUid: string): string {
  return membershipIdFor(orgId, accountUid);
}
