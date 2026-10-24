import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'support/fake_auth_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-out startup navigates to welcome screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(null)),
          ),
        ],
        child: const SibolApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Register as Teen'), findsOneWidget);
    expect(find.text('Starting…'), findsNothing);
  });

  testWidgets('welcome sign in opens login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(null)),
          ),
        ],
        child: const SibolApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsWidgets);
  });

  testWidgets('welcome register as teen opens teen registration', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(null)),
          ),
        ],
        child: const SibolApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Register as Teen'));
    await tester.pumpAndSettle();

    expect(find.text('Teen registration'), findsOneWidget);
  });

  testWidgets('teen registration back returns to welcome', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(null)),
          ),
        ],
        child: const SibolApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Register as Teen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Register as Teen'), findsOneWidget);
  });
}
