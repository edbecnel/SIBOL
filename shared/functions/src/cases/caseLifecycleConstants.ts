export const CASE_COLLECTION = "cases";

export const ASSISTANCE_CASE_BINDINGS = "assistanceCaseBindings";

export const CASE_OPEN_IDEMPOTENCY = "caseOpenIdempotency";

export const LIFECYCLE_EVENTS = "lifecycleEvents";

export const CaseLifecycleStatus = {
  open: "open",
  inProgress: "inProgress",
  resolved: "resolved",
  closed: "closed",
} as const;

export type CaseLifecycleStatusValue =
  (typeof CaseLifecycleStatus)[keyof typeof CaseLifecycleStatus];

export const LEGACY_CASE_STATUSES = [
  "active",
  "followUpScheduled",
  "followUpCompleted",
  "closed",
] as const;

export const LifecycleEventType = {
  caseOpened: "case_opened",
  coordinatorAssigned: "coordinator_assigned",
  statusChanged: "status_changed",
  resolved: "resolved",
  closed: "closed",
  reopened: "reopened",
} as const;

export const RESOLUTION_SUMMARY_MIN = 10;
export const RESOLUTION_SUMMARY_MAX = 2000;
export const REOPEN_REASON_MIN = 10;
export const REOPEN_REASON_MAX = 500;
export const CLOSURE_NOTES_MIN = 10;
export const CLOSURE_NOTES_MAX = 2000;
