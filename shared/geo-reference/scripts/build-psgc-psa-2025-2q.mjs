/**
 * Build SIBOL PSGC graph bundle from PSA-sourced quarterly JSON (via @jobuntux/psgc build input).
 * Origin: Philippine Statistics Authority PSGC — see manifests/psgc-psa-2025-2q.json
 */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const dataDir = join(root, "node_modules", "@jobuntux", "psgc", "data", "2025-2Q");
const version = "psgc-psa-2025-2q";

function trimName(s) {
  return (s ?? "").trim().replace(/\s+/g, " ");
}

function cityClassForMun(name) {
  const n = trimName(name);
  if (n.startsWith("City of ") || n.endsWith(" City")) return "component_city";
  return "municipality";
}

function loadJson(name) {
  return JSON.parse(readFileSync(join(dataDir, name), "utf8"));
}

const regions = loadJson("regions.json");
const provinces = loadJson("provinces.json");
const muncities = loadJson("muncities.json");
const barangays = loadJson("barangays.json");

const regionByReg = new Map(regions.map((r) => [r.regCode, r.psgcCode]));
const provinceByRegProv = new Map(
  provinces
    .filter((p) => !p.cityClass)
    .map((p) => [`${p.regCode}:${p.provCode}`, p.psgcCode]),
);

const nodes = [];

for (const r of regions) {
  nodes.push({
    code: r.psgcCode,
    level: "region",
    officialName: trimName(r.regionName),
    parentCode: null,
  });
}

for (const p of provinces) {
  const regionCode = regionByReg.get(p.regCode);
  if (!regionCode) continue;
  if (p.cityClass === "HUC" || p.cityClass === "ICC") {
    nodes.push({
      code: p.psgcCode,
      level: "city_mun",
      officialName: trimName(p.provName),
      parentCode: regionCode,
      cityClass: p.cityClass,
    });
  } else {
    nodes.push({
      code: p.psgcCode,
      level: "province",
      officialName: trimName(p.provName),
      parentCode: regionCode,
    });
  }
}

for (const m of muncities) {
  const parentCode = provinceByRegProv.get(`${m.regCode}:${m.provCode}`);
  if (!parentCode) continue;
  nodes.push({
    code: m.psgcCode,
    level: "city_mun",
    officialName: trimName(m.munCityName),
    parentCode,
    cityClass: cityClassForMun(m.munCityName),
  });
}

for (const b of barangays) {
  const munCode = `${b.regCode}:${b.provCode}:${b.munCityCode}`;
  const parentMun = muncities.find(
    (m) =>
      m.regCode === b.regCode &&
      m.provCode === b.provCode &&
      m.munCityCode === b.munCityCode,
  );
  if (!parentMun) continue;
  nodes.push({
    code: b.psgcCode,
    level: "barangay",
    officialName: trimName(b.brgyName),
    parentCode: parentMun.psgcCode,
  });
}

const bundle = {
  version,
  synthetic: false,
  source: {
    originator: "Philippine Statistics Authority (PSA)",
    publicationTitle: "Philippine Standard Geographic Code (PSGC)",
    publicationDate: "2025-06-30",
    psaPage: "https://psa.gov.ph/classification/psgc",
    buildInputPackage: "@jobuntux/psgc@0.2.1",
    buildInputDataset: "2025-2Q",
    buildInputNote:
      "Normalized from PSA quarterly release packaged for build reproducibility; acknowledge PSA as source.",
    retrievedAt: new Date().toISOString(),
  },
  nodes,
};

const artifactDir = join(root, "artifacts");
mkdirSync(artifactDir, { recursive: true });
const artifactPath = join(artifactDir, `${version}.json`);
const json = JSON.stringify(bundle);
writeFileSync(artifactPath, json);
const sha256 = createHash("sha256").update(json).digest("hex");

const manifest = {
  version,
  synthetic: false,
  generatedAt: new Date().toISOString(),
  sourceUrl: "https://psa.gov.ph/classification/psgc",
  sourcePublicationDate: "2025-06-30",
  sourceRetrievedAt: bundle.source.retrievedAt,
  reuseDetermination:
    "PSA publishes PSGC for public statistical use; in-app attribution required (see SIBOL-GEO-001).",
  artifactFile: `artifacts/${version}.json`,
  sha256,
  recordCounts: {
    regions: nodes.filter((n) => n.level === "region").length,
    provinces: nodes.filter((n) => n.level === "province").length,
    city_mun: nodes.filter((n) => n.level === "city_mun").length,
    barangay: nodes.filter((n) => n.level === "barangay").length,
  },
};

mkdirSync(join(root, "manifests"), { recursive: true });
writeFileSync(join(root, "manifests", `${version}.json`), JSON.stringify(manifest, null, 2));

const counts = manifest.recordCounts;
console.log(`Wrote ${artifactPath} (${nodes.length} nodes, sha256=${sha256.slice(0, 12)}…)`);
console.log(counts);

// Acceptance spot-check
const tres = nodes.find((n) => n.code === "1004302022");
const balingasag = nodes.find((n) => n.code === "1004302000");
const misOr = nodes.find((n) => n.code === "1004300000");
const r10 = nodes.find((n) => n.code === "1000000000");
if (!tres || !balingasag || !misOr || !r10) {
  throw new Error("acceptance chain missing in built bundle");
}
console.log("Acceptance: Region X → Misamis Oriental → Balingasag →", tres.officialName);
