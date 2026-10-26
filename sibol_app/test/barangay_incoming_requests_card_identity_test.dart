import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_submitter_identity.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/features/teenager/presentation/screens/barangay_incoming_requests_screen.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

void main() {
  testWidgets('incoming request card shows cached account email offline', (
    tester,
  ) async {
    final request = AssistanceRequest(
      requestId: 'demo-assist-inbox-001',
      teenUid: 'teen-uid',
      barangay: 'Barangay 3, Balingasag',
      orgId: 'barangay03',
      category: AssistanceRequestCategory.generalSupport,
      description: 'Fictional request',
      status: AssistanceRequestStatus.submitted,
      createdAt: DateTime(2026, 10, 26, 8),
      submitterAccountEmail: 'teen.demo@sibol.local',
    );

    final snapshot = FirestoreListSnapshot(
      isFromCache: true,
      hasPendingWrites: false,
      items: [request],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          barangayAssistanceOrgIdProvider.overrideWithValue('barangay03'),
          barangayIncomingRequestsProvider.overrideWith(
            (ref) async* {
              yield snapshot;
            },
          ),
        ],
        child: const MaterialApp(
          home: BarangayIncomingRequestsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('General support (demo)'), findsOneWidget);
    expect(
      find.textContaining('Account email: teen.demo@sibol.local'),
      findsOneWidget,
    );
    expect(find.text('Demo Teen User'), findsNothing);
    expect(find.textContaining('Ref: demo-assist-inbox-001'), findsOneWidget);
  });
}
