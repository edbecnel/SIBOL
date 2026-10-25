import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/moph/presentation/screens/moph_home_screen.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';

const _hospitalOrgId = 'hospital01';
const _uid = 'mophStaffUid1234567890123456';

UserProfile _mophProfile({String? primaryOrgId}) {
  return UserProfile(
    uid: _uid,
    role: SibolRole.moph,
    displayName: 'Demo MOPH User',
    active: true,
    createdAt: DateTime(2026),
    primaryOrgId: primaryOrgId,
  );
}

OrganizationMembership _hospitalMembership(List<String> capabilities) {
  final now = DateTime(2026);
  return OrganizationMembership(
    membershipId: 'mbr_${_hospitalOrgId}__$_uid',
    orgId: _hospitalOrgId,
    accountUid: _uid,
    status: MembershipStatus.active,
    capabilities: capabilities,
    createdAt: now,
    updatedAt: now,
  );
}

CoordinationThread _sampleThread() {
  final now = DateTime(2026, 10, 25);
  return CoordinationThread(
    threadId: 'thread-1',
    orgId: 'barangay03',
    displayRef: 'SIBOL-REF-DEMO',
    barangay: 'Barangay 3, Balingasag',
    category: AssistanceRequestCategory.counselingReferral,
    barangayReferralSummary: 'Fictional summary for hospital coordination.',
    phase: CoordinationPhase.referred,
    createdAt: now,
    updatedAt: now,
    lastStaffEventAt: now,
    createdByUid: 'barangay-uid',
  );
}

MophAggregateReport _sampleReport() {
  final now = DateTime(2026, 10, 25);
  return MophAggregateReport(
    reportId: 'report-1',
    barangay: 'Barangay 3, Balingasag',
    orgId: 'barangay03',
    submittedAt: now,
    submittedByUid: 'barangay-uid',
    totalCaseCount: 3,
    activeCaseCount: 2,
    followUpScheduledCount: 1,
    followUpCompletedCount: 0,
    closedCaseCount: 0,
    reportStatus: 'submitted',
    acceptedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required UserProfile profile,
    required List<OrganizationMembership> memberships,
    List<CoordinationThread> threads = const [],
    List<MophAggregateReport> reports = const [],
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(
              AuthUser(uid: _uid, email: 'moph.demo@sibol.local'),
            ),
          ),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          accountMembershipsProvider.overrideWith(
            (ref) => Stream.value(memberships),
          ),
          mophCoordinationThreadsProvider.overrideWith(
            (ref) => Stream.value(threads),
          ),
          mophSubmittedReportsProvider.overrideWith(
            (ref) => Stream.value(reports),
          ),
          organizationDirectoryEntryProvider('barangay03').overrideWith(
            (ref) => Stream.value(
              OrganizationDirectoryEntry(
                orgId: 'barangay03',
                type: OrganizationType.barangay,
                name: 'Barangay 3 (Poblacion)',
                status: OrganizationStatus.active,
                updatedAt: DateTime(2026, 1, 1),
                geographicSiteLabel: 'Barangay 3, Balingasag',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MophHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
  }

  testWidgets('operational MOPH staff sees coordination and report sections',
      (tester) async {
    await pumpDashboard(
      tester,
      profile: _mophProfile(primaryOrgId: _hospitalOrgId),
      memberships: [
        _hospitalMembership([OrgCapabilities.coordinationHospital]),
      ],
      threads: [_sampleThread()],
      reports: [_sampleReport()],
    );

    expect(find.text('SIBOL-REF-DEMO'), findsOneWidget);
    expect(find.text('Barangay 3 (Poblacion)'), findsWidgets);
    expect(find.textContaining('permission-denied'), findsNothing);
  });

  testWidgets('management-only MOPH admin shows authorization error, not loading',
      (tester) async {
    await pumpDashboard(
      tester,
      profile: _mophProfile(primaryOrgId: _hospitalOrgId),
      memberships: [
        _hospitalMembership([OrgCapabilities.orgManageMembers]),
      ],
    );

    expect(find.textContaining('coordination.hospital'), findsOneWidget);
    expect(find.textContaining('Loading coordinations'), findsNothing);
  });

  test('membershipListenOrgIdForStaff uses pilot hospital when primaryOrgId missing',
      () {
    expect(
      membershipListenOrgIdForStaff(_mophProfile(primaryOrgId: null)),
      _hospitalOrgId,
    );
  });
}
