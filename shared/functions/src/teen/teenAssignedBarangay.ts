import { AuthzError } from "../authz/assert";
import { loadPsgcBundle, PsgcNode, validateBarangaySelection } from "../geo/psgc";
import type { RegisterTeenInput } from "./registerTeenAccount";

function formatAssignedBarangayFromChain(chain: PsgcNode[]): string {
  const barangay = chain.find((n) => n.level === "barangay");
  const cityMun = chain.find((n) => n.level === "city_mun");
  if (!barangay || !cityMun) {
    throw new AuthzError(
      "Unable to derive Barangay label from geographic selection.",
      "failed-precondition",
    );
  }
  return `${barangay.officialName}, ${cityMun.officialName}`;
}

/**
 * Assistance routing label for teen profiles. Organization ID remains authoritative;
 * this field is the human-readable Barangay identity required by assistance submission.
 */
export function resolveTeenAssignedBarangayLabel(
  org: Record<string, unknown>,
  input: RegisterTeenInput,
): string {
  const psgcCode = input.selectedBarangayPsgcCode?.trim();
  if (psgcCode) {
    const version = input.psgcVersion?.trim();
    if (!version) {
      throw new AuthzError("psgcVersion is required.", "invalid-argument");
    }
    const bundle = loadPsgcBundle(version);
    const validated = validateBarangaySelection(bundle, {
      psgcVersion: version,
      psgcRegionCode: input.psgcRegionCode?.trim() ?? "",
      psgcProvinceCode: input.psgcProvinceCode ?? null,
      psgcCityMunCode: input.psgcCityMunCode?.trim() ?? "",
      psgcBarangayCode: psgcCode,
    });
    if (!validated.ok) {
      throw new AuthzError(validated.error, "invalid-argument");
    }
    return formatAssignedBarangayFromChain(validated.nodes);
  }

  const legacy =
    typeof org.legacyBarangayLabel === "string"
      ? org.legacyBarangayLabel.trim()
      : "";
  if (legacy.length >= 2) {
    return legacy;
  }

  throw new AuthzError(
    "Selected Barangay organization cannot provide an assistance routing label. Use geographic registration or set legacyBarangayLabel on the organization.",
    "failed-precondition",
  );
}
