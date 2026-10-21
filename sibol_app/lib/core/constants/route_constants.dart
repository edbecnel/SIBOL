abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const teenHome = '/teen';
  static const barangayHome = '/barangay';
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
