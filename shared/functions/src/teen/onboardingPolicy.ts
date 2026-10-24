/**
 * Provisional teen onboarding policy (PO decisions pending — REG-C).
 * Defaults preserve existing demo workflows (no new email-verification gate).
 */
export const TEEN_ONBOARDING_POLICY = {
  /** When true, regRegisterTeenAccount rejects unverified Auth emails. */
  requireEmailVerificationBeforeProfile: false,
  /**
   * When true, teen accounts receive onboardingStatus pending_email_verification
   * and assistance callables/rules may deny until verified (Flutter gates match).
   */
  requireEmailVerificationBeforeAssistance: false,
  privacyNoticeVersion: "2026-provisional-reg-c",
} as const;

export type TeenOnboardingStatus =
  | "complete"
  | "pending_email_verification"
  | "profile_incomplete";

export function resolveTeenOnboardingStatus(
  emailVerified: boolean,
): TeenOnboardingStatus {
  if (
    TEEN_ONBOARDING_POLICY.requireEmailVerificationBeforeAssistance &&
    !emailVerified
  ) {
    return "pending_email_verification";
  }
  return "complete";
}
