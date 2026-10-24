#!/usr/bin/env node
/**
 * Seeds fictional SIBOL demonstration data into Firebase **emulators only**.
 *
 * Prerequisites:
 *   - Auth, Firestore (and optionally Functions) emulators running
 *   - FIRESTORE_EMULATOR_HOST=127.0.0.1:8195
 *   - FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
 *   - FIREBASE_PROJECT_ID=sibol-286d0
 *   - Password env vars (see Docs/Operations/SIBOL-INT-001-Emulator-Demonstration-Runbook.md)
 *
 * Usage:
 *   cd shared/provisioning && npm install
 *   npm run seed:emulator -- --confirm-emulator-demo
 */

import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import { assertEmulatorEnvironment } from "./src/emulator_guard.mjs";
import {
  executeEmulatorDemoSeed,
  loadEmulatorDemoUsers,
} from "./src/emulator_seed.mjs";

function parseArgv(argv) {
  return {
    confirmEmulatorDemo: argv.includes("--confirm-emulator-demo"),
    dryRun: argv.includes("--dry-run"),
  };
}

async function main() {
  const flags = parseArgv(process.argv.slice(2));
  const guard = await assertEmulatorEnvironment({
    confirmFlag: flags.confirmEmulatorDemo,
    checkReachable: !flags.dryRun,
  });
  if (!guard.ok) {
    console.error(guard.message);
    process.exit(1);
  }

  const { users, missing } = loadEmulatorDemoUsers();
  if (missing.length) {
    console.error(
      `Missing password environment variables: ${missing.join("; ")}`,
    );
    process.exit(1);
  }

  if (flags.dryRun) {
    console.log(
      `Dry-run OK: would seed ${users.length} emulator users into project ${guard.projectId}.`,
    );
    for (const u of users) {
      console.log(`  - ${u.email} (${u.key})`);
    }
    return;
  }

  if (!getApps().length) {
    initializeApp({ projectId: guard.projectId });
  }

  const auth = getAuth();
  const db = getFirestore();
  await executeEmulatorDemoSeed({ auth, db, users });
  console.log("Emulator demonstration seed complete (fictional data only).");
}

main().catch((err) => {
  console.error(err?.message || "Emulator seed failed.");
  process.exit(1);
});
