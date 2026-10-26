import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/coordination_thread_detail_body.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

void main() {
  testWidgets('renders MOPH-visible fields without teen identifiers', (
    tester,
  ) async {
    final thread = CoordinationThread(
      threadId: 'thread-1',
      orgId: 'barangay03',
      barangay: 'Barangay 3, Balingasag',
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
      ProviderScope(
        overrides: [
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
        child: MaterialApp(
          home: Scaffold(
            body: CoordinationThreadDetailBody(thread: thread, events: events),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SIBOL-REF-DEMO'), findsOneWidget);
    expect(find.text('Barangay 3 (Poblacion)'), findsOneWidget);
    expect(find.text('Geographic site'), findsNothing);
    expect(find.text('Historical site label'), findsNothing);
    expect(find.textContaining('Fictional coordination summary'), findsOneWidget);
    expect(find.textContaining('teenUid'), findsNothing);
    expect(find.textContaining('Teen original'), findsNothing);
  });
}
