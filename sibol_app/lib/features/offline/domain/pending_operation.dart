enum PendingOperationKind {
  teenAssistanceSubmit,
  barangayAcknowledge,
  barangayReferral,
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
    this.lastAttemptAt,
    this.attemptCount = 0,
    this.lastError,
    this.serverRequestId,
  });

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
  }) {
    return PendingOperation(
      operationId: operationId,
      ownerUid: ownerUid,
      kind: kind,
      state: state ?? this.state,
      createdAt: createdAt,
      payload: payload,
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
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      attemptCount: json['attemptCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      serverRequestId: json['serverRequestId'] as String?,
    );
  }
}
