import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { applyMigrationPlan, verifyPostMigration } from "../src/apply.mjs";
import { buildMigrationPlan } from "../src/plan.mjs";
import { loadOrgMapping } from "../src/load_mapping.mjs";
import { DEMO_BARANGAY_LABEL, DEMO_BARANGAY_ORG_ID } from "../src/demo_orgs.mjs";

function createFakeDb(initial = {}) {
  /** @type {Map<string, object>} */
  const store = new Map(Object.entries(initial));

  return {
    collection(name) {
      return {
        doc(id) {
          const path = `${name}/${id}`;
          return {
            path,
            async get() {
              const data = store.get(path);
              return {
                exists: data !== undefined,
                data: () => data,
              };
            },
            async set(data, opts = {}) {
              const prev = store.get(path);
              store.set(
                path,
                opts.merge && prev ? { ...prev, ...data } : { ...data },
              );
            },
          };
        },
      };
    },
    _store: store,
  };
}

describe("M1 applyMigrationPlan", () => {
  it("dry-run performs no writes", async () => {
    const db = createFakeDb();
    const plan = buildMigrationPlan({
      dbSnapshot: {
        cases: [{ id: "c1", data: { barangay: DEMO_BARANGAY_LABEL } }],
      },
      mapping: loadOrgMapping(),
    });
    const result = await applyMigrationPlan(db, plan, { dryRun: true });
    assert.equal(result.dryRun, true);
    assert.equal(db._store.size, 0);
    assert.ok(result.preview.length > 0);
    assert.equal(result.applied.length, 0);
  });

  it("skips orgId backfill when conflicting orgId already set", async () => {
    const db = createFakeDb({
      "cases/c1": { barangay: DEMO_BARANGAY_LABEL, orgId: "org9999999999999999999999" },
    });
    const plan = buildMigrationPlan({
      dbSnapshot: {
        cases: [{ id: "c1", data: db._store.get("cases/c1") }],
      },
      mapping: loadOrgMapping(),
    });
    const result = await applyMigrationPlan(db, plan, { dryRun: false });
    const conflict = result.preview.find((p) => p.action === "skip-orgId-conflict");
    assert.ok(conflict);
    assert.equal(db._store.get("cases/c1").orgId, "org9999999999999999999999");
  });

  it("idempotent second apply skips existing org and membership", async () => {
    const mapping = loadOrgMapping();
    const snapshot = {
      users: [
        {
          uid: "barangayStaffUid123456789012",
          data: {
            active: true,
            role: "barangay",
            assignedBarangay: DEMO_BARANGAY_LABEL,
          },
        },
      ],
      cases: [{ id: "c1", data: { barangay: DEMO_BARANGAY_LABEL } }],
    };
    const db = createFakeDb();
    const plan = buildMigrationPlan({ dbSnapshot: snapshot, mapping });
    await applyMigrationPlan(db, plan, { dryRun: false });
    const sizeAfterFirst = db._store.size;
    const second = await applyMigrationPlan(db, plan, { dryRun: false });
    assert.equal(db._store.size, sizeAfterFirst);
    assert.ok(
      second.preview.some((p) => p.action === "skip-org-exists"),
    );
    assert.ok(
      second.preview.some((p) => p.action === "skip-membership-exists"),
    );
    assert.equal(
      second.applied.filter((a) => a.action === "create-org").length,
      0,
    );
    assert.equal(
      second.applied.filter((a) => a.action === "create-membership").length,
      0,
    );
  });

  it("verifyPostMigration detects missing orgId after incomplete apply", async () => {
    const db = createFakeDb({
      "cases/c1": { barangay: DEMO_BARANGAY_LABEL },
    });
    const plan = buildMigrationPlan({
      dbSnapshot: { cases: [{ id: "c1", data: { barangay: DEMO_BARANGAY_LABEL } }] },
      mapping: loadOrgMapping(),
    });
    const issues = await verifyPostMigration(db, plan);
    assert.ok(issues.some((i) => i.type === "missing-orgId"));
  });

  it("does not delete existing documents", async () => {
    const db = createFakeDb({
      "cases/keep": { barangay: DEMO_BARANGAY_LABEL, notes: "preserve" },
    });
    const plan = buildMigrationPlan({
      dbSnapshot: { cases: [{ id: "keep", data: db._store.get("cases/keep") }] },
      mapping: loadOrgMapping(),
    });
    await applyMigrationPlan(db, plan, { dryRun: false });
    assert.equal(db._store.has("cases/keep"), true);
    assert.equal(db._store.get("cases/keep").notes, "preserve");
    assert.equal(db._store.get("cases/keep").orgId, DEMO_BARANGAY_ORG_ID);
  });
});
