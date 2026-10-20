import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/presentation/screens/login_screen.dart';

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
}
