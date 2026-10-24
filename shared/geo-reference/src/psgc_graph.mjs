/**
 * PSGC reference graph validation (synthetic or official bundles).
 */

const LEVELS = new Set(["region", "province", "city_mun", "barangay"]);

/**
 * @param {object} bundle
 * @returns {Map<string, object>}
 */
export function indexNodes(bundle) {
  const map = new Map();
  for (const node of bundle.nodes ?? []) {
    map.set(node.code, node);
  }
  return map;
}

/**
 * @param {Map<string, object>} byCode
 * @param {string} code
 * @param {string} level
 */
export function getNode(byCode, code, level) {
  const node = byCode.get(code);
  if (!node || node.level !== level) {
    return null;
  }
  return node;
}

/**
 * Walk parent chain from barangay to region.
 * @returns {{ ok: true, chain: object[] } | { ok: false, error: string }}
 */
export function validateBarangayChain(byCode, barangayCode) {
  const barangay = getNode(byCode, barangayCode, "barangay");
  if (!barangay) {
    return { ok: false, error: "invalid barangay code" };
  }
  const chain = [barangay];
  let current = barangay;
  while (current.parentCode) {
    const parent = byCode.get(current.parentCode);
    if (!parent) {
      return { ok: false, error: "broken parent chain" };
    }
    chain.push(parent);
    current = parent;
  }
  const region = chain.find((n) => n.level === "region");
  if (!region) {
    return { ok: false, error: "region not reached" };
  }
  return { ok: true, chain };
}

/**
 * @param {object} bundle
 * @param {object} selection
 */
export function validateBarangaySelection(bundle, selection) {
  if (bundle.version !== selection.psgcVersion) {
    return { ok: false, error: "unsupported psgc version" };
  }
  const byCode = indexNodes(bundle);
  const chainResult = validateBarangayChain(byCode, selection.psgcBarangayCode);
  if (!chainResult.ok) {
    return chainResult;
  }
  const region = chainResult.chain.find((n) => n.level === "region");
  const cityMun = chainResult.chain.find((n) => n.level === "city_mun");
  const province = chainResult.chain.find((n) => n.level === "province");
  if (!region || region.code !== selection.psgcRegionCode) {
    return { ok: false, error: "region mismatch" };
  }
  if (!cityMun || cityMun.code !== selection.psgcCityMunCode) {
    return { ok: false, error: "city/mun mismatch" };
  }
  if (selection.psgcProvinceCode) {
    if (!province || province.code !== selection.psgcProvinceCode) {
      return { ok: false, error: "province mismatch" };
    }
  } else if (province) {
    return { ok: false, error: "province required for path" };
  }
  return { ok: true, chain: chainResult.chain };
}

export function listLguParentsUnderRegion(byCode, regionCode) {
  const out = [];
  for (const node of byCode.values()) {
    if (node.parentCode === regionCode && node.level === "province") {
      out.push(node);
    }
    if (
      node.parentCode === regionCode &&
      node.level === "city_mun" &&
      node.cityClass === "HUC"
    ) {
      out.push(node);
    }
  }
  return out.sort((a, b) => a.officialName.localeCompare(b.officialName));
}

export function listChildren(byCode, parentCode, level) {
  return [...byCode.values()]
    .filter((n) => n.parentCode === parentCode && n.level === level)
    .sort((a, b) => a.officialName.localeCompare(b.officialName));
}

export function supportedVersions() {
  return ["psgc-synthetic-demo-v1"];
}
