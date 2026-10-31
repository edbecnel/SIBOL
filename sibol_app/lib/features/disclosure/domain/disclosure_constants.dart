/// Legal activation gate — must match server `SIBOL_DISCLOSURE_LEGAL_GATE`.
abstract final class DisclosureLegalPolicy {
  static const identifyingDisclosureActivated = bool.fromEnvironment(
    'SIBOL_DISCLOSURE_LEGAL_GATE',
    defaultValue: false,
  );
}

abstract final class DisclosureCategoryCodes {
  static const legalName = 'legal_name';
  static const dateOfBirthOrAge = 'date_of_birth_or_age';
  static const contactPhone = 'contact_phone';
  static const contactEmail = 'contact_email';
  static const otherEssential = 'other_essential';

  static const all = [
    legalName,
    dateOfBirthOrAge,
    contactPhone,
    contactEmail,
    otherEssential,
  ];
}

abstract final class ReferralPurposeCodes {
  static const hospitalCoordination = 'hospital_coordination';
  static const followUpSupport = 'follow_up_support';
  static const careNavigation = 'care_navigation';
}

abstract final class CoordinationNeedCodes {
  static const scheduleCoordination = 'schedule_coordination';
  static const assessServiceNeed = 'assess_service_need';
  static const arrangeFollowUp = 'arrange_follow_up';
}

abstract final class ResponseTemplateCodes {
  static const administrativeUpdate = 'administrative_update';
  static const schedulingConfirmation = 'scheduling_confirmation';
  static const categoryDisclosure = 'category_disclosure';
}
