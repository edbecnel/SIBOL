import { DEMO_CASE_IDS } from "./constants.mjs";

const FICTIONAL_NAMES = [
  "Ana Demo Reyes",
  "Bea Demo Santos",
  "Cara Demo Lim",
  "Dina Demo Cruz",
  "Ella Demo Neri",
];

const STATUSES = [
  "active",
  "followUpScheduled",
  "followUpCompleted",
  "active",
  "closed",
];

const BARANGAY = "Barangay Tres, Balingasag";

/**
 * Build plain (non-Timestamp) case payloads for schema validation and dry-run reporting.
 */
export function buildDemoCasePlans(referenceDate = new Date("2026-10-01T08:00:00.000Z")) {
  return DEMO_CASE_IDS.map((caseId, i) => {
    const registeredAt = new Date(
      Date.UTC(
        referenceDate.getUTCFullYear(),
        referenceDate.getUTCMonth(),
        referenceDate.getUTCDate() + i,
        8,
        0,
        0,
      ),
    );
    const nextFollowUpAt = new Date(
      Date.UTC(2026, 10, 5 + i, 9, 0, 0),
    );
    const caseStatus = STATUSES[i];
    const followUpCompleted = caseStatus === "followUpCompleted";

    return {
      caseId,
      case: {
        demoName: FICTIONAL_NAMES[i],
        age: 15 + (i % 4),
        barangay: BARANGAY,
        caseStatus,
        registeredAt: registeredAt.toISOString(),
        nextFollowUpAt: nextFollowUpAt.toISOString(),
        notes: "Fictional demonstration notes only.",
        createdAt: referenceDate.toISOString(),
        updatedAt: referenceDate.toISOString(),
        reportStatus: "notSubmitted",
      },
      followUp: {
        followUpId: `demo-followup-${caseId}`,
        caseId,
        scheduledAt: nextFollowUpAt.toISOString(),
        completedAt: followUpCompleted
          ? new Date(Date.UTC(2026, 10, 6 + i, 10, 0, 0)).toISOString()
          : null,
        status: followUpCompleted ? "completed" : "scheduled",
        notes: "Fictional follow-up activity.",
      },
    };
  });
}
