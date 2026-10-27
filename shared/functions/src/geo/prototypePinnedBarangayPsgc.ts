import { DEMO_BARANGAY_ORG_ID } from "../reg/constants";

/**
 * Prototype demonstration: official PSA barangay codes mapped to seeded organizations
 * when `organizationIdentityKeys` has not yet been provisioned on live Firebase.
 * Each entry must match a real active `organizations/{orgId}` record.
 */
export const PROTOTYPE_PINNED_BARANGAY_PSGC_TO_ORG: Readonly<Record<string, string>> = {
  /** Barangay 3 (Poblacion), Balingasag, Misamis Oriental — demo org `barangay03`. */
  "1004302022": DEMO_BARANGAY_ORG_ID,
};

export function pinnedOrgIdForBarangayPsgc(psgcBarangayCode: string): string | undefined {
  return PROTOTYPE_PINNED_BARANGAY_PSGC_TO_ORG[psgcBarangayCode];
}
