import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import {
  assertOrganizationName,
  normalizeOrganizationName,
  runCreateOrganization,
} from "../lib/admin/operations.js";

const projectId = "demo-sibol-hospital-create";
const centralUid = "centralHospitalCreateUid123456789";
const outsiderUid = "outsiderHospitalCreateUid123456789";

let db;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  await db.collection("users").doc(centralUid).set({
    role: "barangay",
    displayName: "Central",
    active: true,
    isCentralAdmin: true,
    createdAt: new Date(),
  });
  await db.collection("users").doc(outsiderUid).set({
    role: "barangay",
    displayName: "Outsider",
    active: true,
    createdAt: new Date(),
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("SIBOL-REG-003 hospital organization create", () => {
  it("normalizes whitespace in organization names", () => {
    assert.equal(
      normalizeOrganizationName("  Northern   Mindanao\nMedical Center  "),
      "Northern Mindanao Medical Center",
    );
  });

  it("rejects empty and whitespace-only hospital names", () => {
    assert.throws(() => assertOrganizationName("   "), AuthzError);
    assert.throws(() => assertOrganizationName(""), AuthzError);
  });

  it("central admin creates hospital with arbitrary name", async () => {
    const created = await runCreateOrganization(db, centralUid, {
      type: "hospital",
      name: "Bukidnon Provincial Medical Center",
      initialOrgAdminEmail: "hospital.admin.bukidnon@sibol.local",
    });
    assert.ok(created.orgId);
    const org = await db.collection("organizations").doc(created.orgId).get();
    assert.equal(org.data()?.type, "hospital");
    assert.equal(org.data()?.name, "Bukidnon Provincial Medical Center");
    const directory = await db.collection("organizationDirectory").doc(created.orgId).get();
    assert.equal(directory.data()?.name, "Bukidnon Provincial Medical Center");
  });

  it("rejects duplicate active hospital name", async () => {
    await expectDenied(
      () =>
        runCreateOrganization(db, centralUid, {
          type: "hospital",
          name: "Bukidnon Provincial Medical Center",
          initialOrgAdminEmail: "duplicate.admin@sibol.local",
        }),
      "already-exists",
    );
  });

  it("denies non-central hospital creation", async () => {
    await expectDenied(
      () =>
        runCreateOrganization(db, outsiderUid, {
          type: "hospital",
          name: "Unauthorized Hospital",
          initialOrgAdminEmail: "x@sibol.local",
        }),
      "permission-denied",
    );
  });
});
