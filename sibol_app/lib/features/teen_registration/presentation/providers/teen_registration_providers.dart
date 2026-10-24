import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/teen_registration/data/teen_registration_api.dart';

final teenRegistrationApiProvider = Provider<TeenRegistrationApi>((ref) {
  return TeenRegistrationApi(FirebaseFunctions.instance);
});

final barangayDirectoryProvider =
    FutureProvider<List<BarangayDirectoryEntry>>((ref) async {
  return ref.watch(teenRegistrationApiProvider).listBarangayDirectory();
});
