export function findFacility(bundle, nhfrFacilityCode) {
  return (bundle.facilities ?? []).find(
    (f) => f.nhfrFacilityCode === nhfrFacilityCode,
  );
}

export function validateHospitalFacility(bundle, code) {
  const row = findFacility(bundle, code);
  if (!row) {
    return { ok: false, error: "unknown facility code" };
  }
  if (row.facilityType !== "hospital") {
    return { ok: false, error: "facility type not in scope" };
  }
  return { ok: true, row };
}

export function supportedNhfrVersions() {
  return ["nhfr-synthetic-demo-v1"];
}
