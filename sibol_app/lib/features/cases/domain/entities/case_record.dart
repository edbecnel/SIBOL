import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_contact_validation.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

class CaseRecord extends Equatable {
  const CaseRecord({
    required this.caseId,
    required this.demoName,
    required this.age,
    required this.barangay,
    required this.orgId,
    required this.caseStatus,
    required this.registeredAt,
    this.nextFollowUpAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.reportStatus = ReportStatus.notSubmitted,
    this.subjectKind,
    this.caseCompleteness,
    this.fullName = '',
    this.dateOfBirth,
    this.contactEmail,
    this.contactPhone,
    this.parentGuardianContact,
    this.teenUid,
    this.linkedAccountEmail,
    this.identityLinkedAt,
    this.teenProfileSyncedAt,
    this.assistanceRequestId,
    this.assignedCoordinatorUid,
  });

  final String caseId;
  /// Legacy Firestore field; kept in sync with [fullName] on write when set.
  final String demoName;
  /// Stored age; prefer [effectiveAge] when DOB is present.
  final int age;
  final String barangay;
  final String orgId;
  final CaseStatus caseStatus;
  final DateTime registeredAt;
  final DateTime? nextFollowUpAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportStatus reportStatus;

  final CaseSubjectKind? subjectKind;
  final CaseCompleteness? caseCompleteness;
  final String fullName;
  final String? dateOfBirth;
  final String? contactEmail;
  final String? contactPhone;
  final String? parentGuardianContact;
  final String? teenUid;
  /// Firebase Authentication email snapshot for registered cases (not contact email).
  final String? linkedAccountEmail;
  final DateTime? identityLinkedAt;
  final DateTime? teenProfileSyncedAt;
  final String? assistanceRequestId;
  final String? assignedCoordinatorUid;

  bool get isAssistanceLinkedCase =>
      assistanceRequestId != null && assistanceRequestId!.trim().isNotEmpty;

  String get displayFullName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    return demoName.trim();
  }

  CaseSubjectKind get resolvedSubjectKind =>
      CaseSubjectKind.resolveStored(subjectKind?.firestoreValue);

  bool get hasDateOfBirth => CaseDateOfBirth.parse(dateOfBirth) != null;

  bool get hasContactMethod => CaseContactValidation.hasContactMethod(
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      );

  bool get isLegacyAgeOnlyDocument =>
      caseCompleteness == null &&
      subjectKind == null &&
      !hasDateOfBirth &&
      !hasContactMethod;

  CaseCompleteness get completeness => CaseCompleteness.inferFromRecord(
        stored: caseCompleteness?.firestoreValue,
        hasDateOfBirth: hasDateOfBirth,
        hasContactMethod: hasContactMethod,
        hasFullName: displayFullName.length >= 2,
        isLegacyAgeOnlyDocument: isLegacyAgeOnlyDocument,
      );

  int get effectiveAge {
    final dob = CaseDateOfBirth.parse(dateOfBirth);
    if (dob != null) {
      return CaseDateOfBirth.currentAge(dob);
    }
    return age;
  }

  int ageOn(DateTime eventDate) {
    final dob = CaseDateOfBirth.parse(dateOfBirth);
    if (dob != null) {
      return CaseDateOfBirth.ageOnDate(
        dob,
        DateTime(eventDate.year, eventDate.month, eventDate.day),
      );
    }
    return age;
  }

  bool get countsTowardReporting =>
      completeness != CaseCompleteness.draft;

  @override
  List<Object?> get props => [
        caseId,
        demoName,
        age,
        barangay,
        orgId,
        caseStatus,
        registeredAt,
        nextFollowUpAt,
        notes,
        createdAt,
        updatedAt,
        reportStatus,
        subjectKind,
        caseCompleteness,
        fullName,
        dateOfBirth,
        contactEmail,
        contactPhone,
        parentGuardianContact,
        teenUid,
        linkedAccountEmail,
        identityLinkedAt,
        teenProfileSyncedAt,
        assistanceRequestId,
        assignedCoordinatorUid,
      ];
}
