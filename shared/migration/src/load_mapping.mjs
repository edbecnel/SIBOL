import { readFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { isValidOrgId } from "../../reg/src/org_id.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));

export function loadOrgMapping(mappingPath) {
  const path =
    mappingPath ??
    resolve(__dirname, "../fixtures/demo_org_mapping.json");
  const raw = JSON.parse(readFileSync(path, "utf8"));
  const barangayEntries = Object.entries(raw.barangayLabels ?? {});
  const barangayByLabel = new Map(barangayEntries);
  const hospitalByName = new Map(Object.entries(raw.hospital ?? {}));

  const barangayOrgIds = barangayEntries.map(([, id]) => id);
  const uniqueOrgIds = new Set(barangayOrgIds);
  if (uniqueOrgIds.size !== barangayOrgIds.length) {
    throw new Error("duplicate orgId across barangayLabels is not allowed");
  }

  for (const [, orgId] of barangayByLabel) {
    if (!isValidOrgId(orgId)) {
      throw new Error(`invalid orgId in barangayLabels: ${orgId}`);
    }
  }
  for (const [, orgId] of hospitalByName) {
    if (!isValidOrgId(orgId)) {
      throw new Error(`invalid orgId in hospital: ${orgId}`);
    }
  }

  return { barangayByLabel, hospitalByName, raw };
}

export function resolveBarangayOrgId(label, mapping) {
  if (!label || typeof label !== "string") {
    return { orgId: null, error: "missing label" };
  }
  const trimmed = label.trim();
  if (!mapping.barangayByLabel.has(trimmed)) {
    return { orgId: null, error: `unmapped barangay label: ${trimmed}` };
  }
  return { orgId: mapping.barangayByLabel.get(trimmed), error: null };
}
