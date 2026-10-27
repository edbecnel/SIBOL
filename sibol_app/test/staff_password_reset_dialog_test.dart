import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/theme/app_theme.dart';
import 'package:sibol_app/features/admin/presentation/widgets/staff_password_reset_dialog.dart';

const _displayName = 'Demo Barangay Org Administrator';
const _email = 'barangay.org.admin@sibol.local';

/// Galaxy S9 logical size (portrait).
const _s9Size = Size(360, 740);

void main() {
  Future<void> pumpHost(WidgetTester tester, {Size size = _s9Size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showStaffPasswordResetFormDialog(
                context: context,
                displayName: _displayName,
                email: _email,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  void expectVisibleField(WidgetTester tester, Key key) {
    final box = tester.renderObject<RenderBox>(find.byKey(key));
    expect(box.hasSize, isTrue);
    expect(box.size.height, greaterThan(40));
    expect(box.size.width, greaterThan(100));
  }

  testWidgets('1 initial sheet shows target account and fields', (tester) async {
    await openSheet(tester);
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.textContaining(_displayName), findsOneWidget);
    expect(find.textContaining(_email), findsOneWidget);
    expectVisibleField(tester, const Key('staff-reset-temporary-password'));
    expectVisibleField(tester, const Key('staff-reset-confirm-password'));
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('2 both password fields visibly rendered', (tester) async {
    await openSheet(tester);
    expect(find.byType(TextField), findsNWidgets(2));
    expectVisibleField(tester, const Key('staff-reset-temporary-password'));
    expectVisibleField(tester, const Key('staff-reset-confirm-password'));
  });

  testWidgets('3 focus confirm field keeps sheet open', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('staff-reset-confirm-password')));
    await tester.pump();
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
  });

  testWidgets('4 keyboard-open layout at S9 dimensions', (tester) async {
    await pumpHost(tester);
    await tester.tap(find.text('Open'));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pumpAndSettle();

    expectVisibleField(tester, const Key('staff-reset-confirm-password'));
    expect(find.byKey(const Key('staff-reset-continue')), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
  });

  testWidgets('5 keyboard-closed layout shows actions', (tester) async {
    await openSheet(tester);
    expect(find.byKey(const Key('staff-reset-cancel')), findsOneWidget);
    expect(find.byKey(const Key('staff-reset-continue')), findsOneWidget);
  });

  testWidgets('6 password visibility toggles', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
  });

  testWidgets('7 password mismatch validation', (tester) async {
    await openSheet(tester);
    await tester.enterText(
      find.byKey(const Key('staff-reset-temporary-password')),
      'TempPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('staff-reset-confirm-password')),
      'Different!',
    );
    await tester.tap(find.byKey(const Key('staff-reset-continue')));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });

  testWidgets('7b minimum length validation', (tester) async {
    await openSheet(tester);
    await tester.enterText(
      find.byKey(const Key('staff-reset-temporary-password')),
      'short',
    );
    await tester.tap(find.byKey(const Key('staff-reset-continue')));
    await tester.pump();
    expect(
      find.text('Temporary password must be at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('8 cancel closes without result', (tester) async {
    StaffPasswordResetFormResult? result;
    await pumpHost(tester);
    final context = tester.element(find.text('Open'));
    showStaffPasswordResetFormDialog(
      context: context,
      displayName: _displayName,
      email: _email,
    ).then((r) => result = r);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('staff-reset-cancel')));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('8b valid passwords return result', (tester) async {
    StaffPasswordResetFormResult? result;
    await pumpHost(tester);
    showStaffPasswordResetFormDialog(
      context: tester.element(find.text('Open')),
      displayName: _displayName,
      email: _email,
    ).then((r) => result = r);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('staff-reset-temporary-password')),
      'TempPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('staff-reset-confirm-password')),
      'TempPass123!',
    );
    await tester.tap(find.byKey(const Key('staff-reset-continue')));
    await tester.pumpAndSettle();
    expect(result?.password, 'TempPass123!');
  });

  testWidgets('9 tapping fields does not dismiss sheet', (tester) async {
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('staff-reset-temporary-password')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('staff-reset-confirm-password')));
    await tester.pump();
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });

  testWidgets('10 sheet not dismissed by tapping scrim', (tester) async {
    await openSheet(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });
}
