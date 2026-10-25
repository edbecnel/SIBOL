import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  Organization barangayOrg({
    String? legacyBarangayLabel,
    OrganizationStatus status = OrganizationStatus.active,
  }) {
    return Organization(
      orgId: 'barangay03',
      type: OrganizationType.barangay,
      name: 'Barangay 3 (Poblacion)',
      status: status,
      createdAt: now,
      updatedAt: now,
      legacyBarangayLabel: legacyBarangayLabel,
    );
  }

  test('fromOrganization returns name and site label when registry is complete', () {
    final presentation = BarangayOrganizationPresentation.fromOrganization(
      barangayOrg(legacyBarangayLabel: 'Barangay 3, Balingasag'),
    );
    expect(presentation?.organizationName, 'Barangay 3 (Poblacion)');
    expect(presentation?.siteLabel, 'Barangay 3, Balingasag');
  });

  test('fromOrganization rejects missing legacy site label', () {
    expect(
      BarangayOrganizationPresentation.fromOrganization(barangayOrg()),
      isNull,
    );
  });

  test('fromOrganization rejects suspended organizations', () {
    expect(
      BarangayOrganizationPresentation.fromOrganization(
        barangayOrg(
          legacyBarangayLabel: 'Barangay 3, Balingasag',
          status: OrganizationStatus.suspended,
        ),
      ),
      isNull,
    );
  });
}
