import { readdir } from "node:fs/promises";
import { relative, resolve } from "node:path";

export const publicDirectory = resolve(import.meta.dir, "public");
export const assets = {
  "index.html": "text/html",
  "404.html": "text/html",
  "_site/style.css": "text/css",
  "_site/page.js": "text/javascript",
  "_site/vhco.png": "image/png",
  "_site/vhco.svg": "image/svg+xml",
  "_site/inter-latin.woff2": "font/woff2",
  "_site/INTER-LICENSE.txt": "text/plain",
  "_site/VHCO-LOGO-NOTICE.txt": "text/plain",
};

export async function verifySource(directory = publicDirectory) {
  const entries = await readdir(directory, { recursive: true, withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = relative(directory, resolve(entry.parentPath, entry.name));
    if (entry.isDirectory() && path === "_site") continue;
    if (!entry.isFile() || !(path in assets)) throw new Error(`Unexpected public asset: ${path}`);
    files.push(path);
  }
  if (files.sort().join("\n") !== Object.keys(assets).sort().join("\n")) {
    throw new Error("The public asset list is incomplete");
  }
  const configuration = Bun.TOML.parse(await Bun.file(`${import.meta.dir}/wrangler.toml`).text());
  if ("route" in configuration || "routes" in configuration || configuration.workers_dev !== false || configuration.preview_urls !== false) {
    throw new Error("Wrangler must be route-free with public previews disabled");
  }
  if (configuration.assets?.directory !== "public/" || configuration.assets?.not_found_handling !== "404-page") {
    throw new Error("Wrangler must serve the explicit public directory with native 404 handling");
  }
  const built = await Bun.build({ entrypoints: [`${directory}/_site/page.js`], target: "browser", write: false });
  if (!built.success) throw new Error("Browser script syntax check failed", { cause: built.logs });
}

if (import.meta.main) {
  await verifySource();
  console.log("Public assets and native Wrangler configuration verified.");
}
