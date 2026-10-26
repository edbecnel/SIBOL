import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';
import 'support/fake_case_repository.dart';

CaseRecord _sampleCase() {
  return CaseRecord(
    caseId: 'case-ui-1',
    demoName: 'Demo Case',
    age: 16,
    barangay: 'Barangay 3, Balingasag',
    orgId: 'barangay03',
    caseStatus: CaseStatus.active,
    registeredAt: DateTime.utc(2026, 4, 1),
    notes: 'Notes',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
    reportStatus: ReportStatus.notSubmitted,
  );
}

void main() {
  testWidgets('case list does not show raw report status enum', (tester) async {
    final record = _sampleCase();
    final repo = FakeCaseRepository(
      cases: [record],
      caseStreams: {
        record.caseId: Stream.value(
          FirestoreDocumentSnapshot(data: record, isFromCache: false),
        ),
      },
    );

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(AuthUser(uid: 'u1', email: 'b@sibol.local')),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                uid: 'u1',
                role: SibolRole.barangay,
                displayName: 'BNS',
                active: true,
                createdAt: DateTime.utc(2026, 1, 1),
                primaryOrgId: record.orgId,
              ),
            ),
          ),
          accountMembershipsProvider.overrideWith(
            (ref) => Stream.value([
              OrganizationMembership(
                membershipId: 'm1',
                orgId: record.orgId,
                accountUid: 'u1',
                status: MembershipStatus.active,
                capabilities: [
                  OrgCapabilities.caseRead,
                  OrgCapabilities.caseWrite,
                ],
                createdAt: DateTime.utc(2026, 1, 1),
                updatedAt: DateTime.utc(2026, 1, 1),
              ),
            ]),
          ),
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CaseDetailScreen(caseId: 'case-ui-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('notSubmitted'), findsNothing);
    expect(find.textContaining('Active case'), findsOneWidget);
    expect(
      find.textContaining('Not yet included in a submitted report'),
      findsOneWidget,
    );

    tester.view.resetPhysicalSize();
  });
}
