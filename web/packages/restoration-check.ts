import { cp, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { verifySite } from "./smoke";
import { publicDirectory } from "./verify";

const temporary = await mkdtemp(join(tmpdir(), "vhco-packages-restore-"));
let child: ReturnType<typeof Bun.spawn> | undefined;
try {
  const copiedAssets = join(temporary, "public");
  await cp(publicDirectory, copiedAssets, { recursive: true });
  const original = await Bun.file(join(copiedAssets, "index.html")).text();
  await Bun.write(join(copiedAssets, "index.html"), original.replace("Packages from", "Synthetic stale page from"));
  const configuration = join(temporary, "wrangler.toml");
  await Bun.write(configuration, await Bun.file(join(import.meta.dir, "wrangler.toml")).text());
  child = Bun.spawn(["node", resolve("node_modules/wrangler/bin/wrangler.js"), "dev", "--local", "--ip", "127.0.0.1", "--port", "0", "--config", configuration], {
    stdout: "pipe", stderr: "inherit", env: { ...process.env, NO_COLOR: "1", WRANGLER_SEND_METRICS: "false" },
  });
  let resolveReady: (value: string) => void;
  const ready = new Promise<string>((resolve) => { resolveReady = resolve; });
  const output = (async () => {
    let text = "";
    for await (const bytes of child!.stdout as ReadableStream<Uint8Array>) {
      process.stdout.write(bytes);
      text += new TextDecoder().decode(bytes);
      const match = text.match(/Ready on (http:\/\/127\.0\.0\.1:\d+)/);
      if (match) resolveReady(match[1]);
    }
  })();
  const url = await Promise.race([ready, Bun.sleep(30_000).then(() => { throw new Error("Native Wrangler readiness timed out"); })]);
  await verifySite(url, { directory: copiedAssets });
  let rejected = false;
  try {
    await verifySite(url, { timeoutMs: 0 });
  } catch {
    rejected = true;
  }
  if (!rejected) throw new Error("The stale page unexpectedly passed byte verification");
  await Bun.write(join(copiedAssets, "index.html"), original);
  await verifySite(url);
  console.log("Native Wrangler rejected stale bytes and verified restored source bytes.");
  child.kill("SIGINT");
  await child.exited;
  await output;
} finally {
  if (child && child.exitCode === null) {
    child.kill("SIGTERM");
    await child.exited;
  }
  await rm(temporary, { recursive: true, force: true });
}
