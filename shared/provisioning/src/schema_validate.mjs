const CASE_STATUSES = new Set([
  "active",
  "followUpScheduled",
  "followUpCompleted",
  "closed",
]);

const REPORT_STATUSES = new Set([
  "notSubmitted",
  "pendingSubmit",
  "submitted",
  "submitFailed",
]);

/**
 * Lightweight validation aligned with shared/contracts/case_record.schema.json
 * (Firestore Timestamps are validated separately at write time).
 */
export function validateFictionalCasePayload(casePayload) {
  const errors = [];
  if (!casePayload || typeof casePayload !== "object") {
    return ["case payload must be an object"];
  }

  const required = [
    "demoName",
    "age",
    "barangay",
    "caseStatus",
    "registeredAt",
    "createdAt",
    "updatedAt",
    "reportStatus",
  ];
  for (const key of required) {
    if (casePayload[key] === undefined || casePayload[key] === null) {
      errors.push(`missing required field: ${key}`);
    }
  }

  if (typeof casePayload.demoName !== "string" || casePayload.demoName.length < 2) {
    errors.push("demoName must be a string with minLength 2");
  }
  if (
    !Number.isInteger(casePayload.age) ||
    casePayload.age < 13 ||
    casePayload.age > 19
  ) {
    errors.push("age must be an integer between 13 and 19");
  }
  if (typeof casePayload.barangay !== "string" || !casePayload.barangay.length) {
    errors.push("barangay must be a non-empty string");
  }
  if (!CASE_STATUSES.has(casePayload.caseStatus)) {
    errors.push(`invalid caseStatus: ${casePayload.caseStatus}`);
  }
  if (!REPORT_STATUSES.has(casePayload.reportStatus)) {
    errors.push(`invalid reportStatus: ${casePayload.reportStatus}`);
  }

  for (const key of ["registeredAt", "createdAt", "updatedAt"]) {
    if (casePayload[key] && Number.isNaN(Date.parse(casePayload[key]))) {
      errors.push(`${key} must be ISO date-time`);
    }
  }
  if (
    casePayload.nextFollowUpAt &&
    Number.isNaN(Date.parse(casePayload.nextFollowUpAt))
  ) {
    errors.push("nextFollowUpAt must be ISO date-time when present");
  }

  const allowed = new Set([
    ...required,
    "nextFollowUpAt",
    "notes",
  ]);
  for (const key of Object.keys(casePayload)) {
    if (!allowed.has(key)) {
      errors.push(`unexpected property: ${key}`);
    }
  }

  return errors;
}

export function validateDemoUserSpec(user) {
  const errors = [];
  if (!user.email?.endsWith("@sibol.local")) {
    errors.push(`email must use @sibol.local domain: ${user.email}`);
  }
  if (!["teen", "barangay", "moph"].includes(user.role)) {
    errors.push(`invalid role: ${user.role}`);
  }
  return errors;
}
