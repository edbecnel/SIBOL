#!/usr/bin/env node
/**
 * Compare Cloud Functions exported in repo vs firebase functions:list (live).
 */
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const indexPath = join(root, "shared/functions/src/index.ts");
const indexSource = readFileSync(indexPath, "utf8");
const repoFunctions = [
  ...indexSource.matchAll(/^export const (\w+) = /gm),
].map((m) => m[1]);

const project = process.env.FIREBASE_PROJECT_ID ?? "sibol-286d0";
const list = spawnSync(
  "firebase",
  ["functions:list", "--project", project, "--json"],
  { encoding: "utf8" },
);
let liveFunctions = [];
if (list.status === 0) {
  try {
    const parsed = JSON.parse(list.stdout);
    liveFunctions = (parsed.result ?? []).map((f) => f.entryPoint ?? f.id);
  } catch {
    liveFunctions = (list.stdout.match(/│ (\w+) /g) ?? []).map((s) =>
      s.replace(/│ /, "").trim(),
    );
  }
} else {
  console.error(list.stderr || list.stdout);
  process.exit(1);
}

const demoCritical = [
  "regRegisterTeenAccount",
  "regSubmitTeenAssistanceRequest",
  "regAcknowledgeTeenAssistanceRequest",
  "createCoordinationReferral",
  "regResolveRegisteredTeenForCase",
  "regListRegisteredTeensForCase",
  "regListBarangayDirectory",
  "regSyncRegisteredTeenCasesFromProfile",
  "healthCheck",
];

const missingOnLive = repoFunctions.filter((n) => !liveFunctions.includes(n));
const missingCritical = demoCritical.filter((n) => !liveFunctions.includes(n));

console.log(
  JSON.stringify(
    {
      project,
      repoExportCount: repoFunctions.length,
      liveDeployedCount: liveFunctions.length,
      liveDeployed: liveFunctions.sort(),
      missingOnLive: missingOnLive.sort(),
      missingCriticalForDemo: missingCritical,
    },
    null,
    2,
  ),
);
