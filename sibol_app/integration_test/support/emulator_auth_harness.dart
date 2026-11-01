import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/router/app_router.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'emulator_test_accounts.dart';
import 'wait_for_widget.dart';

/// Reusable sign-in / sign-out for emulator device acceptance (real UI + Firebase Auth).
class EmulatorAuthHarness {
  EmulatorAuthHarness(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  GoRouter get router => container.read(appRouterProvider);

  Future<void> signInAsTeenager(String password) => signInWithEmail(
        EmulatorTestAccounts.teenEmail,
        password,
        expectedRole: SibolRole.teen,
      );

  Future<void> signInAsBarangay(String password) => signInWithEmail(
        EmulatorTestAccounts.barangayEmail,
        password,
        expectedRole: SibolRole.barangay,
      );

  Future<void> signInAsMoph(String password) => signInWithEmail(
        EmulatorTestAccounts.mophEmail,
        password,
        expectedRole: SibolRole.moph,
      );

  Future<void> signOutCurrentUser() async {
    await container.read(authControllerProvider.notifier).signOut();
    router.go(Routes.welcome);
    await pumpUntilFound(
      tester,
      find.textContaining('Welcome to'),
      timeout: const Duration(seconds: 25),
    );
    expect(
      FirebaseAuth.instance.currentUser,
      isNull,
      reason: 'Firebase session should clear after sign out.',
    );
  }

  Future<void> switchRole({
    required String email,
    required String password,
    required SibolRole expectedRole,
  }) async {
    await signOutCurrentUser();
    await signInWithEmail(email, password, expectedRole: expectedRole);
  }

  Future<void> signInWithEmail(
    String email,
    String password, {
    required SibolRole expectedRole,
  }) async {
    router.go(Routes.login);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Email',
      ),
      timeout: const Duration(seconds: 20),
    );

    if (find.widgetWithText(TextButton, 'Sign in').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(TextButton, 'Sign in').first);
      await tester.pump(const Duration(milliseconds: 400));
    }

    final emailField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Email',
    );
    await tester.enterText(emailField, email);
    final passwordField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Password',
    );
    await tester.enterText(passwordField, password);

    final submit = find.widgetWithText(ElevatedButton, 'Sign in');
    if (submit.evaluate().isEmpty) {
      await tester.tap(find.text('Sign in').last);
    } else {
      await tester.tap(submit);
    }

    await _waitForFirebaseAuth(email);
    await FirebaseAuth.instance.currentUser!.getIdToken(true);
    await tester.pump(const Duration(milliseconds: 300));
    await _assertFirestoreProfileReachable(expectedRole);

    await assertRoleHomeLoaded(expectedRole);
    await assertSessionIdentity(email: email, expectedRole: expectedRole);
  }

  Future<void> _waitForFirebaseAuth(String email) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == email) {
        return;
      }
      if (find.textContaining('Invalid email or password').evaluate().isNotEmpty) {
        fail('Sign-in rejected invalid credentials for $email.');
      }
      if (find.textContaining('Could not sign in').evaluate().isNotEmpty) {
        fail('Sign-in failed for $email (see login error on screen).');
      }
    }
    fail('Firebase Auth did not return signed-in user for $email.');
  }

  Future<void> _assertFirestoreProfileReachable(SibolRole expectedRole) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!snap.exists) {
        fail(
          'Firestore emulator returned no users/$uid document (server read). '
          'Confirm canonical emulators are running and seeded for demo-sibol-emulator.',
        );
      }
      if (snap.data()?['role'] != expectedRole.firestoreValue) {
        fail('Profile role mismatch on server read.');
      }
    } on FirebaseException catch (e) {
      fail(
        'Firestore server read failed (${e.code}): ${e.message}. '
        'Android may not reach host Firestore on port ${EmulatorConfig.firestorePort} '
        '(try adb reverse tcp:${EmulatorConfig.firestorePort} tcp:${EmulatorConfig.firestorePort}).',
      );
    }
  }

  Future<void> assertRoleHomeLoaded(SibolRole role) async {
    final dashboardTitle = switch (role) {
      SibolRole.teen => 'Teenager dashboard',
      SibolRole.barangay => 'Barangay dashboard',
      SibolRole.moph => 'MOPH dashboard',
    };

    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 500));

      if (find.text('Account not ready').evaluate().isNotEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        DocumentSnapshot<Map<String, dynamic>>? snap;
        if (uid != null) {
          snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        }
        fail(
          'Signed in (uid=$uid) but app routed to Account not ready. '
          'Direct Firestore get exists=${snap?.exists}. '
          'If exists=true but UI fails, check profile parsing or router state. '
          'If exists=false, run ./shared/scripts/seed-emulator-demo.sh or clear app data '
          '(adb pm clear) to drop stale offline cache.',
        );
      }
      if (find.text('Could not load your profile').evaluate().isNotEmpty) {
        fail('Profile stream error after sign-in — check Firestore emulator connectivity.');
      }
      if (find.text(dashboardTitle).evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Role home "$dashboardTitle" not reached within timeout.');
  }

  Future<void> assertSessionIdentity({
    required String email,
    required SibolRole expectedRole,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == email) {
        break;
      }
    }
    final user = FirebaseAuth.instance.currentUser;
    expect(user, isNotNull);
    expect(user!.email, email);

    final profileSnap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    expect(profileSnap.exists, isTrue, reason: 'users/{uid} must exist in Firestore emulator.');
    final data = profileSnap.data()!;
    expect(data['role'], expectedRole.firestoreValue);
    expect(data['active'], isTrue);

    if (expectedRole == SibolRole.barangay || expectedRole == SibolRole.moph) {
      expect(data['primaryOrgId'], isNotNull);
    }
    if (expectedRole == SibolRole.teen) {
      expect(data['selectedBarangayOrgId'], isNotNull);
    }

    final authUser = container.read(authStateChangesProvider).value;
    expect(authUser?.uid, user.uid);
  }
}

EmulatorAuthHarness harnessFor(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SibolApp)),
  );
  return EmulatorAuthHarness(tester, container);
}

Finder primaryButton(String label) => find.widgetWithText(ElevatedButton, label);
