abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
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

  static const barangayCaseSegment = 'cases';

  static String barangayCaseDetail(String caseId) =>
      '$barangayHome/$barangayCaseSegment/$caseId';

  static const barangayCaseCreate =
      '$barangayHome/$barangayCaseSegment/new';

  static String barangayCaseEdit(String caseId) =>
      '$barangayHome/$barangayCaseSegment/$caseId/edit';

  static const mophHome = '/moph';
  static const settings = '/settings';
  static const unauthorized = '/unauthorized';
}
