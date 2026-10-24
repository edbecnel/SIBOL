/** Closed capability vocabulary (server-assigned only). */
export const CAPABILITIES = Object.freeze({
  ORG_MANAGE_MEMBERS: "org.manage_members",
  ORG_MANAGE_ROLES: "org.manage_roles",
  CASE_READ: "case.read",
  CASE_WRITE: "case.write",
  REPORT_SUBMIT: "report.submit",
  COORDINATION_BARANGAY: "coordination.barangay",
  COORDINATION_HOSPITAL: "coordination.hospital",
});

export const ALL_CAPABILITIES = Object.freeze(Object.values(CAPABILITIES));

const ADMIN_CAPS = new Set([
  CAPABILITIES.ORG_MANAGE_MEMBERS,
  CAPABILITIES.ORG_MANAGE_ROLES,
]);

const CASE_CAPS = new Set([CAPABILITIES.CASE_READ, CAPABILITIES.CASE_WRITE]);

export function isKnownCapability(value) {
  return typeof value === "string" && ALL_CAPABILITIES.includes(value);
}

export function validateCapabilityList(capabilities) {
  if (!Array.isArray(capabilities)) {
    return ["capabilities must be an array"];
  }
  const errors = [];
  const seen = new Set();
  for (const cap of capabilities) {
    if (!isKnownCapability(cap)) {
      errors.push(`unknown capability: ${cap}`);
    }
    if (seen.has(cap)) {
      errors.push(`duplicate capability: ${cap}`);
    }
    seen.add(cap);
  }
  return errors;
}

/** Administrative caps do not imply case access (DEC-008 / PA #7). */
export function adminImpliesCaseAccess(capabilities) {
  const caps = new Set(capabilities ?? []);
  const hasAdmin = [...ADMIN_CAPS].some((c) => caps.has(c));
  const hasCase = [...CASE_CAPS].some((c) => caps.has(c));
  return hasAdmin && hasCase;
}

export function hasCapability(capabilities, required) {
  if (!Array.isArray(capabilities)) {
    return false;
  }
  return capabilities.includes(required);
}
