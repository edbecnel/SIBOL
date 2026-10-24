import 'package:cloud_functions/cloud_functions.dart';

class BarangayDirectoryEntry {
  BarangayDirectoryEntry({
    required this.orgId,
    required this.name,
    this.legacyBarangayLabel,
  });

  final String orgId;
  final String name;
  final String? legacyBarangayLabel;

  factory BarangayDirectoryEntry.fromMap(Map<String, dynamic> map) {
    return BarangayDirectoryEntry(
      orgId: map['orgId'] as String,
      name: map['name'] as String,
      legacyBarangayLabel: map['legacyBarangayLabel'] as String?,
    );
  }
}

class TeenRegistrationApi {
  TeenRegistrationApi(this._functions);

  final FirebaseFunctions _functions;

  Future<List<BarangayDirectoryEntry>> listBarangayDirectory() async {
    final result = await _functions.httpsCallable('regListBarangayDirectory').call();
    final list = (result.data as Map)['organizations'] as List<dynamic>? ?? [];
    return list
        .map((e) => BarangayDirectoryEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> registerTeenAccount({
    required String selectedBarangayOrgId,
    String? displayName,
    required bool privacyConsentAcknowledged,
  }) async {
    final result = await _functions.httpsCallable('regRegisterTeenAccount').call({
      'selectedBarangayOrgId': selectedBarangayOrgId,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      'privacyConsentAcknowledged': privacyConsentAcknowledged,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
