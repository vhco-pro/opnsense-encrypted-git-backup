import { fileURLToPath } from 'node:url';

const assets = new Map([
  ['/', 'index.html'],
  ['/404.html', '404.html'],
  ['/style.css', 'style.css'],
  ['/page.js', 'page.js'],
  ['/vhco.png', 'vhco.png'],
  ['/inter-latin.woff2', 'inter-latin.woff2'],
  ['/INTER-LICENSE.txt', 'INTER-LICENSE.txt'],
  ['/VHCO-LOGO-NOTICE.txt', 'VHCO-LOGO-NOTICE.txt'],
]);

const server = Bun.serve({
  hostname: '127.0.0.1',
  port: Number(process.env.VHCO_PACKAGES_PREVIEW_PORT ?? 0),
  fetch(request) {
    const asset = assets.get(new URL(request.url).pathname);
    if (!asset) {
      const file = fileURLToPath(new URL('404.html', import.meta.url));
      return new Response(Bun.file(file), { status: 404, headers: { 'Cache-Control': 'no-store' } });
    }
    const file = fileURLToPath(new URL(asset, import.meta.url));
    return new Response(Bun.file(file), { headers: { 'Cache-Control': 'no-store' } });
  },
});

console.log(JSON.stringify({ status: 'ready', url: server.url.href }));
