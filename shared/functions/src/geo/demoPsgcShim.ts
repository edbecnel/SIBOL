/**
 * Prototype-only bridge: maps official PSA barangay codes to seeded demo organizations
 * when SIBOL_ALLOW_DEMO_IDENTITY=true. Not used in production.
 */
export const DEMO_PSGC_BARANGAY_TO_ORG: Readonly<Record<string, string>> = {
  /** Barangay 3 (Poblacion), Balingasag — teen routing label via barangay03. */
  "1004302022": "barangay03",
};
