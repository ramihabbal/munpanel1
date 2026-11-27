const CACHE_NAME = "hhhsm-hhhsmun-offline-v1";
const APP_SHELL = ["./", "./index.html", "./manifest.webmanifest"];
const EXTERNAL_ASSETS = [
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2",
  "https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js",
  "https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=IBM+Plex+Mono:wght@500&display=swap"
];

self.addEventListener("install", event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    for (const url of APP_SHELL) {
      try { await cache.add(new Request(url, {cache:"reload"})); } catch (_) {}
    }
    // Warm external libraries while online. Opaque CDN responses are cacheable.
    for (const url of EXTERNAL_ASSETS) {
      try {
        const response = await fetch(url, {mode:"no-cors"});
        await cache.put(url, response);
      } catch (_) {}
    }
    await self.skipWaiting();
  })());
});

self.addEventListener("activate", event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k.startsWith("hhhsm-") && k !== CACHE_NAME).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", event => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  const isAppNavigation = req.mode === "navigate" && url.origin === self.location.origin;
  const isExternalAsset = url.origin !== self.location.origin;
  // Never cache Supabase API or storage responses: they are live conference data.
  if (url.hostname === "pmpczworpdlhdwykddso.supabase.co") {
    event.respondWith(fetch(req).catch(() => Response.error()));
    return;
  }
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    if (isAppNavigation) {
      try {
        const fresh = await fetch(req);
        cache.put("./index.html", fresh.clone());
        return fresh;
      } catch (_) {
        return (await cache.match(req)) || (await cache.match("./index.html")) || Response.error();
      }
    }
    const cached = await cache.match(req, {ignoreSearch:true});
    if (cached) {
      if (isExternalAsset) {
        event.waitUntil(fetch(req).then(r => { if (r && (r.ok || r.type === "opaque")) return cache.put(req, r); }).catch(()=>{}));
      }
      return cached;
    }
    try {
      const response = await fetch(req);
      if (response && (response.ok || response.type === "opaque")) cache.put(req, response.clone());
      return response;
    } catch (_) {
      return Response.error();
    }
  })());
});
