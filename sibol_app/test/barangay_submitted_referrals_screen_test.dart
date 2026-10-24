import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/core/constants/demo_org_constants.dart';
import 'package:sibol_app/features/coordination/presentation/screens/barangay_submitted_referrals_screen.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'support/fake_coordination_repository.dart';

void main() {
  final profile = UserProfile(
    uid: 'bns-1',
    role: SibolRole.barangay,
    displayName: 'Barangay Demo',
    active: true,
    createdAt: DateTime.utc(2026, 1, 1),
    assignedBarangay: 'Barangay Tres, Balingasag',
  );

  CoordinationThread sampleThread() {
    final when = DateTime.utc(2026, 10, 24);
    return CoordinationThread(
      threadId: 'thread-1',
      barangay: 'Barangay Tres, Balingasag',
      displayRef: 'SIBOL-REF-DEMO12345678',
      category: AssistanceRequestCategory.healthInformation,
      barangayReferralSummary: 'Fictional summary.',
      phase: CoordinationPhase.referred,
      createdAt: when,
      updatedAt: when,
      lastStaffEventAt: when,
      createdByUid: 'bns-1',
    );
  }

  Widget harness({
    required FakeCoordinationRepository repo,
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        coordinationRepositoryProvider.overrideWithValue(repo),
        barangayCoordinationOrgIdProvider.overrideWithValue(
          DemoOrgConstants.barangayTresOrgId,
        ),
      ],
      child: const MaterialApp(
        home: BarangaySubmittedReferralsScreen(),
      ),
    );
  }

  testWidgets('empty referral history shows appropriate message', (tester) async {
    await tester.pumpWidget(
      harness(repo: FakeCoordinationRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No submitted referrals yet'), findsOneWidget);
  });

  testWidgets('lists barangay submitted referrals', (tester) async {
    await tester.pumpWidget(
      harness(
        repo: FakeCoordinationRepository(
          submittedReferralsStream: Stream.value([sampleThread()]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SIBOL-REF-DEMO12345678'), findsOneWidget);
    expect(find.textContaining('Last activity'), findsOneWidget);
  });
}
