import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sibol_app/features/auth/data/repositories/user_profile_repository_impl.dart';
import 'package:sibol_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sibol_app/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:sibol_app/features/cases/data/repositories/case_repository_impl.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';
import 'package:sibol_app/features/teenager/data/repositories/assistance_request_repository_impl.dart';
import 'package:sibol_app/features/teenager/domain/repositories/assistance_request_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return CaseRepositoryImpl(ref.watch(firestoreProvider));
});

final assistanceRequestRepositoryProvider =
    Provider<AssistanceRequestRepository>((ref) {
  return AssistanceRequestRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});
