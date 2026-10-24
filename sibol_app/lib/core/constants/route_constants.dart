abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const accountNotProvisioned = '/account-not-provisioned';
  static const passwordReset = '/password-reset';
  static const teenRegister = '/teen-register';
  static const teenRegisterVerifyEmail = '/teen-register/verify-email';
  static const teenRegisterComplete = '/teen-register/complete';
  static const teenHome = '/teen';
  static const teenAssistanceSegment = 'assistance';

  static const teenAssistanceList = '$teenHome/$teenAssistanceSegment';
  static const teenAssistanceNew = '$teenHome/$teenAssistanceSegment/new';

  static String teenAssistanceDetail(String requestId) =>
      '$teenHome/$teenAssistanceSegment/$requestId';
  static const barangayHome = '/barangay';
  static const barangayIncomingRequestsSegment = 'incoming-requests';

  static const barangayIncomingRequests =
      '$barangayHome/$barangayIncomingRequestsSegment';

  static String barangayIncomingRequestDetail(String requestId) =>
      '$barangayHome/$barangayIncomingRequestsSegment/$requestId';

  static String barangayCoordinationReferral(String assistanceRequestId) =>
      '$barangayHome/$barangayIncomingRequestsSegment/$assistanceRequestId/coordination-referral';

  static const barangayCaseSegment = 'cases';

  static String barangayCaseDetail(String caseId) =>
      '$barangayHome/$barangayCaseSegment/$caseId';

  static const barangayCaseCreate =
      '$barangayHome/$barangayCaseSegment/new';

  static String barangayCaseEdit(String caseId) =>
      '$barangayHome/$barangayCaseSegment/$caseId/edit';

  static const mophHome = '/moph';
  static const mophCoordinationSegment = 'coordinations';
  static const mophReportsSegment = 'reports';

  static String mophCoordinationDetail(String threadId) =>
      '$mophHome/$mophCoordinationSegment/$threadId';

  static String mophReportDetail(String reportId) =>
      '$mophHome/$mophReportsSegment/$reportId';

  static const barangaySubmitReport = '$barangayHome/reports/submit';
  static const barangaySubmittedReportsSegment = 'submitted-reports';

  static const barangaySubmittedReports =
      '$barangayHome/$barangaySubmittedReportsSegment';

  static String barangayReportReceipt(String reportId) =>
      '$barangayHome/$barangaySubmittedReportsSegment/$reportId';

  static const barangaySubmittedReferralsSegment = 'submitted-referrals';

  static const barangaySubmittedReferrals =
      '$barangayHome/$barangaySubmittedReferralsSegment';

  static String barangaySubmittedReferralDetail(String threadId) =>
      '$barangayHome/$barangaySubmittedReferralsSegment/$threadId';

  static const settings = '/settings';
  static const unauthorized = '/unauthorized';

  static const centralAdminOrganizations = '/admin/organizations';
  static const centralAdminCreateOrganization = '/admin/organizations/new';

  static String centralAdminOrganizationDetail(String orgId) =>
      '/admin/organizations/$orgId';

  static String orgAdminStaff(String orgId) => '/admin/org/$orgId/staff';

  static String orgAdminInvitations(String orgId) =>
      '/admin/org/$orgId/staff/invitations';

  static const myInvitations = '/admin/my-invitations';
}
