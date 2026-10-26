import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/router/app_router.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_submitter_identity.dart';
import 'package:sibol_app/main_common.dart';

/// Run after online card test with device airplane mode enabled (host script).
/// Relies on Firestore persistence + prior session cache; does not reseed data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const expectedEmails = <String>[
    'teen.demo@sibol.local',
    'teen.qa03@example.com',
  ];

  testWidgets('Incoming request cards show cached account email (device, offline)', (
    tester,
  ) async {
    await mainCommon();
    await tester.pumpAndSettle(const Duration(seconds: 15));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SibolApp)),
    );
    final router = container.read(appRouterProvider);

    router.go(Routes.barangayIncomingRequests);
    await tester.pumpAndSettle(const Duration(seconds: 12));

    for (final email in expectedEmails) {
      expect(
        find.text(
          assistanceIncomingRequestCardAccountEmailLine(email),
        ),
        findsWidgets,
      );
    }
  });
}
