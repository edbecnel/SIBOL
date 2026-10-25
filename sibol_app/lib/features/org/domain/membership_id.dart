/// Canonical organization membership document ids (REG-A / shared/reg).
abstract final class MembershipId {
  static const _separator = '__';
  static final _orgIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$');
  static final _accountUidPattern = RegExp(r'^[A-Za-z0-9]{20,128}$');

  static bool isValidOrgId(String orgId) {
    if (orgId.isEmpty || orgId.length > 128) return false;
    if (orgId == '.' || orgId == '..') return false;
    if (orgId.contains(_separator) || orgId.contains('/')) return false;
    return _orgIdPattern.hasMatch(orgId);
  }

  static bool isValidAccountUid(String accountUid) {
    return _accountUidPattern.hasMatch(accountUid);
  }

  static String forOrgAndAccount(String orgId, String accountUid) {
    if (!isValidOrgId(orgId)) {
      throw ArgumentError.value(orgId, 'orgId', 'invalid orgId');
    }
    if (!isValidAccountUid(accountUid)) {
      throw ArgumentError.value(accountUid, 'accountUid', 'invalid accountUid');
    }
    return 'mbr_$orgId$_separator$accountUid';
  }
}
