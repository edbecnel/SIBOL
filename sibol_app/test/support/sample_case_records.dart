import 'package:sibol_app/core/constants/demo_org_constants.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

CaseRecord sampleCaseRecord({
  String caseId = 'demo-case-001',
  String demoName = 'Bea Demo Santos',
}) {
  final registered = DateTime(2026, 3, 15);
  return CaseRecord(
    caseId: caseId,
    demoName: demoName,
    age: 17,
    barangay: 'Demo Barangay',
    orgId: DemoOrgConstants.barangay03OrgId,
    caseStatus: CaseStatus.active,
    registeredAt: registered,
    nextFollowUpAt: DateTime(2026, 4, 1, 10),
    notes: 'Fictional demonstration case for academic review.',
    createdAt: registered,
    updatedAt: DateTime(2026, 3, 20, 14, 30),
    reportStatus: ReportStatus.notSubmitted,
  );
}
