/** Coordinator-approved demonstration Firebase project (confirm flag must match). */
export const EXPECTED_DEMO_PROJECT_ID = "sibol-286d0";

export const DEMO_USER_SPECS = [
  {
    email: "teen.demo@sibol.local",
    role: "teen",
    displayName: "Demo Teen User",
    passwordEnvVar: "SIBOL_DEMO_PASSWORD_TEEN",
  },
  {
    email: "barangay.demo@sibol.local",
    role: "barangay",
    displayName: "Demo BNS User",
    passwordEnvVar: "SIBOL_DEMO_PASSWORD_BARANGAY",
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
