import {
  DISCLOSURE_CATEGORY_CATALOG_VERSION,
  DISCLOSURE_NOTICE_VERSION,
} from "./constants";

/** When false, consent-dependent identifying disclosure call paths fail closed (legal gate). */
export function isIdentifyingDisclosureLegallyActivated(): boolean {
  return process.env.SIBOL_DISCLOSURE_LEGAL_GATE === "true";
}

export function disclosureNoticeVersion(): string {
  return DISCLOSURE_NOTICE_VERSION;
}

export function disclosureCategoryCatalogVersion(): string {
  return DISCLOSURE_CATEGORY_CATALOG_VERSION;
}
