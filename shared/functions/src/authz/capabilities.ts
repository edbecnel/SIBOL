export const CAPABILITIES = {
  ORG_MANAGE_MEMBERS: "org.manage_members",
  ORG_MANAGE_ROLES: "org.manage_roles",
  CASE_READ: "case.read",
  CASE_WRITE: "case.write",
  REPORT_SUBMIT: "report.submit",
  COORDINATION_BARANGAY: "coordination.barangay",
  COORDINATION_HOSPITAL: "coordination.hospital",
} as const;

export type Capability = (typeof CAPABILITIES)[keyof typeof CAPABILITIES];

const ALL: readonly string[] = Object.values(CAPABILITIES);

export function isKnownCapability(value: string): boolean {
  return ALL.includes(value);
}

export function hasCapability(
  capabilities: readonly string[] | undefined,
  required: Capability,
): boolean {
  return Array.isArray(capabilities) && capabilities.includes(required);
}
