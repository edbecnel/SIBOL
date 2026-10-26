import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/core/firestore/firestore_snapshot_listeners.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/presentation/screens/barangay_home_screen.dart';
import 'package:sibol_app/features/cases/presentation/widgets/case_follow_up_timeline.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/shared/widgets/cached_data_notice.dart';
import 'support/fake_case_repository.dart';
import 'support/sample_case_records.dart';
import 'support/sample_follow_ups.dart';

void main() {
  test('cache metadata listeners use includeMetadataChanges', () {
    expect(FirestoreSnapshotListeners.includeMetadataChanges, isTrue);
  });

  testWidgets('CachedDataNotice hides when snapshot is server-confirmed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedDataNotice(isFromCache: false),
        ),
      ),
    );
    expect(find.textContaining('server snapshot'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CachedDataNotice(isFromCache: true),
        ),
      ),
    );
    expect(find.textContaining('server snapshot'), findsOneWidget);
  });

  testWidgets('dashboard cache warning clears on metadata-only transition', (tester) async {
    final record = sampleCaseRecord();
    final controller = StreamController<FirestoreListSnapshot<CaseListEntry>>();
    const uid = 'barangay-case-list-uid';

    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(AuthUser(uid: uid, email: 'b@sibol.local')),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(
              UserProfile(
                uid: uid,
                role: SibolRole.barangay,
                displayName: 'Barangay',
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
                accountUid: uid,
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
          caseRepositoryProvider.overrideWithValue(
            FakeCaseRepository(
              cases: [record],
              casesStream: controller.stream,
            ),
          ),
        ],
        child: const MaterialApp(home: BarangayHomeScreen()),
      ),
    );

    controller.add(
      FirestoreListSnapshot(
        items: [
          CaseListEntry(record: record, isFromCache: true, hasPendingWrites: false),
        ],
        isFromCache: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('server snapshot'), findsOneWidget);

    controller.add(
      FirestoreListSnapshot(
        items: [
          CaseListEntry(record: record, isFromCache: false, hasPendingWrites: false),
        ],
        isFromCache: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('server snapshot'), findsNothing);

    await controller.close();
    tester.view.resetPhysicalSize();
  });

  testWidgets('follow-up Cached only clears after server metadata', (tester) async {
    const caseId = 'demo-case-001';
    final controller = StreamController<List<FollowUpTimelineEntry>>();
    final base = sampleFollowUp(
      notes: 'Synced note',
      followUpId: 'fu-1',
    );
    final withAudit = FollowUp(
      followUpId: base.followUpId,
      caseId: base.caseId,
      scheduledAt: base.scheduledAt,
      completedAt: base.completedAt,
      status: base.status,
      notes: base.notes,
      createdAt: DateTime.utc(2026, 4, 1),
      createdByUid: 'staff-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(
            FakeCaseRepository(followUpStreams: {caseId: controller.stream}),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CaseFollowUpTimeline(caseId: caseId)),
        ),
      ),
    );

    controller.add([
      FollowUpTimelineEntry(
        followUp: withAudit,
        isFromCache: true,
        awaitingServerConfirmation: false,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Cached only'), findsOneWidget);

    controller.add([
      FollowUpTimelineEntry(
        followUp: withAudit,
        isFromCache: false,
        awaitingServerConfirmation: false,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Cached only'), findsNothing);
    expect(find.text('Pending sync'), findsNothing);

    await controller.close();
  });

  testWidgets('follow-up Pending sync remains while awaiting server', (tester) async {
    const caseId = 'demo-case-001';
    final pending = sampleFollowUp(notes: 'Offline draft');
    final repo = FakeCaseRepository(
      followUpStreams: {
        caseId: Stream.value([
          FollowUpTimelineEntry(
            followUp: pending,
            isFromCache: true,
            awaitingServerConfirmation: true,
          ),
        ]),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [caseRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(body: CaseFollowUpTimeline(caseId: caseId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('Cached only'), findsNothing);
  });
}
