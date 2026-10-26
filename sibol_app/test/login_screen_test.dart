import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sibol_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class _InvalidCredentialAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      message: 'INVALID_LOGIN_CREDENTIALS',
      code: 'invalid-credential',
    );
  }

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
  Future<void> sendPasswordResetEmail(String email) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> acknowledgeMandatoryPasswordChange() async {}
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == label,
  );
}

Finder _editableText(Finder field) {
  return find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
}

EditableTextState _editableState(WidgetTester tester, Finder field) {
  return tester.state<EditableTextState>(_editableText(field));
}

Future<void> _tapField(WidgetTester tester, Finder field) async {
  await tester.ensureVisible(field);
  await tester.tap(_editableText(field));
  await tester.pump();
}

void main() {
  testWidgets('login screen renders email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.textContaining('fictional'), findsWidgets);
  });

  testWidgets('email field receives focus when tapped', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    final email = _textFieldWithLabel('Email');
    expect(email, findsOneWidget);

    await _tapField(tester, email);

    expect(
      tester.getSemantics(_editableText(email)).hasFlag(SemanticsFlag.isFocused),
      isTrue,
    );
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
  });

  testWidgets('email field accepts text via enterText', (tester) async {
    const input = 'fictional.input@sibol.test';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    final email = _textFieldWithLabel('Email');
    await _tapField(tester, email);
    await tester.enterText(email, input);
    await tester.pump();

    expect(_editableState(tester, email).textEditingValue.text, input);
  });

  testWidgets('password field receives focus when tapped', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    final password = _textFieldWithLabel('Password');
    expect(password, findsOneWidget);

    await _tapField(tester, password);

    expect(
      tester
          .getSemantics(_editableText(password))
          .hasFlag(SemanticsFlag.isFocused),
      isTrue,
    );
    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
  });

  testWidgets('password field accepts text via enterText', (tester) async {
    const input = 'FictionalTestInputOnly';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    final password = _textFieldWithLabel('Password');
    await _tapField(tester, password);
    await tester.enterText(password, input);
    await tester.pump();

    expect(_editableState(tester, password).textEditingValue.text, input);
  });

  testWidgets('clears stale sign-in error when login screen is reopened',
      (tester) async {
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith(
              (ref) => _InvalidCredentialAuthRepository(),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid email or password.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpLogin(tester);
    expect(find.text('Invalid email or password.'), findsNothing);
  });
}
