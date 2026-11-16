const html = await Bun.file(`${import.meta.dir}/public/index.html`).text();
const references = [...new Set(Array.from(html.matchAll(/href="(https:\/\/[^"<>]+)"/g), (match) => match[1]))];
if (references.length === 0) throw new Error("The page has no public references");
for (const reference of references) {
  const response = await fetch(reference, { redirect: "follow", signal: AbortSignal.timeout(20_000) });
  const expected = new URL(reference);
  const final = new URL(response.url);
  const samePath = final.pathname.replace(/\/$/, "") === expected.pathname.replace(/\/$/, "");
  if (response.status !== 200 || final.origin !== expected.origin || !samePath) {
    throw new Error(`Public reference failed: ${reference}, HTTP ${response.status}, final ${final.href}`);
  }
  await response.body?.cancel();
  console.log(JSON.stringify({ reference, final: final.href, status: response.status }));
}
