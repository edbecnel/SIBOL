import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/coordination_thread_detail_body.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

void main() {
  testWidgets('renders MOPH-visible fields without teen identifiers', (
    tester,
  ) async {
    final thread = CoordinationThread(
      threadId: 'thread-1',
      barangay: 'Barangay Tres, Balingasag',
      displayRef: 'SIBOL-REF-DEMO12345678',
      category: AssistanceRequestCategory.generalSupport,
      barangayReferralSummary: 'Fictional coordination summary for MOPH.',
      phase: CoordinationPhase.referred,
      createdAt: DateTime(2026, 10, 24),
      updatedAt: DateTime(2026, 10, 24),
      lastStaffEventAt: DateTime(2026, 10, 24),
      createdByUid: 'bns-uid',
    );
    final events = [
      CoordinationStaffEvent(
        eventId: 'e1',
        eventType: 'referral_submitted',
        body: 'Referral submitted for review.',
        actorUid: 'bns-uid',
        createdAt: DateTime(2026, 10, 24),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoordinationThreadDetailBody(thread: thread, events: events),
        ),
      ),
    );

    expect(find.textContaining('SIBOL-REF-DEMO'), findsOneWidget);
    expect(find.textContaining('Fictional coordination summary'), findsOneWidget);
    expect(find.textContaining('teenUid'), findsNothing);
    expect(find.textContaining('Teen original'), findsNothing);
  });
}
