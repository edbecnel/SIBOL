import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/domain/membership_id.dart';

void main() {
  const uid = 'WZj7Seh3qNUlGfnDaYbL1RBA4bNV';

  test('forOrgAndAccount builds canonical id', () {
    expect(
      MembershipId.forOrgAndAccount('barangay03', uid),
      'mbr_barangay03__$uid',
    );
  });

  test('rejects invalid org id', () {
    expect(
      () => MembershipId.forOrgAndAccount('not/valid', uid),
      throwsArgumentError,
    );
  });
}
