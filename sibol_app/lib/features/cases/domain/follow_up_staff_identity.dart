import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

/// Human-readable staff attribution for follow-up rows (audit UID preserved separately).
class FollowUpStaffIdentity {
  static String recordedByLine(FollowUp followUp) {
    final name = followUp.createdByDisplayName?.trim();
    final email = followUp.createdByStaffEmail?.trim();
    if (name != null && name.isNotEmpty) {
      if (email != null && email.isNotEmpty) {
        return 'Recorded by $name ($email)';
      }
      return 'Recorded by $name';
    }
    if (email != null && email.isNotEmpty) {
      return 'Recorded by $email';
    }
    final uid = followUp.createdByUid?.trim();
    if (uid != null && uid.isNotEmpty) {
      return 'Recorded by staff ($uid)';
    }
    return 'Recorded by staff';
  }
}
