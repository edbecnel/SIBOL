import { membershipIdFor } from "../../reg/src/membership_id.mjs";

/**
 * Apply plan to Firestore. Idempotent: skips existing orgs/memberships; only patches missing orgId.
 * @param {import("firebase-admin/firestore").Firestore} db
 * @param {import("./plan.mjs").buildMigrationPlan} plan
 * @param {{ dryRun: boolean }} options
 */
export async function applyMigrationPlan(db, plan, { dryRun }) {
  const preview = [];
  const applied = [];

  if (plan.errors.length > 0 && !dryRun) {
    throw new Error(
      `Migration plan has ${plan.errors.length} blocking error(s). Fix mapping or data first.`,
    );
  }

  for (const org of plan.organizations) {
    const ref = db.collection("organizations").doc(org.orgId);
    const snap = await ref.get();
    const action = snap.exists ? "skip-org-exists" : "create-org";
    preview.push({ action, path: ref.path });
    if (!dryRun && !snap.exists) {
      await ref.set(org);
      applied.push({ action: "create-org", orgId: org.orgId });
    }
  }

  for (const m of plan.memberships) {
    const ref = db.collection("organizationMemberships").doc(m.membershipId);
    const snap = await ref.get();
    const action = snap.exists ? "skip-membership-exists" : "create-membership";
    preview.push({ action, path: ref.path, membershipId: m.membershipId });
    if (!dryRun && !snap.exists) {
      await ref.set({
        membershipId: m.membershipId,
        orgId: m.orgId,
        accountUid: m.accountUid,
        status: m.status,
        capabilities: m.capabilities,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      });
      applied.push({ action: "create-membership", membershipId: m.membershipId });
    }
  }

  for (const u of plan.userUpdates) {
    const ref = db.collection("users").doc(u.uid);
    preview.push({ action: "patch-user", path: ref.path, set: u.set });
    if (!dryRun) {
      await ref.set(u.set, { merge: true });
      applied.push({ action: "patch-user", uid: u.uid });
    }
  }

  for (const d of plan.documentUpdates) {
    const ref = db.collection(d.collection).doc(d.id);
    const snap = await ref.get();
    if (!snap.exists) {
      preview.push({ action: "skip-missing-doc", path: ref.path });
      continue;
    }
    const current = snap.data()?.orgId;
    if (current === d.set.orgId) {
      preview.push({ action: "skip-orgId-present", path: ref.path });
      continue;
    }
    preview.push({ action: "backfill-orgId", path: ref.path, orgId: d.set.orgId });
    if (!dryRun) {
      await ref.set(d.set, { merge: true });
      applied.push({ action: "backfill-orgId", path: ref.path });
    }
  }

  return { preview, applied, dryRun };
}

export async function verifyPostMigration(db, plan) {
  const issues = [];
  for (const d of plan.documentUpdates) {
    const snap = await db.collection(d.collection).doc(d.id).get();
    if (!snap.exists) continue;
    if (snap.data()?.orgId !== d.set.orgId) {
      issues.push({
        type: "missing-orgId",
        collection: d.collection,
        id: d.id,
        expected: d.set.orgId,
        actual: snap.data()?.orgId,
      });
    }
  }
  for (const m of plan.memberships) {
    const id = membershipIdFor(m.orgId, m.accountUid);
    const snap = await db.collection("organizationMemberships").doc(id).get();
    if (!snap.exists) {
      issues.push({ type: "missing-membership", membershipId: id });
    }
  }
  return issues;
}
