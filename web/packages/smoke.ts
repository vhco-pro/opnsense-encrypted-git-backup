import { assets, publicDirectory } from "./verify";

export async function verifySite(baseURL: string, options: { directory?: string; timeoutMs?: number; intervalMs?: number } = {}) {
  const origin = new URL(baseURL);
  const local = ["localhost", "127.0.0.1", "[::1]"].includes(origin.hostname);
  if (origin.username || origin.password || origin.search || origin.hash || origin.pathname !== "/" || (!local && origin.href !== "https://pkg.vhco.pro/")) {
    throw new Error("Unexpected site URL");
  }
  const directory = options.directory ?? publicDirectory;
  const deadline = Date.now() + (options.timeoutMs ?? 60_000);
  const requests = Object.entries(assets).filter(([path]) => path !== "404.html").map(([path, type]) => ({
    url: path === "index.html" ? "/" : `/${path}`,
    file: path,
    type,
    status: 200,
  }));
  requests.push({ url: "/_site/__vhco_missing_asset__", file: "404.html", type: "text/html", status: 404 });
  while (true) {
    try {
      for (const item of requests) {
        const remaining = options.timeoutMs === 0 ? 10_000 : deadline - Date.now();
        if (remaining <= 0) throw new Error("Public response verification timed out");
        const response = await fetch(new URL(item.url, origin), { signal: AbortSignal.timeout(Math.min(10_000, remaining)), cache: "no-store" });
        const type = response.headers.get("content-type")?.split(";", 1)[0].trim();
        const expected = Buffer.from(await Bun.file(`${directory}/${item.file}`).arrayBuffer());
        const actual = Buffer.from(await response.arrayBuffer());
        if (response.status !== item.status || type !== item.type || !actual.equals(expected)) {
          throw new Error(`Public response differs for ${item.url}: HTTP ${response.status}, ${type}`);
        }
      }
      return { origin: origin.origin, checkedResponses: requests.length };
    } catch (error) {
      if (Date.now() >= deadline) throw error;
      await Bun.sleep(Math.min(options.intervalMs ?? 5_000, deadline - Date.now()));
    }
  }
}

if (import.meta.main) {
  const url = Bun.argv.slice(2).filter((value) => value !== "--")[0] ?? process.env.CLOUDFLARE_SITE_URL;
  if (!url) throw new Error("Supply a site URL");
  if (process.env.CLOUDFLARE_SITE_URL && process.env.CLOUDFLARE_SITE_URL !== "https://pkg.vhco.pro") throw new Error("Unexpected production site URL");
  console.log(JSON.stringify(await verifySite(url)));
}
