import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/admin/presentation/screens/org_admin_teen_recovery_screen.dart';

void main() {
  testWidgets('teen recovery screen denied without org admin access', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isCentralAdminProvider.overrideWith((ref) => false),
          orgAdminManagedOrgIdsProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(
          home: OrgAdminTeenRecoveryScreen(orgId: 'barangay03'),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('permission to recover teenager accounts'),
      findsOneWidget,
    );
  });
}
