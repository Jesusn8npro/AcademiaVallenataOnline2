// 🚀 SERVICE WORKER OPTIMIZADO - Academia Vallenata Online
// Versión: 2.0.0 | Más liviano y rápido

const VERSION = 'v2.0.0';
const CACHE_PREFIX = 'academia-vallenata';
const CACHE_STATIC = `${CACHE_PREFIX}-static-${VERSION}`;
const CACHE_DYNAMIC = `${CACHE_PREFIX}-dynamic-${VERSION}`;
const CACHE_AUDIO = `${CACHE_PREFIX}-audio-${VERSION}`;

// 📦 ARCHIVOS CRÍTICOS (solo lo esencial)
const CRITICAL_ASSETS = [
  '/',
  '/manifest.json',
  '/favicon.png'
];

// ⚡ INSTALACIÓN RÁPIDA
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_STATIC)
      .then(cache => cache.addAll(CRITICAL_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// 🔄 ACTIVACIÓN Y LIMPIEZA
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys
          .filter(key => key.startsWith(CACHE_PREFIX) && !key.endsWith(VERSION))
          .map(key => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

// 🌐 ESTRATEGIA DE FETCH SIMPLIFICADA
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Solo interceptar requests del mismo origen
  if (url.origin !== location.origin) return;
  
  // 🎵 Audio: Cache-First
  if (request.url.includes('.mp3') || request.url.includes('.wav') || request.url.includes('/audio/')) {
    event.respondWith(handleAudio(request));
    return;
  }
  
  // 📱 Navegación: Network-First con Offline fallback  
  if (request.mode === 'navigate') {
    event.respondWith(handleNavigation(request));
    return;
  }
  
  // 📦 Assets: Cache-First con Network fallback
  event.respondWith(handleAssets(request));
});

// 🎵 MANEJO DE AUDIO OPTIMIZADO
async function handleAudio(request) {
  try {
    const cachedResponse = await caches.match(request, { cacheName: CACHE_AUDIO });
    if (cachedResponse) return cachedResponse;
    
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_AUDIO);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch {
    // Retornar respuesta vacía para audio fallido
    return new Response('', { status: 200, headers: { 'Content-Type': 'audio/wav' } });
  }
}

// 📱 MANEJO DE NAVEGACIÓN
async function handleNavigation(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_DYNAMIC);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch {
    // Offline: Buscar en cache o mostrar página offline
    const cachedResponse = await caches.match(request);
    if (cachedResponse) return cachedResponse;
    
    const offlinePage = await caches.match('/sin-conexion');
    if (offlinePage) return offlinePage;
    
    // Fallback básico
    return new Response(`
      <!DOCTYPE html>
      <html lang="es">
      <head>
        <meta charset="UTF-8">
        <title>Sin Conexión</title>
        <style>body{font-family:Arial;text-align:center;padding:50px;color:#666}</style>
      </head>
      <body>
        <h1>🎵 Academia Vallenata</h1>
        <p>Sin conexión a internet</p>
        <button onclick="location.reload()">🔄 Reintentar</button>
      </body>
      </html>
    `, { headers: { 'Content-Type': 'text/html' } });
  }
}

// 📦 MANEJO DE ASSETS
async function handleAssets(request) {
  try {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) return cachedResponse;
    
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_STATIC);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch {
    throw new Error('Asset no disponible');
  }
}

// 🔔 NOTIFICACIONES PUSH SIMPLIFICADAS
self.addEventListener('push', event => {
  if (!event.data) return;
  
  const data = event.data.json();
  const options = {
    body: data.message || 'Nueva notificación',
    icon: '/iconos-pwa/icon-192x192.png',
    badge: '/iconos-pwa/icon-72x72.png',
    tag: data.tag || 'general',
    data: { url: data.url || '/' }
  };
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Academia Vallenata', options)
  );
});

// 🔔 CLICK EN NOTIFICACIONES
self.addEventListener('notificationclick', event => {
  event.notification.close();
  
  const url = event.notification.data?.url || '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window' })
      .then(clientList => {
        for (const client of clientList) {
          if (client.url.includes(location.origin)) {
            client.navigate(url);
            return client.focus();
          }
        }
        return clients.openWindow(url);
      })
  );
});

// 📊 MENSAJE PARA ESTADÍSTICAS (simplificado)
self.addEventListener('message', event => {
  if (event.data?.type === 'GET_CACHE_STATS') {
    caches.keys().then(keys => {
      event.ports[0]?.postMessage({
        caches: keys.length,
        version: VERSION
      });
    });
  }
});

console.log(`🚀 Academia Vallenata SW ${VERSION} - Optimizado y liviano!`); 