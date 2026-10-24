export function allowDemoIdentity(): boolean {
  return process.env.SIBOL_ALLOW_DEMO_IDENTITY === "true";
}

export function allowLegacyTeenOrgBinding(): boolean {
  return process.env.SIBOL_ALLOW_LEGACY_TEEN_ORG_BINDING === "true";
}

export const LEGACY_TEEN_ORG_ALLOWLIST = new Set(["barangay03"]);
