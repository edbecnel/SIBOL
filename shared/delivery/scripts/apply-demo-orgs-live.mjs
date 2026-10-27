#!/usr/bin/env node
/**
 * Idempotent demo organizations/memberships/directory for live `sibol-286d0`.
 * Does not create Auth users or touch case document fields (except profile org merges).
 *
 * Usage (PA-authorized live only):
 *   cd shared/provisioning && npm install
 *   node ../delivery/scripts/apply-demo-orgs-live.mjs --confirm-project=sibol-286d0
 */
import { parseArgs } from "node:util";
import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { ensureDemoOrganizationsAndMemberships } from "../../provisioning/src/demo_org_membership.mjs";
import { DEMO_USER_SPECS } from "../../provisioning/src/constants.mjs";

const { values } = parseArgs({
  options: {
    "confirm-project": { type: "string" },
  },
});

const project = "sibol-286d0";
if (values["confirm-project"] !== project) {
  console.error(`Refusing to run without --confirm-project=${project}`);
  process.exit(1);
}

initializeApp({ projectId: project, credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();

const users = [];
for (const spec of DEMO_USER_SPECS) {
  const record = await auth.getUserByEmail(spec.email);
  users.push({ uid: record.uid, role: spec.role });
}

await ensureDemoOrganizationsAndMemberships(db, users, console);
console.log("Demo org/membership/directory apply complete.");
