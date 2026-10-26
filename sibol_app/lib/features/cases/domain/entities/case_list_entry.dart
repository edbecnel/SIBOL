import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';

/// Case row with Firestore snapshot metadata for list presentation.
class CaseListEntry extends Equatable {
  const CaseListEntry({
    required this.record,
    required this.isFromCache,
    required this.hasPendingWrites,
  });

  final CaseRecord record;
  final bool isFromCache;
  final bool hasPendingWrites;

  @override
  List<Object?> get props => [record, isFromCache, hasPendingWrites];
}
