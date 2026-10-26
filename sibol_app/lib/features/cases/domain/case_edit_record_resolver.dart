import 'dart:async';

import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/features/cases/domain/case_edit_unavailable.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

/// Cache-first case load for the edit form, with resilient live updates.
class CaseEditRecordResolver {
  CaseEditRecordResolver(this._repository);

  final CaseRepository _repository;

  static const Duration _serverBootstrapTimeout = Duration(seconds: 3);

  Stream<CaseRecord> watchForEdit(String caseId) {
    final trimmed = caseId.trim();
    if (trimmed.isEmpty) {
      return Stream<CaseRecord>.error(
        CaseEditUnavailable('Case id is required to edit.'),
      );
    }

    final controller = StreamController<CaseRecord>();
    StreamSubscription<FirestoreDocumentSnapshot<CaseRecord>>? detailSub;
    var closed = false;

    Future<void> start() async {
      CaseRecord? trustedLocal;
      try {
        trustedLocal = await _repository.fetchCasePreferCache(trimmed);
        if (trustedLocal != null && !closed) {
          controller.add(trustedLocal);
        }
      } catch (_) {
        // Fall through to server/bootstrap path.
      }

      if (trustedLocal == null) {
        try {
          final bootstrapped = await _repository
              .fetchCase(trimmed)
              .timeout(_serverBootstrapTimeout);
          if (bootstrapped != null) {
            trustedLocal = bootstrapped;
            if (!closed) controller.add(bootstrapped);
          }
        } on TimeoutException {
          // Offline or unreachable host; rely on cache-only result.
        } catch (_) {
          // Ignore; missing-local error handled below.
        }
      }

      if (trustedLocal == null && !closed) {
        controller.addError(CaseEditUnavailable.missingLocally(trimmed));
        await controller.close();
        return;
      }

      detailSub = _repository.watchCase(trimmed).listen(
        (snapshot) {
          final record = snapshot.data;
          if (record != null && !closed) {
            controller.add(record);
          }
        },
        onError: (_) {
          if (trustedLocal == null && !closed) {
            controller.addError(CaseEditUnavailable.missingLocally(trimmed));
          }
        },
      );
    }

    unawaited(
      start().catchError((Object e, StackTrace st) {
        if (!closed) controller.addError(e, st);
      }),
    );

    controller.onCancel = () async {
      closed = true;
      await detailSub?.cancel();
    };

    return controller.stream;
  }
}
