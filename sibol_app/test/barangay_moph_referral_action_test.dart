import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/barangay_moph_referral_action.dart';

void main() {
  Future<void> pumpAction(
    WidgetTester tester, {
    required bool isAcknowledged,
    required AsyncValue<bool> referralExists,
    VoidCallback? onReferPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarangayMophReferralAction(
            isAcknowledged: isAcknowledged,
            referralExistsAsync: referralExists,
            onReferPressed: onReferPressed ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('acknowledged request displays referral action', (tester) async {
    await pumpAction(
      tester,
      isAcknowledged: true,
      referralExists: const AsyncValue.data(false),
    );

    expect(find.text('Refer to MOPH coordination'), findsOneWidget);
  });

  testWidgets('unacknowledged request does not display referral action',
      (tester) async {
    await pumpAction(
      tester,
      isAcknowledged: false,
      referralExists: const AsyncValue.data(false),
    );

    expect(find.text('Refer to MOPH coordination'), findsNothing);
  });

  testWidgets('tapping the action invokes callback', (tester) async {
    var tapped = false;
    await pumpAction(
      tester,
      isAcknowledged: true,
      referralExists: const AsyncValue.data(false),
      onReferPressed: () => tapped = true,
    );

    await tester.tap(find.text('Refer to MOPH coordination'));
    expect(tapped, isTrue);
  });

  testWidgets('already-referred request cannot submit another referral',
      (tester) async {
    await pumpAction(
      tester,
      isAcknowledged: true,
      referralExists: const AsyncValue.data(true),
    );

    expect(find.text('Refer to MOPH coordination'), findsNothing);
    expect(
      find.textContaining('referral already submitted'),
      findsOneWidget,
    );
  });

  testWidgets('errors during eligibility checks are surfaced', (tester) async {
    await pumpAction(
      tester,
      isAcknowledged: true,
      referralExists: AsyncValue.error(
        StateError('rules denied'),
        StackTrace.empty,
      ),
    );

    expect(
      find.textContaining('Could not verify whether a MOPH referral'),
      findsOneWidget,
    );
    expect(find.text('Refer to MOPH coordination'), findsNothing);
  });
}
