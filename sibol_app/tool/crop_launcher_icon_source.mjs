#!/usr/bin/env node
/**
 * Regenerate assets/branding/sibol_app_icon_source.png from Docs/Branding/SIBOL-Logo-Icon.png.
 * Requires: npm install --prefix tool sharp
 */
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const master = join(root, "..", "Docs", "Branding", "SIBOL-Logo-Icon.png");
const out = join(root, "assets", "branding", "sibol_app_icon_source.png");
const side = 1024;

let sharp;
try {
  sharp = (await import("sharp")).default;
} catch {
  console.error("Install sharp: npm install --prefix tool sharp");
  process.exit(1);
}

await sharp(master)
  .resize(side, side)
  .flatten({ background: "#ffffff" })
  .png()
  .toFile(out);

console.log("Wrote", out);
