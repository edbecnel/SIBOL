import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/data/models/organization_directory_entry_model.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';

void main() {
  test('fromFirestore maps cached directory document fields', () {
    final model = OrganizationDirectoryEntryModel.fromFirestore({
      'orgId': 'barangay03',
      'name': 'Barangay 3 (Poblacion)',
      'type': 'barangay',
      'status': 'active',
      'geographicSiteLabel': 'Barangay 3, Balingasag',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
    });

    final entity = model.toEntity();
    expect(entity, isNotNull);
    expect(entity!.name, 'Barangay 3 (Poblacion)');
    expect(entity.type, OrganizationType.barangay);
    expect(entity.geographicSiteLabel, 'Barangay 3, Balingasag');
  });
}
