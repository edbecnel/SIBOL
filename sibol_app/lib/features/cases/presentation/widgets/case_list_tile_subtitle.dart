import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/case_identity_presentation.dart';
import 'package:sibol_app/features/cases/domain/case_presentation_labels.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';

class CaseListTileSubtitle extends StatelessWidget {
  const CaseListTileSubtitle({super.key, required this.entry});

  final CaseListEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final record = entry.record;
    final syncLabel = CasePresentationLabels.synchronizationStatus(
      isFromCache: entry.isFromCache,
      hasPendingWrites: entry.hasPendingWrites,
    );
    final contactHint = CaseIdentityPresentation.listContactHint(record);
    final lines = <String>[
      '${CaseIdentityPresentation.subjectClassificationLabel(record)} · '
          'Age ${record.effectiveAge}',
      CasePresentationLabels.lifecycleStatus(record.caseStatus),
      if (contactHint != null) contactHint,
      'Case opened ${dateFmt.format(record.registeredAt)}',
      CaseIdentityPresentation.completenessLabel(record),
      CasePresentationLabels.aggregateReportInclusion(record.reportStatus),
      if (syncLabel != null && syncLabel != 'Server confirmed') syncLabel,
    ];
    return Text(lines.join('\n'));
  }
}
