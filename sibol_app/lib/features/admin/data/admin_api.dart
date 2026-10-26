import 'package:cloud_functions/cloud_functions.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';

class OrganizationStaffDirectory {
  OrganizationStaffDirectory({
    required this.organizationType,
    required this.memberships,
  });

  final OrganizationType organizationType;
  final List<Map<String, dynamic>> memberships;
}

class AdminApi {
  AdminApi(this._functions);

  final FirebaseFunctions _functions;

  Future<void> bootstrapCentralAdminForEmulator() async {
    await _functions.httpsCallable('bootstrapCentralAdminForEmulator').call({
      'confirm': true,
    });
  }

  Future<Map<String, dynamic>> createOrganization({
    required String type,
    required String name,
    required String initialOrgAdminEmail,
    String? legacyBarangayLabel,
  }) async {
    final result = await _functions.httpsCallable('regCreateOrganization').call({
      'type': type,
      'name': name,
      'initialOrgAdminEmail': initialOrgAdminEmail,
      if (legacyBarangayLabel != null) 'legacyBarangayLabel': legacyBarangayLabel,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> createBarangayOrganization({
    required String idempotencyKey,
    required String psgcVersion,
    required String psgcRegionCode,
    String? psgcProvinceCode,
    required String psgcCityMunCode,
    required String psgcBarangayCode,
    required String initialOrgAdminEmail,
    String? displayNameAlias,
    String? legacyBarangayLabel,
  }) async {
    final result =
        await _functions.httpsCallable('regCreateBarangayOrganization').call({
      'idempotencyKey': idempotencyKey,
      'psgcVersion': psgcVersion,
      'psgcRegionCode': psgcRegionCode,
      if (psgcProvinceCode != null) 'psgcProvinceCode': psgcProvinceCode,
      'psgcCityMunCode': psgcCityMunCode,
      'psgcBarangayCode': psgcBarangayCode,
      'initialOrgAdminEmail': initialOrgAdminEmail,
      if (displayNameAlias != null) 'displayNameAlias': displayNameAlias,
      if (legacyBarangayLabel != null) 'legacyBarangayLabel': legacyBarangayLabel,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> createHospitalOrganization({
    required String idempotencyKey,
    required String nhfrSnapshotVersion,
    required String nhfrFacilityCode,
    required String psgcVersion,
    required String psgcRegionCode,
    String? psgcProvinceCode,
    required String psgcCityMunCode,
    String? psgcBarangayCode,
    required String initialOrgAdminEmail,
    String? displayNameAlias,
  }) async {
    final result =
        await _functions.httpsCallable('regCreateHospitalOrganization').call({
      'idempotencyKey': idempotencyKey,
      'nhfrSnapshotVersion': nhfrSnapshotVersion,
      'nhfrFacilityCode': nhfrFacilityCode,
      'psgcVersion': psgcVersion,
      'psgcRegionCode': psgcRegionCode,
      if (psgcProvinceCode != null) 'psgcProvinceCode': psgcProvinceCode,
      'psgcCityMunCode': psgcCityMunCode,
      if (psgcBarangayCode != null) 'psgcBarangayCode': psgcBarangayCode,
      'initialOrgAdminEmail': initialOrgAdminEmail,
      if (displayNameAlias != null) 'displayNameAlias': displayNameAlias,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> listOrganizations() async {
    final result = await _functions.httpsCallable('regListOrganizations').call();
    final list = (result.data as Map)['organizations'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> setOrganizationStatus({
    required String orgId,
    required String status,
  }) async {
    await _functions.httpsCallable('regSetOrganizationStatus').call({
      'orgId': orgId,
      'status': status,
    });
  }

  Future<OrganizationStaffDirectory> listMemberships(String orgId) async {
    final result =
        await _functions.httpsCallable('regListOrganizationMemberships').call({
      'orgId': orgId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final orgTypeRaw = data['organizationType'] as String? ?? 'barangay';
    final orgType = orgTypeRaw == 'hospital'
        ? OrganizationType.hospital
        : OrganizationType.barangay;
    final list = data['memberships'] as List<dynamic>? ?? [];
    return OrganizationStaffDirectory(
      organizationType: orgType,
      memberships:
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  Future<void> resetStaffMemberPassword({
    required String orgId,
    required String targetAccountUid,
    required String newPassword,
  }) async {
    await _functions.httpsCallable('regResetStaffMemberPassword').call({
      'orgId': orgId,
      'targetAccountUid': targetAccountUid,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> appointOrganizationAdmin({
    required String orgId,
    required String email,
  }) async {
    final result =
        await _functions.httpsCallable('regAppointOrganizationAdmin').call({
      'orgId': orgId,
      'email': email,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> provisionStaffMember({
    required String orgId,
    required String email,
    required String displayName,
    required String password,
    required List<String> capabilities,
    String? clientOperationId,
  }) async {
    final result =
        await _functions.httpsCallable('regProvisionStaffMember').call({
      'orgId': orgId,
      'email': email,
      'displayName': displayName,
      'password': password,
      'capabilities': capabilities,
      if (clientOperationId != null) 'clientOperationId': clientOperationId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> inviteStaffMember({
    required String orgId,
    required String email,
    List<String>? capabilities,
  }) async {
    final result = await _functions.httpsCallable('regInviteStaffMember').call({
      'orgId': orgId,
      'email': email,
      if (capabilities != null) 'capabilities': capabilities,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> listStaffInvitations(String orgId) async {
    final result =
        await _functions.httpsCallable('regListStaffInvitations').call({
      'orgId': orgId,
    });
    final list = (result.data as Map)['invitations'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listMyPendingInvitations() async {
    final result =
        await _functions.httpsCallable('regListMyPendingInvitations').call();
    final list = (result.data as Map)['invitations'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationId) async {
    final result =
        await _functions.httpsCallable('regAcceptStaffInvitation').call({
      'invitationId': invitationId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> approveMembership(String membershipId) async {
    await _functions.httpsCallable('regApproveMembership').call({
      'membershipId': membershipId,
    });
  }

  Future<void> updateMembershipCapabilities({
    required String membershipId,
    required List<String> capabilities,
  }) async {
    await _functions.httpsCallable('regUpdateMembershipCapabilities').call({
      'membershipId': membershipId,
      'capabilities': capabilities,
    });
  }

  Future<void> suspendMembership(String membershipId) async {
    await _functions.httpsCallable('regSuspendMembership').call({
      'membershipId': membershipId,
    });
  }

  Future<void> reactivateMembership(String membershipId) async {
    await _functions.httpsCallable('regReactivateMembership').call({
      'membershipId': membershipId,
    });
  }

  Future<void> revokeMembership(String membershipId) async {
    await _functions.httpsCallable('regRevokeMembership').call({
      'membershipId': membershipId,
    });
  }

  Future<void> revokeInvitation(String invitationId) async {
    await _functions.httpsCallable('regRevokeInvitation').call({
      'invitationId': invitationId,
    });
  }
}
