import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Future<UserProfile?> fetchProfile(String uid);
}
