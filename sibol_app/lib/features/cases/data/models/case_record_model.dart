import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/case_validation.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

class CaseRecordModel {
  CaseRecordModel({
    required this.caseId,
    required this.demoName,
    required this.age,
    required this.barangay,
    required this.orgId,
    required this.caseStatus,
    required this.registeredAt,
    this.nextFollowUpAt,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.reportStatus,
    this.subjectKind,
    this.caseCompleteness,
    this.fullName,
    this.dateOfBirth,
    this.contactEmail,
    this.contactPhone,
    this.parentGuardianContact,
    this.teenUid,
    this.linkedAccountEmail,
    this.identityLinkedAt,
    this.teenProfileSyncedAt,
  });

  final String caseId;
  final String demoName;
  final int age;
  final String barangay;
  final String orgId;
  final String caseStatus;
  final DateTime registeredAt;
  final DateTime? nextFollowUpAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reportStatus;
  final String? subjectKind;
  final String? caseCompleteness;
  final String? fullName;
  final String? dateOfBirth;
  final String? contactEmail;
  final String? contactPhone;
  final String? parentGuardianContact;
  final String? teenUid;
  final String? linkedAccountEmail;
  final DateTime? identityLinkedAt;
  final DateTime? teenProfileSyncedAt;

  factory CaseRecordModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CaseRecordModel(
      caseId: id,
      demoName: data['demoName'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      barangay: data['barangay'] as String? ?? '',
      orgId: data['orgId'] as String? ?? '',
      caseStatus: data['caseStatus'] as String? ?? '',
      registeredAt: _toDate(data['registeredAt']),
      nextFollowUpAt: data['nextFollowUpAt'] == null
          ? null
          : _toDate(data['nextFollowUpAt']),
      notes: data['notes'] as String? ?? '',
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      reportStatus: data['reportStatus'] as String? ?? 'notSubmitted',
      subjectKind: data['subjectKind'] as String?,
      caseCompleteness: data['caseCompleteness'] as String?,
      fullName: data['fullName'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      parentGuardianContact: data['parentGuardianContact'] as String?,
      teenUid: data['teenUid'] as String?,
      linkedAccountEmail: data['linkedAccountEmail'] as String?,
      identityLinkedAt: data['identityLinkedAt'] == null
          ? null
          : _toDate(data['identityLinkedAt']),
      teenProfileSyncedAt: data['teenProfileSyncedAt'] == null
          ? null
          : _toDate(data['teenProfileSyncedAt']),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final entity = toEntity();
    final displayName = entity.displayFullName;
    final storedAge = _storedAgeForEntity(entity);
    return {
      'demoName': displayName,
      'fullName': displayName,
      'age': storedAge,
      'barangay': barangay,
      'orgId': orgId,
      'caseStatus': caseStatus,
      'registeredAt': Timestamp.fromDate(registeredAt),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': Timestamp.fromDate(nextFollowUpAt!),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reportStatus': reportStatus,
      if (subjectKind != null && subjectKind!.isNotEmpty)
        'subjectKind': subjectKind,
      if (caseCompleteness != null && caseCompleteness!.isNotEmpty)
        'caseCompleteness': caseCompleteness,
      if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty)
        'dateOfBirth': dateOfBirth!.trim(),
      if (contactEmail != null && contactEmail!.trim().isNotEmpty)
        'contactEmail': contactEmail!.trim(),
      if (contactPhone != null && contactPhone!.trim().isNotEmpty)
        'contactPhone': contactPhone!.trim(),
      if (parentGuardianContact != null &&
          parentGuardianContact!.trim().isNotEmpty)
        'parentGuardianContact': parentGuardianContact!.trim(),
      if (teenUid != null && teenUid!.trim().isNotEmpty) 'teenUid': teenUid,
      if (linkedAccountEmail != null && linkedAccountEmail!.trim().isNotEmpty)
        'linkedAccountEmail': linkedAccountEmail!.trim(),
      if (identityLinkedAt != null)
        'identityLinkedAt': Timestamp.fromDate(identityLinkedAt!),
      if (teenProfileSyncedAt != null)
        'teenProfileSyncedAt': Timestamp.fromDate(teenProfileSyncedAt!),
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    final map = toFirestoreMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toFirestoreUpdate({required DateTime createdAt}) {
    final map = toFirestoreMap();
    map['createdAt'] = Timestamp.fromDate(createdAt);
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }

  factory CaseRecordModel.fromEntity(CaseRecord record) {
    final displayName = record.displayFullName;
    return CaseRecordModel(
      caseId: record.caseId,
      demoName: displayName,
      age: _storedAgeForEntity(record),
      barangay: record.barangay,
      orgId: record.orgId,
      caseStatus: record.caseStatus.firestoreValue,
      registeredAt: record.registeredAt,
      nextFollowUpAt: record.nextFollowUpAt,
      notes: record.notes,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      reportStatus: record.reportStatus.firestoreValue,
      subjectKind: record.subjectKind?.firestoreValue,
      caseCompleteness: record.caseCompleteness?.firestoreValue,
      fullName: displayName,
      dateOfBirth: record.dateOfBirth,
      contactEmail: record.contactEmail,
      contactPhone: record.contactPhone,
      parentGuardianContact: record.parentGuardianContact,
      teenUid: record.teenUid,
      linkedAccountEmail: record.linkedAccountEmail,
      identityLinkedAt: record.identityLinkedAt,
      teenProfileSyncedAt: record.teenProfileSyncedAt,
    );
  }

  CaseRecord toEntity() {
    final status = CaseStatus.fromFirestore(caseStatus);
    final report = ReportStatus.fromFirestore(reportStatus);
    if (status == null || report == null) {
      throw FormatException('Invalid case document $caseId');
    }
    return CaseRecord(
      caseId: caseId,
      demoName: demoName,
      age: age,
      barangay: barangay,
      orgId: orgId,
      caseStatus: status,
      registeredAt: registeredAt,
      nextFollowUpAt: nextFollowUpAt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reportStatus: report,
      subjectKind: CaseSubjectKind.fromFirestore(subjectKind),
      caseCompleteness: CaseCompleteness.fromFirestore(caseCompleteness),
      fullName: fullName ?? '',
      dateOfBirth: dateOfBirth,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      parentGuardianContact: parentGuardianContact,
      teenUid: teenUid,
      linkedAccountEmail: linkedAccountEmail,
      identityLinkedAt: identityLinkedAt,
      teenProfileSyncedAt: teenProfileSyncedAt,
    );
  }

  static void assertValidForWrite(CaseRecord record) {
    final error = CaseValidation.validateForWrite(record);
    if (error != null) {
      throw FormatException(error);
    }
  }

  static int _storedAgeForEntity(CaseRecord record) {
    if (record.completeness == CaseCompleteness.draft) {
      final dob = CaseDateOfBirth.parse(record.dateOfBirth);
      if (dob != null) return CaseDateOfBirth.currentAge(dob);
      return record.age;
    }
    final dob = CaseDateOfBirth.parse(record.dateOfBirth);
    if (dob != null) return CaseDateOfBirth.currentAge(dob);
    return record.age;
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
