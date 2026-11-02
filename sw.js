// Service worker: gör att appen fungerar offline efter första besöket.
const CACHE = "hp-plugg-v13";
const FILES = ["./", "./index.html", "./quant-bank.js", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png", "./apple-touch-icon.png", "./provsfragor/2000-var/2000vt-nog-01.png", "./provsfragor/2001-host/2001ht-nog-01.png", "./provsfragor/2002-var/2002vt-nog-01.png", "./provsfragor/2003-var/2003vt-nog-01.png", "./provsfragor/2004-var/2004vt-nog-01.png", "./provsfragor/2005-var/2005vt-nog-01.png", "./provsfragor/2006-var/2006vt-nog-01.png", "./provsfragor/2007-var/2007vt-nog-01.png", "./provsfragor/2008-var/2008vt-nog-01.png", "./provsfragor/2009-var/2009vt-nog-01.png", "./provsfragor/2010-var/2010vt-nog-01.png", "./provsfragor/2011-host/2011ht-xyz-01.png", "./provsfragor/2012-host/2012ht-xyz-01.png", "./provsfragor/2013-host/2013ht-xyz-01.png", "./provsfragor/2014-host/2014ht-xyz-01.png", "./provsfragor/2015-host/2015ht-xyz-01.png", "./provsfragor/2016-host/2016ht-xyz-01.png", "./provsfragor/2017-host/2017ht-xyz-01.png", "./provsfragor/2018-host/kvant-pass-4-kva-22.png", "./provsfragor/2019-host/2019ht-xyz-01.png", "./provsfragor/2020-host/2020ht-xyz-01.png", "./provsfragor/2021-host/2021ht-xyz-01.png", "./provsfragor/2022-host/2022ht-xyz-01.png", "./provsfragor/2023-host/2023ht-xyz-01.png", "./provsfragor/2024-var-pass-2/xyz-01.png", "./provsfragor/2024-var-pass-2/xyz-02.png", "./provsfragor/2024-var-pass-2/xyz-03.png", "./provsfragor/2024-var-pass-2/xyz-04.png", "./provsfragor/2024-var-pass-2/xyz-05.png", "./provsfragor/2024-var-pass-2/xyz-06.png", "./provsfragor/2024-var-pass-2/xyz-07.png", "./provsfragor/2024-var-pass-2/xyz-08.png", "./provsfragor/2024-var-pass-2/xyz-09.png", "./provsfragor/2024-var-pass-2/xyz-10.png", "./provsfragor/2024-var-pass-2/xyz-11.png", "./provsfragor/2024-var-pass-2/xyz-12.png", "./provsfragor/2025-host/2025ht-xyz-01.png", "./provsfragor/2026-host/kvant-pass-1-xyz-11.png", "./provsfragor/2026-var/kvant-pass-3-xyz-11.png", "./provsfragor/2026-var/kvant-pass-3-xyz-12.png"];

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
