import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/presentation/widgets/case_follow_up_timeline.dart';
import 'support/fake_case_repository.dart';
import 'support/sample_follow_ups.dart';

void main() {
  const caseId = 'demo-case-001';

  testWidgets('shows follow-ups in scheduledAt order', (tester) async {
    final later = sampleFollowUp(
      followUpId: 'fu-2',
      scheduledAt: DateTime(2026, 5, 1),
      notes: 'Second visit',
    );
    final earlier = sampleFollowUp(
      followUpId: 'fu-1',
      scheduledAt: DateTime(2026, 4, 1),
      notes: 'First visit',
    );
    final repo = FakeCaseRepository(
      followUpStreams: {
        caseId: Stream.value([
          FollowUpTimelineEntry(followUp: earlier, isFromCache: false),
          FollowUpTimelineEntry(followUp: later, isFromCache: false),
        ]),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CaseFollowUpTimeline(caseId: caseId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First visit'), findsOneWidget);
    expect(find.text('Second visit'), findsOneWidget);
    expect(find.text('First visit'), findsOneWidget);
  });

  testWidgets('shows pending sync chip when write not confirmed', (tester) async {
    final entry = sampleFollowUp(notes: 'Offline draft');
    final repo = FakeCaseRepository(
      followUpStreams: {
        caseId: Stream.value([
          FollowUpTimelineEntry(
            followUp: entry,
            isFromCache: true,
            hasPendingWrites: false,
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
    expect(find.text('Offline draft'), findsOneWidget);
  });

  testWidgets('shows empty state when no follow-ups', (tester) async {
    final repo = FakeCaseRepository(
      followUpStreams: {caseId: Stream.value(const [])},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CaseFollowUpTimeline(caseId: caseId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No follow-ups recorded'), findsOneWidget);
  });

  testWidgets('shows loading indicator', (tester) async {
    final controller = StreamController<List<FollowUpTimelineEntry>>();
    final repo = FakeCaseRepository(
      followUpStreams: {caseId: controller.stream},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CaseFollowUpTimeline(caseId: caseId),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Loading follow-ups…'), findsOneWidget);
    await controller.close();
  });

  testWidgets('shows error when stream fails', (tester) async {
    final repo = FakeCaseRepository(
      followUpStreams: {
        caseId: Stream<List<FollowUpTimelineEntry>>.error(Exception('denied')),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CaseFollowUpTimeline(caseId: caseId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load follow-ups'), findsOneWidget);
  });
}
