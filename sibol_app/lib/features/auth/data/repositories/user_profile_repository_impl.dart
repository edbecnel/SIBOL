import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/auth/data/models/user_profile_model.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserProfileModel.fromFirestore(snap.id, snap.data()!).toEntity();
    });
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfileModel.fromFirestore(snap.id, snap.data()!).toEntity();
  }
}
