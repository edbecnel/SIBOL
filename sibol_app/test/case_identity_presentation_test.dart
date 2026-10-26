import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_identity_presentation.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/presentation/widgets/case_list_tile_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

CaseRecord _record({
  String? contactEmail,
  String? contactPhone,
  CaseCompleteness completeness = CaseCompleteness.active,
  CaseSubjectKind? subjectKind,
}) {
  return CaseRecord(
    caseId: 'case-1',
    demoName: 'Demo Teen',
    age: 16,
    barangay: 'Barangay 3, Balingasag',
    orgId: 'barangay03',
    caseStatus: CaseStatus.active,
    registeredAt: DateTime.utc(2026, 10, 26),
    notes: '',
    createdAt: DateTime.utc(2026, 10, 26),
    updatedAt: DateTime.utc(2026, 10, 26),
    reportStatus: ReportStatus.notSubmitted,
    contactEmail: contactEmail,
    contactPhone: contactPhone,
    caseCompleteness: completeness,
    subjectKind: subjectKind,
  );
}

void main() {
  group('listCardContactLine', () {
    test('email only shows Email prefix', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(contactEmail: 'teen@sibol.local'),
        ),
        'Email: teen@sibol.local',
      );
    });

    test('phone only shows Phone prefix', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(contactPhone: '+639171234567'),
        ),
        'Phone: +639171234567',
      );
    });

    test('both prefers email on card', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(
            contactEmail: 'teen@sibol.local',
            contactPhone: '+639171234567',
          ),
        ),
        'Email: teen@sibol.local',
      );
    });

    test('neither shows not provided', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(_record()),
        'Contact: Not provided',
      );
    });

    test('whitespace email with valid phone shows phone', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(contactEmail: '   ', contactPhone: '+639171234567'),
        ),
        'Phone: +639171234567',
      );
    });

    test('draft keeps activation message', () {
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(
            completeness: CaseCompleteness.draft,
            contactEmail: 'draft@sibol.local',
          ),
        ),
        'Contact details required before activation',
      );
    });

    test('registered unregistered use same contact priority', () {
      final email = 'linked@sibol.local';
      expect(
        CaseIdentityPresentation.listCardContactLine(
          _record(
            contactEmail: email,
            subjectKind: CaseSubjectKind.registered,
          ),
        ),
        'Email: $email',
      );
    });
  });

  testWidgets('case list subtitle includes contact line and core labels',
      (tester) async {
    final record = _record(contactEmail: 'maria.offline@test.org');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaseListTileSubtitle(
            entry: CaseListEntry(
              record: record,
              isFromCache: false,
              hasPendingWrites: false,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Manual record (no SIBOL account)'), findsOneWidget);
    expect(find.textContaining('Active case'), findsOneWidget);
    expect(find.textContaining('Email: maria.offline@test.org'), findsOneWidget);
    expect(
      find.textContaining('Not yet included in a submitted report'),
      findsOneWidget,
    );
  });
}
