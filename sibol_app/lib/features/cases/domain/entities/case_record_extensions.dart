import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

extension CaseRecordCopy on CaseRecord {
  CaseRecord copyWith({
    String? caseId,
    String? demoName,
    int? age,
    String? barangay,
    String? orgId,
    CaseStatus? caseStatus,
    DateTime? registeredAt,
    DateTime? nextFollowUpAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReportStatus? reportStatus,
    CaseSubjectKind? subjectKind,
    CaseCompleteness? caseCompleteness,
    String? fullName,
    String? dateOfBirth,
    String? contactEmail,
    String? contactPhone,
    String? parentGuardianContact,
    String? teenUid,
    String? linkedAccountEmail,
    DateTime? identityLinkedAt,
  }) {
    return CaseRecord(
      caseId: caseId ?? this.caseId,
      demoName: demoName ?? this.demoName,
      age: age ?? this.age,
      barangay: barangay ?? this.barangay,
      orgId: orgId ?? this.orgId,
      caseStatus: caseStatus ?? this.caseStatus,
      registeredAt: registeredAt ?? this.registeredAt,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reportStatus: reportStatus ?? this.reportStatus,
      subjectKind: subjectKind ?? this.subjectKind,
      caseCompleteness: caseCompleteness ?? this.caseCompleteness,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      parentGuardianContact:
          parentGuardianContact ?? this.parentGuardianContact,
      teenUid: teenUid ?? this.teenUid,
      linkedAccountEmail: linkedAccountEmail ?? this.linkedAccountEmail,
      identityLinkedAt: identityLinkedAt ?? this.identityLinkedAt,
    );
  }
}
