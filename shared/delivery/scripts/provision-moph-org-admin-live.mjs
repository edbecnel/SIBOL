#!/usr/bin/env node
/**
 * Live-only: provision moph.org.admin@sibol.local for hospital01 (Auth + profile + org-admin membership).
 * Idempotent. Never logs passwords. Does not copy emulator UIDs.
 */
import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { membershipIdFor } from "../../reg/src/membership_id.mjs";
import { CAPABILITIES } from "../../reg/src/capabilities.mjs";
import { DEMO_HOSPITAL_ORG_ID } from "../../provisioning/src/constants.mjs";

const PROJECT = "sibol-286d0";
const ORG_ID = DEMO_HOSPITAL_ORG_ID;
const EMAIL = "moph.org.admin@sibol.local";
const DISPLAY_NAME = "Demo MOPH Org Administrator";
const PASSWORD_ENV = "SIBOL_EMULATOR_PASSWORD_MOPH_ORG_ADMIN";
const ORDINARY_MOPH_EMAIL = "moph.demo@sibol.local";

const ORG_ADMIN_CAPS = [
  CAPABILITIES.ORG_MANAGE_MEMBERS,
  CAPABILITIES.ORG_MANAGE_ROLES,
];

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../../..");

function loadEnvFile(path) {
  if (!existsSync(path)) return {};
  const out = {};
  for (const line of readFileSync(path, "utf8").split("\n")) {
    let trimmed = line.trim();
    if (trimmed.startsWith("export ")) trimmed = trimmed.slice(7).trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let val = trimmed.slice(eq + 1).trim();
    if (
      (val.startsWith('"') && val.endsWith('"')) ||
      (val.startsWith("'") && val.endsWith("'"))
    ) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

const { values } = parseArgs({
  options: {
    "dry-run": { type: "boolean", default: false },
    execute: { type: "boolean", default: false },
    "confirm-project": { type: "string" },
    "env-file": { type: "string" },
  },
});

if (!values["dry-run"] && !values.execute) {
  console.error("Pass --dry-run or --execute");
  process.exit(1);
}
if (values.execute && values["confirm-project"] !== PROJECT) {
  console.error(`Execute requires --confirm-project=${PROJECT}`);
  process.exit(1);
}

const envFile =
  values["env-file"] ?? resolve(REPO_ROOT, ".env.emulator.local");
const fileEnv = loadEnvFile(envFile);
const passwordAvailable = Boolean(
  (process.env[PASSWORD_ENV] ?? fileEnv[PASSWORD_ENV] ?? "").trim(),
);

initializeApp({ projectId: PROJECT, credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();

let existingAuth = null;
try {
  existingAuth = await auth.getUserByEmail(EMAIL);
} catch (e) {
  if (e.code !== "auth/user-not-found") throw e;
}

const orgSnap = await db.collection("organizations").doc(ORG_ID).get();
const orgData = orgSnap.exists ? orgSnap.data() : null;

let ordinaryMophUid = null;
try {
  ordinaryMophUid = (await auth.getUserByEmail(ORDINARY_MOPH_EMAIL)).uid;
} catch {
  ordinaryMophUid = null;
}

let membershipId = null;
let existingMembership = null;
if (existingAuth?.uid) {
  membershipId = membershipIdFor(ORG_ID, existingAuth.uid);
  const mSnap = await db
    .collection("organizationMemberships")
    .doc(membershipId)
    .get();
  if (mSnap.exists) existingMembership = mSnap.data();
}

let profileSnap = null;
if (existingAuth?.uid) {
  profileSnap = await db.collection("users").doc(existingAuth.uid).get();
}

const plan = {
  project: PROJECT,
  email: EMAIL,
  orgId: ORG_ID,
  mode: values.execute ? "execute" : "dry-run",
  passwordSourceEnvVar: PASSWORD_ENV,
  passwordAvailableForExecute: passwordAvailable,
  organizationExists: orgSnap.exists,
  organizationType: orgData?.type ?? null,
  organizationStatus: orgData?.status ?? null,
  organizationName: orgData?.name ?? null,
  ordinaryMophStaffEmail: ORDINARY_MOPH_EMAIL,
  ordinaryMophUid,
  existingAuthUid: existingAuth?.uid ?? null,
  actions: [],
};

if (!orgSnap.exists) {
  plan.actions.push({ type: "error", reason: "organization_missing", orgId: ORG_ID });
} else if (orgData?.type !== "hospital") {
  plan.actions.push({
    type: "error",
    reason: "organization_type_mismatch",
    expected: "hospital",
    actual: orgData?.type,
  });
} else if (orgData?.status !== "active") {
  plan.actions.push({
    type: "error",
    reason: "organization_not_active",
    status: orgData?.status,
  });
} else if (!existingAuth) {
  plan.actions.push({ type: "create_auth_user", email: EMAIL });
  plan.actions.push({ type: "create_user_profile", role: "moph", active: true });
  plan.actions.push({
    type: "create_membership",
    orgId: ORG_ID,
    status: "active",
    capabilities: ORG_ADMIN_CAPS,
    membershipRole: "moph_org_admin",
  });
  plan.actions.push({ type: "set_primary_org_id", orgId: ORG_ID });
} else {
  if (!passwordAvailable && values.execute) {
    plan.actions.push({ type: "error", reason: "password_unavailable", envVar: PASSWORD_ENV });
  } else {
    plan.actions.push({ type: "reconcile_auth_password", uid: existingAuth.uid });
  }
  if (!profileSnap?.exists) {
    plan.actions.push({
      type: "create_user_profile",
      uid: existingAuth.uid,
      role: "moph",
      active: true,
    });
  } else {
    const data = profileSnap.data() ?? {};
    if (data.role !== "moph") {
      plan.actions.push({ type: "patch_profile", field: "role", value: "moph" });
    }
    if (data.active !== true) {
      plan.actions.push({ type: "patch_profile", field: "active", value: true });
    }
    if (data.isCentralAdmin === true) {
      plan.actions.push({ type: "patch_profile", field: "isCentralAdmin", value: false });
    }
    if (!data.primaryOrgId) {
      plan.actions.push({ type: "set_primary_org_id", orgId: ORG_ID });
    }
  }
  if (!existingMembership) {
    plan.actions.push({
      type: "create_membership",
      membershipId,
      orgId: ORG_ID,
      status: "active",
      capabilities: ORG_ADMIN_CAPS,
      membershipRole: "moph_org_admin",
    });
  } else {
    const caps = existingMembership.capabilities ?? [];
    const missing = ORG_ADMIN_CAPS.filter((c) => !caps.includes(c));
    if (existingMembership.status !== "active" || missing.length > 0) {
      plan.actions.push({
        type: "reconcile_membership",
        membershipId,
        status: "active",
        capabilities: ORG_ADMIN_CAPS,
        patch: { status: existingMembership.status, missingCapabilities: missing },
      });
    }
  }
}

plan.blueprint = {
  email: EMAIL,
  displayName: DISPLAY_NAME,
  role: "moph",
  orgId: ORG_ID,
  membershipCapabilities: ORG_ADMIN_CAPS,
  emulatorBlueprintKey: "moph_org_admin",
};

if (values["dry-run"]) {
  console.log(JSON.stringify(plan, null, 2));
  process.exit(plan.actions.some((a) => a.type === "error") ? 1 : 0);
}

if (plan.actions.some((a) => a.type === "error")) {
  console.error(JSON.stringify(plan, null, 2));
  process.exit(1);
}

const password = (
  process.env[PASSWORD_ENV] ??
  fileEnv[PASSWORD_ENV] ??
  ""
).trim();

let uid = existingAuth?.uid;
if (!uid) {
  const created = await auth.createUser({
    email: EMAIL,
    password,
    displayName: DISPLAY_NAME,
  });
  uid = created.uid;
} else {
  await auth.updateUser(uid, { password, displayName: DISPLAY_NAME });
}

const now = Timestamp.now();
const profileRef = db.collection("users").doc(uid);
const profileDoc = await profileRef.get();
const profilePayload = {
  role: "moph",
  displayName: DISPLAY_NAME,
  active: true,
  primaryOrgId: ORG_ID,
  isCentralAdmin: false,
};
if (!profileDoc.exists) {
  await profileRef.set({ ...profilePayload, createdAt: now });
} else {
  await profileRef.set(profilePayload, { merge: true });
}

const membershipIdFinal = membershipIdFor(ORG_ID, uid);
const mRef = db.collection("organizationMemberships").doc(membershipIdFinal);
const mDoc = await mRef.get();
if (!mDoc.exists) {
  await mRef.set({
    membershipId: membershipIdFinal,
    orgId: ORG_ID,
    accountUid: uid,
    status: "active",
    capabilities: ORG_ADMIN_CAPS,
    createdAt: now,
    updatedAt: now,
  });
} else {
  await mRef.set(
    {
      status: "active",
      capabilities: ORG_ADMIN_CAPS,
      updatedAt: now,
    },
    { merge: true },
  );
}

console.log(
  JSON.stringify(
    {
      ...plan,
      mode: "execute",
      uid,
      membershipId: membershipIdFinal,
      completed: true,
    },
    null,
    2,
  ),
);
