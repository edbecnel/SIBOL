#!/usr/bin/env node
/**
 * Launcher for shared/provisioning/seed_tranche1_demo.mjs so firebase-admin
 * resolves from shared/provisioning/node_modules (no NODE_PATH).
 *
 * Preferred:
 *   cd shared/provisioning && npm install && npm run seed -- [flags]
 */
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const provisioningDir = join(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "provisioning",
);

const result = spawnSync(
  process.execPath,
  [join(provisioningDir, "seed_tranche1_demo.mjs"), ...process.argv.slice(2)],
  {
    stdio: "inherit",
    env: process.env,
    cwd: provisioningDir,
  },
);

process.exit(result.status ?? 1);
