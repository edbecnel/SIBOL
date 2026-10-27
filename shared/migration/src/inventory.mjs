/**
 * Collect inventory from Firestore (Admin SDK).
 * @param {import("firebase-admin/firestore").Firestore} db
 */
export async function collectInventory(db) {
  const collections = {
    users: "users",
    cases: "cases",
    teenAssistanceRequests: "teenAssistanceRequests",
    reports: "reports",
    caseCoordinationThreads: "caseCoordinationThreads",
    barangayCoordinationRegistry: "barangayCoordinationRegistry",
  };

  const snapshot = { users: [], cases: [] };
  for (const [key, name] of Object.entries(collections)) {
    if (!snapshot[key]) snapshot[key] = [];
    const snap = await db.collection(name).get();
    for (const doc of snap.docs) {
      const row = { id: doc.id, data: doc.data() };
      if (key === "users") row.uid = doc.id;
      snapshot[key].push(row);
    }
  }

  const labels = new Set();
  for (const c of snapshot.cases) {
    if (c.data?.barangay) labels.add(c.data.barangay);
  }
  for (const u of snapshot.users) {
    if (u.data?.assignedBarangay) labels.add(u.data.assignedBarangay);
  }

  return {
    counts: Object.fromEntries(
      Object.keys(collections).map((k) => [k, snapshot[k].length]),
    ),
    barangayLabels: [...labels].sort(),
    snapshot,
  };
}
