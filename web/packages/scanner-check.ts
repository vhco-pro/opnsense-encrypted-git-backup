import { cp, mkdtemp, mkdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { scan } from "./scan";

const temporary = await mkdtemp(join(tmpdir(), "vhco-packages-scan-"));
const token = "ghp_" + "Ab3Cd4Ef5Gh6Ij7Kl8Mn9Op0Qr1St2Uv3Wx4";
const cases = [
  { path: "README.md", code: 1 },
  { path: "wrangler.toml", code: 1 },
  { path: "public/index.html", code: 1 },
  { path: "public/_site/page.js", code: 1 },
  { path: ".wrangler/probe.txt", code: 0 },
  { path: "node_modules/probe.txt", code: 0 },
];
try {
  for (const item of cases) {
    const directory = join(temporary, String(cases.indexOf(item)));
    const file = join(directory, item.path);
    await mkdir(join(file, ".."), { recursive: true });
    await cp(join(import.meta.dir, ".gitleaks.toml"), join(directory, ".gitleaks.toml"));
    await Bun.write(file, `# Synthetic test credential\ntoken = "${token}"\n`);
    const code = await scan(directory);
    if (code !== item.code) throw new Error(`Unexpected scanner exit for ${item.path}: ${code}`);
  }
  console.log("Native source and generated-cache scanner cases passed.");
} finally {
  await rm(temporary, { recursive: true, force: true });
}
