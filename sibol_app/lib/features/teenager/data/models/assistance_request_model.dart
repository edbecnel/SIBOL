import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

class AssistanceRequestModel {
  AssistanceRequestModel({
    required this.requestId,
    required this.teenUid,
    required this.barangay,
    required this.orgId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedByUid,
    this.submitterDisplayName,
    this.submitterAccountEmail,
    this.caseId,
  });

  final String requestId;
  final String teenUid;
  final String barangay;
  final String orgId;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByUid;
  final String? submitterDisplayName;
  final String? submitterAccountEmail;
  final String? caseId;

  factory AssistanceRequestModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return AssistanceRequestModel(
      requestId: id,
      teenUid: data['teenUid'] as String? ?? '',
      barangay: data['barangay'] as String? ?? '',
      orgId: data['orgId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? '',
      createdAt: _toDate(data['createdAt']),
      acknowledgedAt: data['acknowledgedAt'] == null
          ? null
          : _toDate(data['acknowledgedAt']),
      acknowledgedByUid: data['acknowledgedByUid'] as String?,
      submitterDisplayName: data['submitterDisplayName'] as String?,
      submitterAccountEmail: data['submitterAccountEmail'] as String?,
      caseId: data['caseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'teenUid': teenUid,
      'barangay': barangay,
      'orgId': orgId,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AssistanceRequest toEntity() {
    final cat = AssistanceRequestCategory.fromFirestore(category);
    final st = AssistanceRequestStatus.fromFirestore(status);
    if (cat == null || st == null) {
      throw FormatException('Invalid assistance request document $requestId');
    }
    return AssistanceRequest(
      requestId: requestId,
      teenUid: teenUid,
      barangay: barangay,
      orgId: orgId,
      category: cat,
      description: description,
      status: st,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt,
      acknowledgedByUid: acknowledgedByUid,
      submitterDisplayName: submitterDisplayName,
      submitterAccountEmail: submitterAccountEmail,
      caseId: caseId,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
