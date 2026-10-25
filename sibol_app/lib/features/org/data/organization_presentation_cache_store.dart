import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';

const _storageKeyPrefix = 'sibol.org_presentation.v1';

/// Last-known directory-derived presentation, scoped per authenticated user and org.
abstract class OrganizationPresentationCachePersistence {
  Future<BarangayOrganizationPresentation?> load({
    required String accountUid,
    required String orgId,
  });

  Future<void> save({
    required String accountUid,
    required String orgId,
    required BarangayOrganizationPresentation presentation,
    DateTime? directoryUpdatedAt,
  });

  Future<void> clearForUser(String accountUid);
}

class OrganizationPresentationCacheStore
    implements OrganizationPresentationCachePersistence {
  OrganizationPresentationCacheStore(this._storage);

  final FlutterSecureStorage _storage;

  String _keyFor(String accountUid, String orgId) =>
      '$_storageKeyPrefix.$accountUid.$orgId';

  @override
  Future<BarangayOrganizationPresentation?> load({
    required String accountUid,
    required String orgId,
  }) async {
    final uid = accountUid.trim();
    final oid = orgId.trim();
    if (uid.isEmpty || oid.isEmpty) return null;
    final raw = await _storage.read(key: _keyFor(uid, oid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final name = (map['organizationName'] as String?)?.trim() ?? '';
      final site = (map['siteLabel'] as String?)?.trim() ?? '';
      if (name.isEmpty || site.length < 2) return null;
      return BarangayOrganizationPresentation(
        organizationName: name,
        siteLabel: site,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save({
    required String accountUid,
    required String orgId,
    required BarangayOrganizationPresentation presentation,
    DateTime? directoryUpdatedAt,
  }) async {
    final uid = accountUid.trim();
    final oid = orgId.trim();
    if (uid.isEmpty || oid.isEmpty) return;
    final name = presentation.organizationName.trim();
    final site = presentation.siteLabel.trim();
    if (name.isEmpty || site.length < 2) return;
    final payload = <String, dynamic>{
      'orgId': oid,
      'organizationName': name,
      'siteLabel': site,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      if (directoryUpdatedAt != null)
        'directoryUpdatedAt': directoryUpdatedAt.toUtc().toIso8601String(),
    };
    await _storage.write(
      key: _keyFor(uid, oid),
      value: jsonEncode(payload),
    );
  }

  @override
  Future<void> clearForUser(String accountUid) async {
    // Secure storage has no prefix delete; callers clear known org keys in tests.
    final uid = accountUid.trim();
    if (uid.isEmpty) return;
    await _storage.delete(key: '$_storageKeyPrefix.$uid');
  }
}
