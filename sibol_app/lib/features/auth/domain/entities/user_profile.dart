import 'package:equatable/equatable.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.active,
    required this.createdAt,
  });

  final String uid;
  final SibolRole role;
  final String displayName;
  final bool active;
  final DateTime createdAt;

  @override
  List<Object?> get props => [uid, role, displayName, active, createdAt];
}
