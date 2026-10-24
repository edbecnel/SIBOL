import { readFileSync } from "node:fs";
import { join } from "node:path";

export type NhfrFacilityRow = {
  nhfrFacilityCode: string;
  facilityOfficialName: string;
  facilityType: string;
  psgcCityMunCode?: string;
  psgcRegionCode?: string;
};

export type NhfrBundle = {
  version: string;
  synthetic?: boolean;
  facilities: NhfrFacilityRow[];
};

const SUPPORTED = new Set(["nhfr-synthetic-demo-v1"]);

function bundlePath(version: string): string {
  return join(__dirname, "..", "..", "geo-data", `${version}.json`);
}

export function loadNhfrBundle(version: string): NhfrBundle {
  if (!SUPPORTED.has(version)) {
    throw new Error(`unsupported nhfr version: ${version}`);
  }
  const raw = readFileSync(bundlePath(version), "utf8");
  return JSON.parse(raw) as NhfrBundle;
}

export function hospitalIdentityKey(code: string): string {
  return `hospital:NHFR:${code}`;
}

export function validateHospitalFacility(
  bundle: NhfrBundle,
  nhfrFacilityCode: string,
): { ok: true; row: NhfrFacilityRow } | { ok: false; error: string } {
  const row = bundle.facilities.find((f) => f.nhfrFacilityCode === nhfrFacilityCode);
  if (!row) {
    return { ok: false, error: "unknown facility code" };
  }
  if (row.facilityType !== "hospital") {
    return { ok: false, error: "facility type not in scope" };
  }
  return { ok: true, row };
}

export function supportedNhfrVersions(): string[] {
  return [...SUPPORTED];
}
