import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';

class AssistanceRequest extends Equatable {
  const AssistanceRequest({
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
  });

  final String requestId;
  final String teenUid;
  final String barangay;
  final String orgId;
  final AssistanceRequestCategory category;
  final String description;
  final AssistanceRequestStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByUid;
  final String? submitterDisplayName;
  final String? submitterAccountEmail;

  @override
  List<Object?> get props => [
        requestId,
        teenUid,
        barangay,
        orgId,
        category,
        description,
        status,
        createdAt,
        acknowledgedAt,
        acknowledgedByUid,
        submitterDisplayName,
        submitterAccountEmail,
      ];
}
