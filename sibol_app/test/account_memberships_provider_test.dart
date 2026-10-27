import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_repository.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

class _FakeOrgRepository implements OrganizationRepository {
  _FakeOrgRepository(this._streams);

  final Map<String, Stream<List<OrganizationMembership>>> _streams;
  String? lastOrgId;
  String? lastAccountUid;

  @override
  Stream<List<OrganizationMembership>> watchMembershipForOrg({
    required String orgId,
    required String accountUid,
  }) {
    lastOrgId = orgId;
    lastAccountUid = accountUid;
    return _streams['$orgId::$accountUid'] ?? Stream.value(const []);
  }

  @override
  Stream<Organization?> watchOrganization(String orgId) =>
      Stream.value(null);

  @override
  Future<Organization?> fetchOrganization(String orgId) async => null;

  @override
  Future<OrganizationMembership?> fetchMembership(String membershipId) async =>
      null;
}

OrganizationMembership _membership({
  required String orgId,
  required String uid,
  required List<String> caps,
}) {
  final now = DateTime(2026);
  return OrganizationMembership(
    membershipId: 'mbr_${orgId}__$uid',
    orgId: orgId,
    accountUid: uid,
    status: MembershipStatus.active,
    capabilities: caps,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const uidA = 'WZj7Seh3qNUlGfnDaYbL1RBA4bNV';
  const orgId = 'barangay03';

  UserProfile barangayProfile(String uid, {String? primaryOrgId}) {
    return UserProfile(
      uid: uid,
      role: SibolRole.barangay,
      displayName: 'Staff',
      active: true,
      createdAt: DateTime(2026),
      primaryOrgId: primaryOrgId,
    );
  }

  test('uses primaryOrgId for canonical membership listen', () async {
    final repo = _FakeOrgRepository({
      '$orgId::$uidA': Stream.value([
        _membership(
          orgId: orgId,
          uid: uidA,
          caps: ['org.manage_members', 'org.manage_roles'],
        ),
      ]),
    });
    final container = ProviderContainer(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(repo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(AuthUser(uid: uidA, email: 'a@sibol.local')),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(barangayProfile(uidA, primaryOrgId: orgId)),
        ),
      ],
    );
    container.listen(accountMembershipsProvider, (_, __) {});
    await pumpEventQueue(times: 5);
    final memberships = container.read(accountMembershipsProvider).value;
    expect(memberships, isNotNull);
    expect(memberships, hasLength(1));
    expect(repo.lastOrgId, orgId);
    expect(repo.lastAccountUid, uidA);
    expect(container.read(orgAdminManagedOrgIdsProvider), [orgId]);
    container.dispose();
  });

  test('central administrator has admin access without org-admin membership',
      () async {
    const centralUid = 'wibfqrFWxTR614NVBYpkGJkp3Lh1';
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(
            AuthUser(uid: centralUid, email: 'central.admin@sibol.local'),
          ),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(
            UserProfile(
              uid: centralUid,
              role: SibolRole.barangay,
              displayName: 'Central',
              active: true,
              createdAt: DateTime(2026),
              isCentralAdmin: true,
            ),
          ),
        ),
      ],
    );
    container.listen(userProfileProvider, (_, __) {});
    await pumpEventQueue(times: 5);
    expect(container.read(isCentralAdminProvider), isTrue);
    expect(container.read(orgAdminManagedOrgIdsProvider), isEmpty);
    expect(container.read(canAccessAdministrationProvider), isTrue);
    container.dispose();
  });

  test('missing primaryOrgId yields empty memberships without repository call', () async {
    final repo = _FakeOrgRepository({});
    final container = ProviderContainer(
      overrides: [
        organizationRepositoryProvider.overrideWithValue(repo),
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(AuthUser(uid: uidA, email: 'a@sibol.local')),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream.value(barangayProfile(uidA, primaryOrgId: null)),
        ),
      ],
    );
    container.listen(accountMembershipsProvider, (_, __) {});
    await pumpEventQueue(times: 5);
    expect(container.read(accountMembershipsProvider).value, isEmpty);
    expect(repo.lastOrgId, isNull);
    container.dispose();
  });
}
