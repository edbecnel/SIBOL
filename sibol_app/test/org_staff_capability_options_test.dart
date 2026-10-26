import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/admin/domain/org_staff_capability_options.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';

void main() {
  test('barangay capability options exclude hospital coordination', () {
    final caps = OrgStaffCapabilityOptions.capabilitiesFor(
      OrganizationType.barangay,
    );
    expect(caps, contains(OrgCapabilities.reportSubmit));
    expect(caps, isNot(contains(OrgCapabilities.coordinationHospital)));
  });

  test('hospital capability options use coordination.hospital only', () {
    final caps = OrgStaffCapabilityOptions.capabilitiesFor(
      OrganizationType.hospital,
    );
    expect(caps, equals([OrgCapabilities.coordinationHospital]));
  });
}
