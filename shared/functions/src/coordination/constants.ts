export const COLLECTIONS = {
  users: "users",
  teenAssistanceRequests: "teenAssistanceRequests",
  caseCoordinationThreads: "caseCoordinationThreads",
  barangayCoordinationRegistry: "barangayCoordinationRegistry",
  teenCoordinationLinks: "teenCoordinationLinks",
} as const;

export const SUMMARY_MIN = 10;
export const SUMMARY_MAX = 2000;

export const OPEN_PHASES = ["referred", "awaitingBarangay", "awaitingMoph"] as const;

export const TEEN_PROGRESS = {
  code: "referred",
  label:
    "Your barangay has referred your assistance request for hospital coordination.",
} as const;
