export const TEEN_COMM_COLLECTION = "teenAssistanceCommunications";
export const TEEN_COMM_MESSAGES = "messages";
export const TEEN_COMM_IDEMPOTENCY = "teenCommunicationIdempotency";

export const TEEN_COMM_TEMPLATE_VERSION = "2026-11-01";

export const TeenCommTemplateCode = {
  caseWorkStarted: "case_work_started",
  coordinationProgressGeneric: "coordination_progress_generic",
  coordinationProgressCheckUpdates: "coordination_progress_check_updates",
  coordinationOutcomeNeutral: "coordination_outcome_neutral",
  followUpContactBarangay: "follow_up_contact_barangay",
} as const;

export type TeenCommTemplateCodeValue =
  (typeof TeenCommTemplateCode)[keyof typeof TeenCommTemplateCode];

const TEMPLATE_TEXT: Record<TeenCommTemplateCodeValue, string> = {
  [TeenCommTemplateCode.caseWorkStarted]:
    "Your assistance request is being attended to by your Barangay.",
  [TeenCommTemplateCode.coordinationProgressGeneric]:
    "Your Barangay is coordinating the assistance requested. Please check for further updates.",
  [TeenCommTemplateCode.coordinationProgressCheckUpdates]:
    "Your Barangay is coordinating the assistance requested. Please check for further updates.",
  [TeenCommTemplateCode.coordinationOutcomeNeutral]:
    "Your Barangay has an update regarding your assistance request. Please contact your Barangay representative for the next steps.",
  [TeenCommTemplateCode.followUpContactBarangay]:
    "Please contact your Barangay representative for follow-up instructions regarding your assistance request.",
};

export const BARANGAY_SELECTABLE_PROGRESS_TEMPLATES: readonly TeenCommTemplateCodeValue[] =
  [
    TeenCommTemplateCode.coordinationProgressGeneric,
    TeenCommTemplateCode.coordinationProgressCheckUpdates,
  ];

export const BARANGAY_SELECTABLE_FOLLOW_UP_TEMPLATES: readonly TeenCommTemplateCodeValue[] =
  [TeenCommTemplateCode.followUpContactBarangay];

export function teenCommDisplayText(code: TeenCommTemplateCodeValue): string {
  return TEMPLATE_TEXT[code];
}

export function parseTeenCommTemplateCode(raw: unknown): TeenCommTemplateCodeValue {
  if (typeof raw !== "string" || !raw.trim()) {
    throw new Error("templateCode is required.");
  }
  const value = raw.trim() as TeenCommTemplateCodeValue;
  if (!Object.values(TeenCommTemplateCode).includes(value)) {
    throw new Error("templateCode is invalid.");
  }
  return value;
}
