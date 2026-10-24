#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "../../..");
const configName =
  process.env.SIBOL_FIREBASE_EMULATOR_CONFIG ?? "firebase.emulator-smoke-isolated.json";
const config = resolve(repoRoot, configName);
const portsPath = resolve(repoRoot, "shared/emulator/smoke_isolated_ports.json");
const ports = JSON.parse(readFileSync(portsPath, "utf8"));
const functionsDir = resolve(repoRoot, "shared/functions");

const build = spawnSync("npm", ["run", "build"], {
  cwd: functionsDir,
  stdio: "inherit",
});
if (build.status !== 0) {
  process.exit(build.status ?? 1);
}

const command =
  "node --test --test-concurrency=1 --test-force-exit ../integration/test/int001_scenarios.smoke.mjs ../integration/test/prototype_journey.smoke.mjs";

const firestoreHost = `127.0.0.1:${ports.firestore}`;
const authHost = `127.0.0.1:${ports.auth}`;

const result = spawnSync(
  `firebase emulators:exec --config "${config}" --only auth,firestore --project sibol-286d0 "${command}"`,
  {
    cwd: functionsDir,
    stdio: "inherit",
    env: {
      ...process.env,
      NODE_PATH: resolve(functionsDir, "node_modules"),
      FIRESTORE_EMULATOR_HOST: firestoreHost,
      FIREBASE_AUTH_EMULATOR_HOST: authHost,
      FIREBASE_PROJECT_ID: "sibol-286d0",
      SIBOL_EMULATOR_PASSWORD_TEEN: "int-smoke-teen-only-local",
      SIBOL_EMULATOR_PASSWORD_BARANGAY_STAFF: "int-smoke-bns-only-local",
      SIBOL_EMULATOR_PASSWORD_MOPH_STAFF: "int-smoke-moph-only-local",
      SIBOL_EMULATOR_PASSWORD_CENTRAL: "int-smoke-central-only-local",
      SIBOL_EMULATOR_PASSWORD_BARANGAY_ORG_ADMIN: "int-smoke-boa-only-local",
      SIBOL_EMULATOR_PASSWORD_BACKUP_BARANGAY_ORG_ADMIN: "int-smoke-backup-only-local",
      SIBOL_EMULATOR_PASSWORD_MOPH_ORG_ADMIN: "int-smoke-moa-only-local",
    },
    shell: true,
  },
);

process.exit(result.status ?? 1);
