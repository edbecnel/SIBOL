import { CAPABILITIES, Capability, hasCapability, isKnownCapability } from "../authz/capabilities";
import { MembershipDoc } from "../authz/assert";
import { AuthzError } from "../authz/assert";

export const ORG_ADMIN_CAPABILITIES: readonly Capability[] = [
  CAPABILITIES.ORG_MANAGE_MEMBERS,
  CAPABILITIES.ORG_MANAGE_ROLES,
];

export const INVITATION_TTL_MS = 7 * 24 * 60 * 60 * 1000;

export function isOrgAdministrator(membership: MembershipDoc | undefined): boolean {
  if (!membership || membership.status !== "active") return false;
  return (
    hasCapability(membership.capabilities, CAPABILITIES.ORG_MANAGE_MEMBERS) &&
    hasCapability(membership.capabilities, CAPABILITIES.ORG_MANAGE_ROLES)
  );
}

export function countActiveOrgAdministrators(
  memberships: MembershipDoc[],
): number {
  return memberships.filter((m) => isOrgAdministrator(m)).length;
}

export function capabilitiesAllowedForOrgType(
  orgType: "barangay" | "hospital",
  capabilities: readonly string[],
): boolean {
  for (const cap of capabilities) {
    if (cap === CAPABILITIES.COORDINATION_BARANGAY && orgType !== "barangay") {
      return false;
    }
    if (cap === CAPABILITIES.COORDINATION_HOSPITAL && orgType !== "hospital") {
      return false;
    }
  }
  return true;
}

export function assertAssignableCapabilities(
  actorIsCentralAdmin: boolean,
  orgType: "barangay" | "hospital",
  capabilities: string[],
): void {
  if (!capabilities.length) {
    throw new AuthzError("At least one capability is required.", "invalid-argument");
  }
  const unique = [...new Set(capabilities)];
  for (const cap of unique) {
    if (!isKnownCapability(cap)) {
      throw new AuthzError(`Unknown capability: ${cap}`, "invalid-argument");
    }
    if (
      !actorIsCentralAdmin &&
      (cap === CAPABILITIES.ORG_MANAGE_MEMBERS ||
        cap === CAPABILITIES.ORG_MANAGE_ROLES)
    ) {
      throw new AuthzError(
        "Organization administrators cannot grant org management capabilities.",
        "permission-denied",
      );
    }
  }
  if (!capabilitiesAllowedForOrgType(orgType, unique)) {
    throw new AuthzError(
      "Capability set is not valid for organization type.",
      "invalid-argument",
    );
  }
}

export function defaultStaffCapabilitiesForOrgType(
  orgType: "barangay" | "hospital",
): Capability[] {
  if (orgType === "barangay") {
    return [
      CAPABILITIES.CASE_READ,
      CAPABILITIES.CASE_WRITE,
      CAPABILITIES.REPORT_SUBMIT,
      CAPABILITIES.COORDINATION_BARANGAY,
    ];
  }
  return [CAPABILITIES.COORDINATION_HOSPITAL];
}
