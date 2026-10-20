#!/usr/bin/env node
/**
 * Seeds fictional SIBOL demonstration users and cases via Firebase Admin SDK.
 *
 * Install dependencies first:
 *   cd shared/provisioning && npm install
 *
 * Usage (dry-run, no Firebase writes):
 *   export FIREBASE_PROJECT_ID=sibol-286d0
 *   export SIBOL_DEMO_PASSWORD_TEEN='...'
 *   export SIBOL_DEMO_PASSWORD_BARANGAY='...'
 *   export SIBOL_DEMO_PASSWORD_MOPH='...'
 *   npm run seed -- --dry-run --confirm-project=sibol-286d0
 *
 * Live provisioning (separate PA authorization required):
 *   npm run seed -- --confirm-project=sibol-286d0
 *
 * Optional read-only remote inspection:
 *   npm run seed -- --dry-run --remote-read --confirm-project=sibol-286d0
 */

import { applicationDefault, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

import { parseArgv, resolveProjectId } from "./src/config.mjs";
import {
  formatDryRunReport,
  planProvisioningOperations,
  runLocalPreflight,
} from "./src/preflight.mjs";
import { collectRemoteSnapshot, executeProvisioning } from "./src/provision.mjs";

async function main() {
  const argv = process.argv.slice(2);
  const flags = parseArgv(argv);

  const preflight = runLocalPreflight({ argv, requirePasswords: true });
  if (!preflight.ok) {
    console.error(preflight.message);
    process.exit(1);
  }

  let remoteSnapshot = null;
  if (flags.remoteRead) {
    if (!getApps().length) {
      initializeApp({
        projectId: preflight.projectId,
        credential: applicationDefault(),
      });
    }
    const auth = getAuth();
    const db = getFirestore();
    remoteSnapshot = await collectRemoteSnapshot({
      auth,
      db,
      users: preflight.users,
      casePlans: preflight.casePlans,
    });
    console.log("Remote read-only snapshot collected (no writes).");
  }

  const operations = planProvisioningOperations({
    users: preflight.users,
    casePlans: preflight.casePlans,
    remoteSnapshot,
  });

  if (flags.dryRun) {
    console.log(formatDryRunReport(preflight, operations));
    console.log("\nDry-run complete. No Firebase writes were performed.");
    return;
  }

  if (!getApps().length) {
    initializeApp({
      projectId: preflight.projectId,
      credential: applicationDefault(),
    });
  }

  const auth = getAuth();
  const db = getFirestore();
  await executeProvisioning({ auth, db, users: preflight.users });
  console.log("Seed complete (fictional data only).");
}

main().catch((err) => {
  console.error(err?.message || "Provisioning failed.");
  process.exit(1);
});
