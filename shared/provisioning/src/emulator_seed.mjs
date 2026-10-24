import { membershipIdFor } from "../../reg/src/membership_id.mjs";
import { CAPABILITIES } from "../../reg/src/capabilities.mjs";
import {
  DEMO_ASSIGNED_BARANGAY,
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_NAME,
  DEMO_HOSPITAL_ORG_ID,
} from "./constants.mjs";
import {
  EMULATOR_DEMO_ASSISTANCE_INBOX_ID,
  EMULATOR_DEMO_USER_BLUEPRINTS,
} from "./emulator_demo_constants.mjs";

const BARANGAY_STAFF_CAPS = [
  CAPABILITIES.CASE_READ,
  CAPABILITIES.CASE_WRITE,
  CAPABILITIES.REPORT_SUBMIT,
  CAPABILITIES.COORDINATION_BARANGAY,
];

const ORG_ADMIN_CAPS = [
  CAPABILITIES.ORG_MANAGE_MEMBERS,
  CAPABILITIES.ORG_MANAGE_ROLES,
];

const MOPH_STAFF_CAPS = [CAPABILITIES.COORDINATION_HOSPITAL];

function resolvePassword(blueprint) {
  for (const envVar of blueprint.passwordEnvVars) {
    const value = process.env[envVar];
    if (value && String(value).trim()) {
      return { password: String(value), envVar };
    }
  }
  return {
    missing: blueprint.passwordEnvVars[0],
    tried: blueprint.passwordEnvVars,
  };
}

export function loadEmulatorDemoUsers() {
  const users = [];
  const missing = [];
  for (const blueprint of EMULATOR_DEMO_USER_BLUEPRINTS) {
    const resolved = resolvePassword(blueprint);
    if (resolved.missing) {
      missing.push(`${resolved.missing} (or ${resolved.tried.slice(1).join(", ")})`);
      continue;
    }
    users.push({ ...blueprint, password: resolved.password });
  }
  return { users, missing };
}

async function ensureOrganizations(db, logger) {
  const now = new Date();
  const orgs = [
    {
      orgId: DEMO_BARANGAY_ORG_ID,
      type: "barangay",
      name: DEMO_ASSIGNED_BARANGAY,
      status: "active",
    },
    {
      orgId: DEMO_HOSPITAL_ORG_ID,
      type: "hospital",
      name: DEMO_HOSPITAL_NAME,
      status: "active",
    },
  ];
  for (const org of orgs) {
    const ref = db.collection("organizations").doc(org.orgId);
    if (!(await ref.get()).exists) {
      await ref.set({ ...org, createdAt: now, updatedAt: now });
      logger.log(`Created organization ${org.orgId}`);
    }
  }
}

async function upsertMembership(db, orgId, uid, capabilities, logger) {
  const membershipId = membershipIdFor(orgId, uid);
  const ref = db.collection("organizationMemberships").doc(membershipId);
  if ((await ref.get()).exists) {
    return membershipId;
  }
  const now = new Date();
  await ref.set({
    membershipId,
    orgId,
    accountUid: uid,
    status: "active",
    capabilities,
    createdAt: now,
    updatedAt: now,
  });
  logger.log(`Created membership ${membershipId}`);
  return membershipId;
}

function membershipPlan(blueprint) {
  switch (blueprint.membership) {
    case "barangay_org_admin":
      return { orgId: DEMO_BARANGAY_ORG_ID, capabilities: [...ORG_ADMIN_CAPS] };
    case "barangay_staff":
      return { orgId: DEMO_BARANGAY_ORG_ID, capabilities: [...BARANGAY_STAFF_CAPS] };
    case "moph_org_admin":
      return { orgId: DEMO_HOSPITAL_ORG_ID, capabilities: [...ORG_ADMIN_CAPS] };
    case "moph_staff":
      return { orgId: DEMO_HOSPITAL_ORG_ID, capabilities: [...MOPH_STAFF_CAPS] };
    default:
      return null;
  }
}

/**
 * Idempotent emulator demonstration seed (Auth + Firestore). Requires emulator guard.
 */
export async function executeEmulatorDemoSeed({ auth, db, users, logger = console }) {
  await ensureOrganizations(db, logger);
  const uidByKey = {};

  for (const user of users) {
    let record;
    try {
      record = await auth.getUserByEmail(user.email);
      logger.log(`Auth user exists: ${user.email}`);
    } catch {
      record = await auth.createUser({
        email: user.email,
        password: user.password,
        displayName: user.displayName,
        emailVerified: user.role === "teen",
      });
      logger.log(`Created Auth user: ${user.email}`);
    }

    uidByKey[user.key] = record.uid;
    const now = new Date();
    const profile = {
      role: user.role,
      displayName: user.displayName,
      active: true,
      createdAt: now,
    };
    if (user.isCentralAdmin) {
      profile.isCentralAdmin = true;
    }
    if (user.assignedBarangay) {
      profile.assignedBarangay = user.assignedBarangay;
    }
    if (user.role === "teen") {
      profile.selectedBarangayOrgId = DEMO_BARANGAY_ORG_ID;
      profile.onboardingStatus = "complete";
    }

    const profileRef = db.collection("users").doc(record.uid);
    const snap = await profileRef.get();
    if (!snap.exists) {
      await profileRef.set(profile);
      logger.log(`Created profile for ${user.email}`);
    } else {
      const merge = {};
      const existing = snap.data();
      for (const [k, v] of Object.entries(profile)) {
        if (existing[k] === undefined || existing[k] === null) {
          merge[k] = v;
        }
      }
      if (user.isCentralAdmin && existing.isCentralAdmin !== true) {
        merge.isCentralAdmin = true;
      }
      if (Object.keys(merge).length) {
        await profileRef.set(merge, { merge: true });
        logger.log(`Merged profile fields for ${user.email}`);
      }
    }

    const plan = membershipPlan(user);
    if (plan) {
      await upsertMembership(db, plan.orgId, record.uid, plan.capabilities, logger);
      await profileRef.set({ primaryOrgId: plan.orgId }, { merge: true });
    }
  }

  const teenUid = uidByKey.teen;
  if (teenUid) {
    const assistRef = db.collection("teenAssistanceRequests").doc(EMULATOR_DEMO_ASSISTANCE_INBOX_ID);
    if (!(await assistRef.get()).exists) {
      const now = new Date();
      await assistRef.set({
        teenUid,
        barangay: DEMO_ASSIGNED_BARANGAY,
        orgId: DEMO_BARANGAY_ORG_ID,
        category: "generalSupport",
        description: "Fictional inbox sample for Barangay acknowledgment demo.",
        status: "submitted",
        createdAt: now,
      });
      logger.log(`Created sample assistance request ${EMULATOR_DEMO_ASSISTANCE_INBOX_ID}`);
    }
  }

  return { uidByKey };
}
