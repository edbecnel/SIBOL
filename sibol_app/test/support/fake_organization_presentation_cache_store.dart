import 'package:sibol_app/features/org/data/organization_presentation_cache_store.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';

class FakeOrganizationPresentationCacheStore
    implements OrganizationPresentationCachePersistence {
  final Map<String, BarangayOrganizationPresentation> _byKey = {};

  String _key(String accountUid, String orgId) => '$accountUid::$orgId';

  @override
  Future<BarangayOrganizationPresentation?> load({
    required String accountUid,
    required String orgId,
  }) async {
    return _byKey[_key(accountUid, orgId)];
  }

  @override
  Future<void> save({
    required String accountUid,
    required String orgId,
    required BarangayOrganizationPresentation presentation,
    DateTime? directoryUpdatedAt,
  }) async {
    _byKey[_key(accountUid, orgId)] = presentation;
  }

  @override
  Future<void> clearForUser(String accountUid) async {
    _byKey.removeWhere((k, _) => k.startsWith('$accountUid::'));
  }
}
