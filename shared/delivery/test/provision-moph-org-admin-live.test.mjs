import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { membershipIdFor } from "../../reg/src/membership_id.mjs";
import { CAPABILITIES } from "../../reg/src/capabilities.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const scriptPath = resolve(
  __dirname,
  "../scripts/provision-moph-org-admin-live.mjs",
);

const ORG_ADMIN_CAPS = [
  CAPABILITIES.ORG_MANAGE_MEMBERS,
  CAPABILITIES.ORG_MANAGE_ROLES,
];

function runScript(args, { env = {} } = {}) {
  return spawnSync(process.execPath, [scriptPath, ...args], {
    cwd: resolve(__dirname, "../scripts"),
    encoding: "utf8",
    env: { ...process.env, ...env },
  });
}

describe("provision-moph-org-admin-live", () => {
  it("requires --dry-run or --execute", () => {
    const result = runScript([]);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Pass --dry-run or --execute/);
  });

  it("execute requires --confirm-project=sibol-286d0", () => {
    const result = runScript(["--execute"]);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /confirm-project=sibol-286d0/);
  });

  it("membership id follows mbr_hospital01__{uid}", () => {
    const uid = "Ab12Cd34Ef56Gh78Ij90Kl12Mn34";
    assert.equal(
      membershipIdFor("hospital01", uid),
      "mbr_hospital01__Ab12Cd34Ef56Gh78Ij90Kl12Mn34",
    );
  });

  it("org admin capabilities match audited set", () => {
    assert.deepEqual(ORG_ADMIN_CAPS, [
      "org.manage_members",
      "org.manage_roles",
    ]);
  });

  it("dry-run reports moph.org.admin and hospital01 when credentialed", () => {
    if (!process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.GCLOUD_PROJECT) {
      return;
    }
    const result = runScript(["--dry-run"]);
    if (result.status !== 0 && result.stdout.includes("organization_missing")) {
      return;
    }
    const plan = JSON.parse(result.stdout);
    assert.equal(plan.project, "sibol-286d0");
    assert.equal(plan.email, "moph.org.admin@sibol.local");
    assert.equal(plan.orgId, "hospital01");
    assert.equal(plan.passwordSourceEnvVar, "SIBOL_EMULATOR_PASSWORD_MOPH_ORG_ADMIN");
    assert.equal(plan.ordinaryMophStaffEmail, "moph.demo@sibol.local");
    assert.deepEqual(plan.blueprint.membershipCapabilities, ORG_ADMIN_CAPS);
  });
});
