export function minimumStructuredReferral(assistanceRequestId) {
  return {
    assistanceRequestId,
    disclosureMode: "minimum",
    referralPurposeCode: "hospital_coordination",
    coordinationNeedCodes: ["schedule_coordination"],
  };
}

export function authorizedStructuredReferral(assistanceRequestId, authorizationId) {
  return {
    assistanceRequestId,
    disclosureMode: "authorized",
    authorizationId,
    referralPurposeCode: "hospital_coordination",
    coordinationNeedCodes: ["assess_service_need"],
  };
}

export function structuredInformationResponse(threadId, options = {}) {
  return {
    threadId,
    responseTemplateCode: options.template ?? "administrative_update",
    disclosedCategoryCodes: options.categories ?? [],
    ...(options.authorizationId
      ? { authorizationId: options.authorizationId }
      : {}),
  };
}
