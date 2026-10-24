import { Timestamp } from "firebase-admin/firestore";
import { membershipIdFor } from "../../reg/src/membership_id.mjs";
import { CAPABILITIES } from "../../reg/src/capabilities.mjs";
import {
  DEMO_ASSIGNED_BARANGAY,
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_NAME,
  DEMO_HOSPITAL_ORG_ID,
} from "./constants.mjs";

const BARANGAY_CAPS = [
  CAPABILITIES.CASE_READ,
  CAPABILITIES.CASE_WRITE,
  CAPABILITIES.REPORT_SUBMIT,
  CAPABILITIES.COORDINATION_BARANGAY,
];

const MOPH_CAPS = [CAPABILITIES.COORDINATION_HOSPITAL];

/**
 * Idempotent demo organizations and memberships for REG-001 M2.
 * @param {import("firebase-admin/firestore").Firestore} db
 * @param {{ uid: string, role: string }[]} users
 */
export async function ensureDemoOrganizationsAndMemberships(db, users, logger = console) {
  const now = Timestamp.now();

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
    const snap = await ref.get();
    if (!snap.exists) {
      await ref.set({ ...org, createdAt: now, updatedAt: now });
      logger.log(`Created organization ${org.orgId}`);
    }
  }

  for (const user of users) {
    const { uid, role } = user;
    if (!uid) continue;

    const profileRef = db.collection("users").doc(uid);
    const profileSnap = await profileRef.get();
    const profilePatch = {};

    if (role === "barangay") {
      const membershipId = membershipIdFor(DEMO_BARANGAY_ORG_ID, uid);
      const mRef = db.collection("organizationMemberships").doc(membershipId);
      if (!(await mRef.get()).exists) {
        await mRef.set({
          membershipId,
          orgId: DEMO_BARANGAY_ORG_ID,
          accountUid: uid,
          status: "active",
          capabilities: BARANGAY_CAPS,
          createdAt: now,
          updatedAt: now,
        });
        logger.log(`Created barangay membership for ${uid}`);
      }
      profilePatch.primaryOrgId = DEMO_BARANGAY_ORG_ID;
    } else if (role === "moph") {
      const membershipId = membershipIdFor(DEMO_HOSPITAL_ORG_ID, uid);
      const mRef = db.collection("organizationMemberships").doc(membershipId);
      if (!(await mRef.get()).exists) {
        await mRef.set({
          membershipId,
          orgId: DEMO_HOSPITAL_ORG_ID,
          accountUid: uid,
          status: "active",
          capabilities: MOPH_CAPS,
          createdAt: now,
          updatedAt: now,
        });
        logger.log(`Created MOPH hospital membership for ${uid}`);
      }
      profilePatch.primaryOrgId = DEMO_HOSPITAL_ORG_ID;
    } else if (role === "teen") {
      profilePatch.selectedBarangayOrgId = DEMO_BARANGAY_ORG_ID;
    }

    if (profileSnap.exists && Object.keys(profilePatch).length > 0) {
      const data = profileSnap.data();
      const merge = {};
      for (const [k, v] of Object.entries(profilePatch)) {
        if (!data[k]) merge[k] = v;
      }
      if (Object.keys(merge).length > 0) {
        await profileRef.set(merge, { merge: true });
        logger.log(`Patched profile org fields for ${uid}`);
      }
    }
  }
}
