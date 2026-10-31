import {
  CoordinationNeedCodes,
  ReferralPurposeCodes,
  ResponseTemplateCodes,
} from "./categoryCatalog";

const PURPOSE_LABELS: Record<string, string> = {
  [ReferralPurposeCodes.hospitalCoordination]:
    "Hospital coordination for adolescent assistance",
  [ReferralPurposeCodes.followUpSupport]: "Follow-up support coordination",
  [ReferralPurposeCodes.careNavigation]: "Care navigation coordination",
};

const NEED_LABELS: Record<string, string> = {
  [CoordinationNeedCodes.scheduleCoordination]: "schedule coordination",
  [CoordinationNeedCodes.assessServiceNeed]: "assess service need",
  [CoordinationNeedCodes.arrangeFollowUp]: "arrange follow-up",
};

export function generateReferralSummaryDescription(
  purposeCode: string,
  needCodes: readonly string[],
): string {
  const purpose = PURPOSE_LABELS[purposeCode] ?? "Barangay coordination referral";
  const needs = needCodes
    .map((c) => NEED_LABELS[c] ?? c)
    .join("; ");
  return (
    `${purpose}. Coordination needs: ${needs}. ` +
    "This referral uses structured minimum-information content; teen narrative and unauthorized identifiers are not included."
  );
}

export function generateInformationResponseDescription(
  templateCode: string,
  includesCategoryDisclosure: boolean,
): string {
  switch (templateCode) {
    case ResponseTemplateCodes.schedulingConfirmation:
      return "Barangay provided a scheduling confirmation for hospital coordination.";
    case ResponseTemplateCodes.categoryDisclosure:
      return includesCategoryDisclosure
        ? "Barangay provided authorized identifying information per recorded disclosure authorization."
        : "Barangay provided structured coordination information.";
    case ResponseTemplateCodes.administrativeUpdate:
    default:
      return "Barangay provided a structured administrative coordination update.";
  }
}
