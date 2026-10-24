import { Timestamp } from "firebase-admin/firestore";

import { buildDemoCasePlans } from "./case_payloads.mjs";
import { DEMO_ASSIGNED_BARANGAY, DEMO_BARANGAY_ORG_ID } from "./constants.mjs";
import { planProvisioningOperations } from "./preflight.mjs";

function isoToTimestamp(iso) {
  return Timestamp.fromDate(new Date(iso));
}

/**
 * Execute provisioning (live writes). Caller must ensure preflight passed and dryRun is false.
 */
export async function executeProvisioning({ auth, db, users, logger = console }) {
  const casePlans = buildDemoCasePlans();
  const now = Timestamp.now();

  const remoteSnapshot = await collectRemoteSnapshot({ auth, db, users, casePlans });
  const operations = planProvisioningOperations({ users, casePlans, remoteSnapshot });

  for (const user of users) {
    let record = remoteSnapshot.authByEmail[user.email];
    if (!record) {
      record = await auth.createUser({
        email: user.email,
        password: user.password,
        displayName: user.displayName,
      });
      logger.log(`Created Auth user: ${user.email} (${record.uid})`);
    } else {
      logger.log(`Auth user exists; password unchanged: ${user.email} (${record.uid})`);
    }

    const profileRef = db.collection("users").doc(record.uid);
    const profileSnap = await profileRef.get();
    if (profileSnap.exists) {
      const data = profileSnap.data();
      if (data.role !== user.role || data.active !== true) {
        logger.log(
          `Skipping profile update for ${user.email}; existing role=${data.role} active=${data.active}`,
        );
      } else {
        if (user.assignedBarangay && !data.assignedBarangay) {
          await profileRef.update({ assignedBarangay: user.assignedBarangay });
          logger.log(`Set assignedBarangay for ${user.email}`);
        } else {
          logger.log(`User profile already present for ${user.email}`);
        }
      }
    } else {
      const profile = {
        role: user.role,
        displayName: user.displayName,
        active: true,
        createdAt: now,
      };
      if (user.assignedBarangay) {
        profile.assignedBarangay = user.assignedBarangay;
      }
      if (user.role === "teen" && user.assignedBarangay === DEMO_ASSIGNED_BARANGAY) {
        profile.selectedBarangayOrgId = DEMO_BARANGAY_ORG_ID;
      }
      await profileRef.set(profile);
      logger.log(`Created user profile: ${user.email} role=${user.role}`);
    }
  }

  for (const plan of casePlans) {
    const caseRef = db.collection("cases").doc(plan.caseId);
    const caseSnap = await caseRef.get();
    if (caseSnap.exists) {
      logger.log(`Case exists; skipping overwrite: ${plan.caseId}`);
      continue;
    }

    await caseRef.set({
      demoName: plan.case.demoName,
      age: plan.case.age,
      barangay: plan.case.barangay,
      orgId: plan.case.orgId,
      caseStatus: plan.case.caseStatus,
      registeredAt: isoToTimestamp(plan.case.registeredAt),
      nextFollowUpAt: isoToTimestamp(plan.case.nextFollowUpAt),
      notes: plan.case.notes,
      createdAt: now,
      updatedAt: now,
      reportStatus: plan.case.reportStatus,
    });

    const followRef = caseRef.collection("followUps").doc(plan.followUp.followUpId);
    const followSnap = await followRef.get();
    if (!followSnap.exists) {
      await followRef.set({
        caseId: plan.followUp.caseId,
        scheduledAt: isoToTimestamp(plan.followUp.scheduledAt),
        completedAt: plan.followUp.completedAt
          ? isoToTimestamp(plan.followUp.completedAt)
          : null,
        status: plan.followUp.status,
        notes: plan.followUp.notes,
      });
    }

    logger.log(`Created case ${plan.caseId} and follow-up ${plan.followUp.followUpId}`);
  }

  return { operations, remoteSnapshot };
}

export async function collectRemoteSnapshot({ auth, db, users, casePlans }) {
  const authByEmail = {};
  const profiles = {};
  const cases = {};

  for (const user of users) {
    try {
      const record = await auth.getUserByEmail(user.email);
      authByEmail[user.email] = { uid: record.uid };
      const profileSnap = await db.collection("users").doc(record.uid).get();
      if (profileSnap.exists) {
        profiles[record.uid] = profileSnap.data();
      }
    } catch (err) {
      if (err?.code !== "auth/user-not-found") {
        throw err;
      }
    }
  }

  for (const plan of casePlans) {
    const snap = await db.collection("cases").doc(plan.caseId).get();
    if (snap.exists) {
      cases[plan.caseId] = snap.data();
    }
  }

  return { authByEmail, profiles, cases };
}
