import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';

/// Operational capabilities an org administrator may assign when provisioning staff.
abstract final class OrgStaffCapabilityOptions {
  static List<String> labelsFor(OrganizationType type) {
    return capabilitiesFor(type);
  }

  static List<String> capabilitiesFor(OrganizationType type) {
    switch (type) {
      case OrganizationType.barangay:
        return const [
          OrgCapabilities.caseRead,
          OrgCapabilities.caseWrite,
          OrgCapabilities.reportSubmit,
          OrgCapabilities.coordinationBarangay,
        ];
      case OrganizationType.hospital:
        return const [OrgCapabilities.coordinationHospital];
    }
  }

  static List<String> defaultSelection(OrganizationType type) {
    switch (type) {
      case OrganizationType.barangay:
        return const [
          OrgCapabilities.caseRead,
          OrgCapabilities.caseWrite,
        ];
      case OrganizationType.hospital:
        return const [OrgCapabilities.coordinationHospital];
    }
  }
}
