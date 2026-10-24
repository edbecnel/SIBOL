import { readFileSync } from "node:fs";
import { join } from "node:path";

export type PsgcNode = {
  code: string;
  level: "region" | "province" | "city_mun" | "barangay";
  officialName: string;
  parentCode: string | null;
  cityClass?: string;
};

export type PsgcBundle = {
  version: string;
  synthetic?: boolean;
  nodes: PsgcNode[];
};

const SUPPORTED = new Set(["psgc-synthetic-demo-v1"]);

function bundlePath(version: string): string {
  return join(__dirname, "..", "..", "geo-data", `${version}.json`);
}

export function loadPsgcBundle(version: string): PsgcBundle {
  if (!SUPPORTED.has(version)) {
    throw new Error(`unsupported psgc version: ${version}`);
  }
  const raw = readFileSync(bundlePath(version), "utf8");
  return JSON.parse(raw) as PsgcBundle;
}

export function indexPsgc(bundle: PsgcBundle): Map<string, PsgcNode> {
  const map = new Map<string, PsgcNode>();
  for (const node of bundle.nodes) {
    map.set(node.code, node);
  }
  return map;
}

export function barangayIdentityKey(psgcBarangayCode: string): string {
  return `barangay:PSGC:${psgcBarangayCode}`;
}

export function validateBarangaySelection(
  bundle: PsgcBundle,
  selection: {
    psgcVersion: string;
    psgcRegionCode: string;
    psgcProvinceCode?: string | null;
    psgcCityMunCode: string;
    psgcBarangayCode: string;
  },
): { ok: true; nodes: PsgcNode[] } | { ok: false; error: string } {
  if (bundle.version !== selection.psgcVersion) {
    return { ok: false, error: "unsupported psgc version" };
  }
  const byCode = indexPsgc(bundle);
  const barangay = byCode.get(selection.psgcBarangayCode);
  if (!barangay || barangay.level !== "barangay") {
    return { ok: false, error: "invalid barangay code" };
  }
  const chain: PsgcNode[] = [barangay];
  let current: PsgcNode = barangay;
  while (current.parentCode) {
    const parent = byCode.get(current.parentCode);
    if (!parent) {
      return { ok: false, error: "broken parent chain" };
    }
    chain.push(parent);
    current = parent;
  }
  const region = chain.find((n) => n.level === "region");
  const cityMun = chain.find((n) => n.level === "city_mun");
  const province = chain.find((n) => n.level === "province");
  if (!region || region.code !== selection.psgcRegionCode) {
    return { ok: false, error: "region mismatch" };
  }
  if (!cityMun || cityMun.code !== selection.psgcCityMunCode) {
    return { ok: false, error: "city/mun mismatch" };
  }
  const provCode = selection.psgcProvinceCode?.trim() || null;
  if (provCode) {
    if (!province || province.code !== provCode) {
      return { ok: false, error: "province mismatch" };
    }
  } else if (province) {
    return { ok: false, error: "province required for path" };
  }
  return { ok: true, nodes: chain };
}

export function supportedPsgcVersions(): string[] {
  return [...SUPPORTED];
}
