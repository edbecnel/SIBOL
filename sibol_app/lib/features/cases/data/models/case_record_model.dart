import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'demoName': demoName,
      'age': age,
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
    };
  }

  /// Firestore payload for client create (server timestamps for audit fields).
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'demoName': demoName,
      'age': age,
      'barangay': barangay,
      'orgId': orgId,
      'caseStatus': caseStatus,
      'registeredAt': Timestamp.fromDate(registeredAt),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': Timestamp.fromDate(nextFollowUpAt!),
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'reportStatus': reportStatus,
    };
  }

  /// Firestore payload for client update (preserves [createdAt]).
  Map<String, dynamic> toFirestoreUpdate({required DateTime createdAt}) {
    return {
      'demoName': demoName,
      'age': age,
      'barangay': barangay,
      'orgId': orgId,
      'caseStatus': caseStatus,
      'registeredAt': Timestamp.fromDate(registeredAt),
      if (nextFollowUpAt != null)
        'nextFollowUpAt': Timestamp.fromDate(nextFollowUpAt!),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'reportStatus': reportStatus,
    };
  }

  factory CaseRecordModel.fromEntity(CaseRecord record) {
    return CaseRecordModel(
      caseId: record.caseId,
      demoName: record.demoName,
      age: record.age,
      barangay: record.barangay,
      orgId: record.orgId,
      caseStatus: record.caseStatus.firestoreValue,
      registeredAt: record.registeredAt,
      nextFollowUpAt: record.nextFollowUpAt,
      notes: record.notes,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      reportStatus: record.reportStatus.firestoreValue,
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
    );
  }

  static void assertValidForWrite(CaseRecord record) {
    final errors = <String>[
      CaseValidation.validateDemoName(record.demoName) ?? '',
      CaseValidation.validateAge(record.age) ?? '',
      CaseValidation.validateBarangay(record.barangay) ?? '',
      CaseValidation.validateCaseStatus(record.caseStatus) ?? '',
    ].where((e) => e.isNotEmpty).toList();
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
