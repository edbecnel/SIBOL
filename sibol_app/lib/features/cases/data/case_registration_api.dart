import 'package:cloud_functions/cloud_functions.dart';

class RegisteredTeenListEntry {
  const RegisteredTeenListEntry({
    required this.teenUid,
    required this.displayName,
  });

  final String teenUid;
  final String displayName;
}

class ResolvedRegisteredTeenForCase {
  const ResolvedRegisteredTeenForCase({
    required this.teenUid,
    required this.fullName,
    this.dateOfBirth,
    this.barangay,
    this.contactEmail,
    this.contactPhone,
    this.parentGuardianContact,
    this.linkedAccountEmail,
    required this.resolvedAt,
  });

  final String teenUid;
  final String fullName;
  final String? dateOfBirth;
  final String? barangay;
  final String? contactEmail;
  final String? contactPhone;
  final String? parentGuardianContact;
  final String? linkedAccountEmail;
  final DateTime resolvedAt;

  factory ResolvedRegisteredTeenForCase.fromMap(Map<String, dynamic> map) {
    return ResolvedRegisteredTeenForCase(
      teenUid: map['teenUid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String?,
      barangay: map['barangay'] as String?,
      contactEmail: map['contactEmail'] as String?,
      contactPhone: map['contactPhone'] as String?,
      parentGuardianContact: map['parentGuardianContact'] as String?,
      linkedAccountEmail: map['linkedAccountEmail'] as String?,
      resolvedAt: DateTime.tryParse(map['resolvedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class CaseRegistrationApi {
  CaseRegistrationApi(this._functions);

  final FirebaseFunctions _functions;

  Future<List<RegisteredTeenListEntry>> listRegisteredTeens({
    required String orgId,
  }) async {
    final result =
        await _functions.httpsCallable('regListRegisteredTeensForCase').call({
      'orgId': orgId,
    });
    final data = result.data as Map<Object?, Object?>?;
    final teens = data?['teens'] as List<Object?>? ?? [];
    return teens.map((entry) {
      final map = Map<String, dynamic>.from(entry! as Map);
      return RegisteredTeenListEntry(
        teenUid: map['teenUid'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
      );
    }).toList();
  }

  Future<ResolvedRegisteredTeenForCase> resolveRegisteredTeen({
    required String orgId,
    required String teenUid,
  }) async {
    final result =
        await _functions.httpsCallable('regResolveRegisteredTeenForCase').call({
      'orgId': orgId,
      'teenUid': teenUid,
    });
    return ResolvedRegisteredTeenForCase.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}
