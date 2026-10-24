/** Coordinator-approved demonstration Firebase project (confirm flag must match). */
export const EXPECTED_DEMO_PROJECT_ID = "sibol-286d0";

/** Demo barangay organization id (matches shared/migration demo mapping). */
export const DEMO_BARANGAY_ORG_ID = "org0123456789012345678901";
export const DEMO_HOSPITAL_ORG_ID = "org2222222222222222222222";
export const DEMO_HOSPITAL_NAME = "Misamis Oriental Provincial Hospital";

/** Demo site for teen assistance routing (matches seeded cases). */
export const DEMO_ASSIGNED_BARANGAY = "Barangay Tres, Balingasag";

export const DEMO_USER_SPECS = [
  {
    email: "teen.demo@sibol.local",
    role: "teen",
    displayName: "Demo Teen User",
    passwordEnvVar: "SIBOL_DEMO_PASSWORD_TEEN",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
  {
    email: "barangay.demo@sibol.local",
    role: "barangay",
    displayName: "Demo BNS User",
    passwordEnvVar: "SIBOL_DEMO_PASSWORD_BARANGAY",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
  {
    email: "moph.demo@sibol.local",
    role: "moph",
    displayName: "Demo MOPH User",
    passwordEnvVar: "SIBOL_DEMO_PASSWORD_MOPH",
  },
];

export const DEMO_CASE_IDS = [
  "demo-case-001",
  "demo-case-002",
  "demo-case-003",
  "demo-case-004",
  "demo-case-005",
];

export const CANONICAL_ROLES = new Set(["teen", "barangay", "moph"]);
