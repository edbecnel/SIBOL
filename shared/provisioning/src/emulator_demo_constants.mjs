import {
  DEMO_ASSIGNED_BARANGAY,
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_ORG_ID,
} from "./constants.mjs";

/** Fictional demonstration identities (emulator only). */
export const EMULATOR_DEMO_USER_BLUEPRINTS = [
  {
    key: "central",
    email: "central.admin@sibol.local",
    role: "barangay",
    displayName: "Demo Central Administrator",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_CENTRAL"],
    isCentralAdmin: true,
    membership: null,
  },
  {
    key: "barangay_org_admin",
    email: "barangay.org.admin@sibol.local",
    role: "barangay",
    displayName: "Demo Barangay Org Administrator",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_BARANGAY_ORG_ADMIN"],
    membership: "barangay_org_admin",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
  {
    key: "barangay_staff",
    email: "barangay.demo@sibol.local",
    role: "barangay",
    displayName: "Demo BNS User",
    passwordEnvVars: [
      "SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF",
      "SIBOL_DEMO_PASSWORD_BARANGAY",
    ],
    membership: "barangay_staff",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
  {
    key: "barangay_backup_admin",
    email: "backup.barangay.admin@sibol.local",
    role: "barangay",
    displayName: "Demo Backup Barangay Org Admin",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_BACKUP_BARANGAY_ORG_ADMIN"],
    membership: "barangay_org_admin",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
  {
    key: "moph_org_admin",
    email: "moph.org.admin@sibol.local",
    role: "moph",
    displayName: "Demo MOPH Org Administrator",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_MOPH_ORG_ADMIN"],
    membership: "moph_org_admin",
  },
  {
    key: "moph_staff",
    email: "moph.demo@sibol.local",
    role: "moph",
    displayName: "Demo MOPH User",
    passwordEnvVars: [
      "SIBOL_EMULATOR_PASSWORD_MOPH_STAFF",
      "SIBOL_DEMO_PASSWORD_MOPH",
    ],
    membership: "moph_staff",
  },
  {
    key: "teen",
    email: "teen.demo@sibol.local",
    role: "teen",
    displayName: "Demo Teen User",
    passwordEnvVars: ["SIBOL_EMULATOR_PASSWORD_TEEN", "SIBOL_DEMO_PASSWORD_TEEN"],
    membership: "teen",
    assignedBarangay: DEMO_ASSIGNED_BARANGAY,
  },
];

export const EMULATOR_DEMO_ASSISTANCE_INBOX_ID = "demo-assist-inbox-001";

export { DEMO_BARANGAY_ORG_ID, DEMO_HOSPITAL_ORG_ID, DEMO_ASSIGNED_BARANGAY };
