enum PendingOperationKind {
  teenAssistanceSubmit,
  barangayAcknowledge,
  barangayReferral,
  barangayReportSubmit,
}

enum PendingOperationState {
  savedLocally,
  waitingToSubmit,
  submitting,
  submittedConfirmed,
  failedRetryable,
  failedPermanent,
  conflict,
}

class PendingOperation {
  const PendingOperation({
    required this.operationId,
    required this.ownerUid,
    required this.kind,
    required this.state,
    required this.createdAt,
    required this.payload,
    this.firebaseProjectId,
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.lastError,
    this.serverRequestId,
  });

  /// Originating Firebase project (`demo-sibol-emulator` or production).
  /// Null marks legacy entries before environment stamping (quarantined on replay).
  final String? firebaseProjectId;

  final String operationId;
  final String ownerUid;
  final PendingOperationKind kind;
  final PendingOperationState state;
  final DateTime createdAt;
  final Map<String, String> payload;
  final DateTime? lastAttemptAt;
  final int attemptCount;
  final String? lastError;
  final String? serverRequestId;

  PendingOperation copyWith({
    PendingOperationState? state,
    DateTime? lastAttemptAt,
    int? attemptCount,
    String? lastError,
    String? serverRequestId,
    String? firebaseProjectId,
  }) {
    return PendingOperation(
      operationId: operationId,
      ownerUid: ownerUid,
      kind: kind,
      state: state ?? this.state,
      createdAt: createdAt,
      payload: payload,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      serverRequestId: serverRequestId ?? this.serverRequestId,
    );
  }

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'ownerUid': ownerUid,
        'kind': kind.name,
        'state': state.name,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        if (firebaseProjectId != null) 'firebaseProjectId': firebaseProjectId,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
        'attemptCount': attemptCount,
        'lastError': lastError,
        'serverRequestId': serverRequestId,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      operationId: json['operationId'] as String,
      ownerUid: json['ownerUid'] as String,
      kind: PendingOperationKind.values.byName(json['kind'] as String),
      state: PendingOperationState.values.byName(json['state'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: Map<String, String>.from(json['payload'] as Map),
      firebaseProjectId: json['firebaseProjectId'] as String?,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      attemptCount: json['attemptCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      serverRequestId: json['serverRequestId'] as String?,
    );
  }
}
