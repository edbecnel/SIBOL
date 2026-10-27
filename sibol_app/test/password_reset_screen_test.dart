import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sibol_app/features/auth/presentation/screens/password_reset_screen.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class _RecordingAuthRepository implements AuthRepository {
  String? lastResetEmail;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<AuthUser> reloadCurrentUser() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> acknowledgeMandatoryPasswordChange() async {}
}

void main() {
  testWidgets('Forgot password flow invokes Firebase reset for real email', (tester) async {
    final repo = _RecordingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) => repo)],
        child: const MaterialApp(home: PasswordResetScreen()),
      ),
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Email',
      ),
      'teen.user@example.com',
    );
    await tester.tap(find.widgetWithText(AppButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(repo.lastResetEmail, 'teen.user@example.com');
    expect(find.textContaining('Firebase sent a password reset email'), findsOneWidget);
  });

  testWidgets('blocks .local demo email without calling Firebase', (tester) async {
    final repo = _RecordingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWith((ref) => repo)],
        child: const MaterialApp(home: PasswordResetScreen()),
      ),
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Email',
      ),
      'teen.demo@sibol.local',
    );
    await tester.tap(find.widgetWithText(AppButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(repo.lastResetEmail, isNull);
    expect(find.textContaining('demonstration .local'), findsOneWidget);
  });
}
