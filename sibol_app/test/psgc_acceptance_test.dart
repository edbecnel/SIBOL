import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/geo/data/psgc_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('official bundle includes Barangay Tres acceptance chain', () async {
    final bundle = await PsgcBundle.load(version: 'psgc-psa-2025-2q');
    expect(bundle.synthetic, isFalse);

    final region = bundle.node('1000000000');
    final province = bundle.node('1004300000');
    final balingasag = bundle.node('1004302000');
    final tres = bundle.node('1004302022');

    expect(region?.officialName, contains('Region X'));
    expect(province?.officialName, 'Misamis Oriental');
    expect(balingasag?.officialName, 'Balingasag');
    expect(tres?.officialName, contains('Barangay 3'));
    expect(tres?.parentCode, balingasag?.code);
    expect(balingasag?.parentCode, province?.code);
    expect(province?.parentCode, region?.code);

    final provinces = bundle.provincesUnderRegion('1000000000');
    expect(provinces.any((p) => p.code == '1004300000'), isTrue);

    final barangays = bundle.children('1004302000', 'barangay');
    expect(barangays.any((b) => b.code == '1004302022'), isTrue);
  });

  test('synthetic bundle is flagged', () async {
    final bundle = await PsgcBundle.load(version: 'psgc-synthetic-demo-v1');
    expect(bundle.synthetic, isTrue);
    expect(bundle.regions().first.officialName, contains('Synthetic'));
  });
}
