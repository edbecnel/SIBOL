import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_presentation_labels.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  test('lifecycle labels are human-readable', () {
    expect(
      CasePresentationLabels.lifecycleStatus(CaseStatus.active),
      'Active case',
    );
    expect(
      CasePresentationLabels.lifecycleStatus(CaseStatus.active),
      isNot(contains('active')),
    );
  });

  test('aggregate report labels do not expose notSubmitted', () {
    final label = CasePresentationLabels.aggregateReportInclusion(
      ReportStatus.notSubmitted,
    );
    expect(label, contains('Not yet included'));
    expect(label.toLowerCase(), isNot(contains('notsubmitted')));
  });

  test('sync labels follow metadata semantics', () {
    expect(
      CasePresentationLabels.synchronizationStatus(
        isFromCache: false,
        hasPendingWrites: true,
      ),
      'Saved locally — awaiting synchronization',
    );
    expect(
      CasePresentationLabels.synchronizationStatus(
        isFromCache: true,
        hasPendingWrites: false,
      ),
      'Showing saved data — checking for updates',
    );
    expect(
      CasePresentationLabels.synchronizationStatus(
        isFromCache: false,
        hasPendingWrites: false,
      ),
      'Server confirmed',
    );
  });
}
