import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/geo/data/psgc_bundle.dart';
import 'package:sibol_app/features/geo/presentation/geo_providers.dart';
import 'package:sibol_app/features/teen_registration/presentation/screens/teen_registration_screen.dart';

void main() {
  testWidgets('teen registration form shows identity and sign-in fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          psgcBundleProvider.overrideWith(
            (ref) => Future.value(
              PsgcBundle(version: 'test-v1', nodes: const [], synthetic: true),
            ),
          ),
        ],
        child: const MaterialApp(home: TeenRegistrationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Date of birth (YYYY-MM-DD)'), findsOneWidget);
    expect(find.text('Sign-in email'), findsOneWidget);
    expect(find.text('Contact email (optional if phone provided)'), findsOneWidget);
    expect(find.text('Create account and register'), findsOneWidget);
  });
}
