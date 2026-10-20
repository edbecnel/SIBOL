import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

class CaseRecord extends Equatable {
  const CaseRecord({
    required this.caseId,
    required this.demoName,
    required this.age,
    required this.barangay,
    required this.caseStatus,
    required this.registeredAt,
    this.nextFollowUpAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.reportStatus = ReportStatus.notSubmitted,
  });

  final String caseId;
  final String demoName;
  final int age;
  final String barangay;
  final CaseStatus caseStatus;
  final DateTime registeredAt;
  final DateTime? nextFollowUpAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportStatus reportStatus;

  @override
  List<Object?> get props => [
        caseId,
        demoName,
        age,
        barangay,
        caseStatus,
        registeredAt,
        nextFollowUpAt,
        notes,
        createdAt,
        updatedAt,
        reportStatus,
      ];
}
