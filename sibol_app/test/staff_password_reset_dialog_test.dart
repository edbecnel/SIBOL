import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/admin/presentation/widgets/staff_password_reset_dialog.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                showStaffPasswordResetFormDialog(
                  context: context,
                  displayName: 'Demo Barangay Org Administrator',
                  email: 'barangay.org.admin@sibol.local',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens Reset password dialog', (tester) async {
    await openDialog(tester);
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byKey(const Key('staff-reset-temporary-password')), findsOneWidget);
    expect(find.byKey(const Key('staff-reset-confirm-password')), findsOneWidget);
  });

  testWidgets('confirm field focus keeps dialog open', (tester) async {
    await openDialog(tester);
    await tester.tap(find.byKey(const Key('staff-reset-confirm-password')));
    await tester.pump();
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });

  testWidgets('temporary password field focus keeps dialog open', (tester) async {
    await openDialog(tester);
    await tester.tap(find.byKey(const Key('staff-reset-temporary-password')));
    await tester.pump();
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });

  testWidgets('keyboard inset keeps actions accessible via scroll', (tester) async {
    tester.view.physicalSize = const Size(400, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 640),
          viewInsets: EdgeInsets.only(bottom: 280),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: StaffPasswordResetFormDialog(
              displayName: 'Demo',
              email: 'barangay.org.admin@sibol.local',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('staff-reset-continue')), findsOneWidget);
    expect(find.byKey(const Key('staff-reset-cancel')), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('password mismatch shows validation without closing', (tester) async {
    await openDialog(tester);
    await tester.enterText(
      find.byKey(const Key('staff-reset-temporary-password')),
      'TempPass123!',
    );
    await tester.enterText(
      find.byKey(const Key('staff-reset-confirm-password')),
      'Different456!',
    );
    await tester.tap(find.byKey(const Key('staff-reset-continue')));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.byType(StaffPasswordResetFormDialog), findsOneWidget);
  });

  testWidgets('matching passwords close dialog with result', (tester) async {
    StaffPasswordResetFormResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showStaffPasswordResetFormDialog(
                  context: context,
                  displayName: 'Demo',
                  email: 'barangay.org.admin@sibol.local',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
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

    expect(result, isNotNull);
    expect(result!.password, 'TempPass123!');
    expect(find.byType(StaffPasswordResetFormDialog), findsNothing);
  });

  testWidgets('password fields support visibility toggle', (tester) async {
    await openDialog(tester);
    expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    await tester.tap(find.byIcon(Icons.visibility_outlined).first);
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
  });
}
