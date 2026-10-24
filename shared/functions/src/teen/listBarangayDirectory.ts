import { Firestore } from "firebase-admin/firestore";

export type BarangayDirectoryEntry = {
  orgId: string;
  name: string;
  legacyBarangayLabel?: string;
};

export async function runListBarangayDirectory(
  db: Firestore,
): Promise<{ organizations: BarangayDirectoryEntry[] }> {
  const snap = await db
    .collection("organizations")
    .where("type", "==", "barangay")
    .where("status", "==", "active")
    .get();

  const organizations = snap.docs
    .map((d) => {
      const data = d.data();
      return {
        orgId: data.orgId as string,
        name: data.name as string,
        legacyBarangayLabel: data.legacyBarangayLabel as string | undefined,
      };
    })
    .filter((o) => o.orgId && o.name)
    .sort((a, b) => a.name.localeCompare(b.name));

  return { organizations };
}
