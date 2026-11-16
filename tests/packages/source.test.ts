import { expect, test } from "bun:test";
import { readdir } from "node:fs/promises";
import { join } from "node:path";

const publicDirectory = "web/packages/public";

export const publicFiles = [
  "404.html",
  "_site/INTER-LICENSE.txt",
  "_site/VHCO-LOGO-NOTICE.txt",
  "_site/inter-latin.woff2",
  "_site/page.js",
  "_site/style.css",
  "_site/vhco.png",
  "index.html",
];

test("the production asset set contains exactly the reviewed public files", async () => {
  const files = await readdir(publicDirectory, { recursive: true, withFileTypes: true });
  const actual = files.filter((entry) => entry.isFile()).map((entry) =>
    join(entry.parentPath, entry.name).slice(publicDirectory.length + 1)
  );
  expect(actual.sort()).toEqual(publicFiles);
});

test("page references use the isolated asset prefix and trusted installation guidance", async () => {
  const html = await Bun.file(`${publicDirectory}/index.html`).text();
  expect(html).toContain('href="/_site/style.css"');
  expect(html).toContain('src="/_site/page.js"');
  expect(html).toContain("os-encrypted-git-backup");
  expect(html).toContain("independent trusted channel");
  expect(html).toContain('role="switch"');
  expect(html).toContain('href="#repository-setup"');
});
