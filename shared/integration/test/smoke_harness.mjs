import { createRequire } from "node:module";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadEmulatorDemoUsers } from "../../provisioning/src/emulator_seed.mjs";
import { executeEmulatorDemoSeed } from "../../provisioning/src/emulator_seed.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const require = createRequire(resolve(__dirname, "../../functions/package.json"));
const admin = require("firebase-admin");
const { Timestamp: smokeTimestamp } = require("firebase-admin/firestore");

export { smokeTimestamp };

const projectId = "demo-sibol-emulator";

export function getSmokeDb() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }
  return admin.firestore();
}

export function getSmokeAuth() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }
  return admin.auth();
}

let seedResult;
let seedInflight;

export async function ensureDemoSeed() {
  if (seedResult) return seedResult;
  if (!seedInflight) {
    seedInflight = (async () => {
      const { users, missing } = loadEmulatorDemoUsers();
      if (missing.length) {
        throw new Error(`Missing smoke passwords: ${missing.join(", ")}`);
      }
      seedResult = await executeEmulatorDemoSeed({
        auth: getSmokeAuth(),
        db: getSmokeDb(),
        users,
      });
      return seedResult;
    })();
  }
  return seedInflight;
}

export async function cleanupSmokeApps() {
  for (const app of admin.apps) {
    if (app) await app.delete();
  }
  seedResult = undefined;
}
