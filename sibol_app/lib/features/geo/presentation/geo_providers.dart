import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/geo/data/nhfr_bundle.dart';
import 'package:sibol_app/features/geo/data/psgc_bundle.dart';

final psgcBundleProvider = FutureProvider<PsgcBundle>((ref) async {
  return PsgcBundle.load();
});

final nhfrBundleProvider = FutureProvider<NhfrBundle>((ref) async {
  return NhfrBundle.load();
});
