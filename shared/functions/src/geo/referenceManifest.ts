import { supportedNhfrVersions } from "./nhfr";
import { supportedPsgcVersions } from "./psgc";

export function runGetReferenceManifest() {
  return {
    supportedPsgcVersions: supportedPsgcVersions(),
    recommendedPsgcVersion: "psgc-synthetic-demo-v1",
    supportedNhfrSnapshotVersions: supportedNhfrVersions(),
    recommendedNhfrSnapshotVersion: "nhfr-synthetic-demo-v1",
    syntheticOnly: true,
  };
}
