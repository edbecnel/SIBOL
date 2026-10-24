/** Demo org ids aligned with shared/migration/fixtures/demo_org_mapping.json */
export const ORG_BARANGAY_DEMO = "org0123456789012345678901";
export const ORG_BARANGAY_OTHER = "org1111111111111111111111";
export const ORG_HOSPITAL_DEMO = "org2222222222222222222222";

export function membershipId(orgId, uid) {
  return `mbr_${orgId}__${uid}`;
}

export const CAPS = {
  caseReadWrite: ["case.read", "case.write"],
  caseReadOnly: ["case.read"],
  orgAdminOnly: ["org.manage_members"],
  barangayCoord: ["coordination.barangay"],
  barangayFull: [
    "case.read",
    "case.write",
    "report.submit",
    "coordination.barangay",
  ],
  hospitalCoord: ["coordination.hospital"],
};

export async function seedOrganization(db, orgId, overrides = {}) {
  const now = new Date();
  await db.collection("organizations").doc(orgId).set({
    orgId,
    type: overrides.type ?? "barangay",
    name: overrides.name ?? "Demo Org",
    status: overrides.status ?? "active",
    createdAt: now,
    updatedAt: now,
    ...overrides,
  });
}

export async function seedMembership(db, orgId, uid, capabilities, status = "active") {
  const now = new Date();
  const id = membershipId(orgId, uid);
  await db.collection("organizationMemberships").doc(id).set({
    membershipId: id,
    orgId,
    accountUid: uid,
    status,
    capabilities,
    createdAt: now,
    updatedAt: now,
  });
}

/** Seeds organizations and memberships for M2 rules tests (users must already exist). */
export async function setupM2DemoAuth(db, options = {}) {
  const site = options.site ?? "Barangay Tres, Balingasag";
  const otherSite = options.otherSite ?? "Other Demo Barangay";
  await seedOrganization(db, ORG_BARANGAY_DEMO, { name: site, type: "barangay" });
  await seedOrganization(db, ORG_BARANGAY_OTHER, { name: otherSite, type: "barangay" });
  await seedOrganization(db, ORG_HOSPITAL_DEMO, {
    name: "Misamis Oriental Provincial Hospital",
    type: "hospital",
  });

  const pairs = [
    [options.barangayUid, ORG_BARANGAY_DEMO, CAPS.barangayFull],
    [options.barangayUid2, ORG_BARANGAY_OTHER, CAPS.barangayFull],
    [options.mophUid, ORG_HOSPITAL_DEMO, CAPS.hospitalCoord],
  ];
  for (const [uid, orgId, caps] of pairs) {
    if (!uid) continue;
    await seedMembership(db, orgId, uid, caps);
    await db.collection("users").doc(uid).set({ primaryOrgId: orgId }, { merge: true });
  }
  if (options.teenUid) {
    await db.collection("users").doc(options.teenUid).set(
      { selectedBarangayOrgId: ORG_BARANGAY_DEMO },
      { merge: true },
    );
  }
  if (options.teenUid2) {
    await db.collection("users").doc(options.teenUid2).set(
      { selectedBarangayOrgId: ORG_BARANGAY_DEMO },
      { merge: true },
    );
  }
}
