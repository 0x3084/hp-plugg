// Service worker: gör att appen fungerar offline efter första besöket.
const CACHE = "hp-plugg-v9";
const FILES = ["./", "./index.html", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png", "./provsfragor/2024-var-pass-2/xyz-01.png", "./provsfragor/2024-var-pass-2/xyz-02.png", "./provsfragor/2024-var-pass-2/xyz-03.png", "./provsfragor/2024-var-pass-2/xyz-04.png", "./provsfragor/2024-var-pass-2/xyz-05.png", "./provsfragor/2024-var-pass-2/xyz-06.png", "./provsfragor/2024-var-pass-2/xyz-07.png", "./provsfragor/2024-var-pass-2/xyz-08.png", "./provsfragor/2024-var-pass-2/xyz-09.png", "./provsfragor/2024-var-pass-2/xyz-10.png", "./provsfragor/2024-var-pass-2/xyz-11.png", "./provsfragor/2018-host/kvant-pass-4-kva-22.png", "./provsfragor/2026-var/kvant-pass-3-xyz-11.png", "./provsfragor/2026-var/kvant-pass-3-xyz-12.png", "./provsfragor/2026-host/kvant-pass-1-xyz-11.png", "./provsfragor/2024-var-pass-2/xyz-12.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)));
  self.skipWaiting();
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});

// Nätet först (så att ändringar syns direkt), cache som reserv när du är offline.
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    fetch(e.request)
      .then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(e.request).then(r => r || caches.match("./index.html")))
  );
});
