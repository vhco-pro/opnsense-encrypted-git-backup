import { fileURLToPath } from 'node:url';

const assets = new Map([
  ['/', 'index.html'],
  ['/style.css', 'style.css'],
  ['/page.js', 'page.js'],
  ['/vhco.png', 'vhco.png'],
  ['/inter-latin.woff2', 'inter-latin.woff2'],
  ['/INTER-LICENSE.txt', 'INTER-LICENSE.txt'],
]);

const server = Bun.serve({
  hostname: '127.0.0.1',
  port: 0,
  fetch(request) {
    const asset = assets.get(new URL(request.url).pathname);
    if (!asset) return new Response('Not found', { status: 404 });
    const file = fileURLToPath(new URL(asset, import.meta.url));
    return new Response(Bun.file(file), { headers: { 'Cache-Control': 'no-store' } });
  },
});

console.log(JSON.stringify({ status: 'ready', url: server.url.href }));
