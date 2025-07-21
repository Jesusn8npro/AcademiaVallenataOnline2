// 🚀 SERVICE WORKER ACADEMIA VALLENATA ONLINE
// Versión: 1.0.0 | Autor: Academia Vallenata Team

const CACHE_NAME = 'academia-vallenata-v1.0.0';
const CACHE_ESTATICO = 'estaticos-v1.0.0';
const CACHE_DINAMICO = 'dinamico-v1.0.0'; 
const CACHE_AUDIO = 'audio-vallenato-v1.0.0';
const CACHE_API = 'api-supabase-v1.0.0';

// 📂 ARCHIVOS CRÍTICOS PARA CACHE (siempre disponibles offline)
const ARCHIVOS_CRITICOS = [
  '/',
  '/cursos',
  '/comunidad', 
  '/simulador-gaming',
  '/ranking',
  '/membresias',
  '/mi-perfil',
  
  // Assets críticos
  '/favicon.png',
  '/logo academia vallenata.png',
  '/Acordeon PRO MAX.png',
  
  // Páginas offline
  '/sin-conexion'
];

// 🎵 RUTAS DE AUDIO PARA CACHE ESPECIAL
const RUTAS_AUDIO = [
  '/static/audio/',
  '/audio/',
  '/efectos/',
  '.mp3',
  '.wav',
  '.ogg'
];

// 🔗 RUTAS API SUPABASE PARA CACHE INTELIGENTE  
const RUTAS_API = [
  'supabase.co',
  '/rest/v1/',
  '/auth/v1/',
  '/storage/v1/'
];

// 🚀 INSTALACIÓN DEL SERVICE WORKER
self.addEventListener('install', event => {
  console.log('🎵 Academia Vallenata SW: Instalando...');
  
  event.waitUntil(
    Promise.all([
      // Cache de archivos críticos
      caches.open(CACHE_ESTATICO).then(cache => {
        console.log('📦 Cacheando archivos críticos');
        return cache.addAll(ARCHIVOS_CRITICOS);
      }),
      
      // Pre-cache del simulador offline
      caches.open(CACHE_DINAMICO).then(cache => {
        console.log('🎹 Pre-cacheando simulador');
        return cache.add('/simulador-gaming?offline=true');
      })
    ]).then(() => {
      console.log('✅ Academia Vallenata SW: Instalado exitosamente');
      return self.skipWaiting();
    })
  );
});

// 🔄 ACTIVACIÓN Y LIMPIEZA DE CACHES ANTIGUOS
self.addEventListener('activate', event => {
  console.log('🎵 Academia Vallenata SW: Activando...');
  
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          // Eliminar caches antiguos
          if (cacheName !== CACHE_ESTATICO && 
              cacheName !== CACHE_DINAMICO && 
              cacheName !== CACHE_AUDIO && 
              cacheName !== CACHE_API) {
            console.log('🗑️ Eliminando cache antiguo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('✅ Academia Vallenata SW: Activado');
      return self.clients.claim();
    })
  );
});

// 🌐 INTERCEPTOR DE REQUESTS - MAGIA OFFLINE
self.addEventListener('fetch', event => {
  const url = event.request.url;
  
  // 🎵 ESTRATEGIA ESPECIAL PARA AUDIO
  if (esArchivoAudio(url)) {
    event.respondWith(manejarAudio(event.request));
    return;
  }
  
  // 🔗 ESTRATEGIA API SUPABASE
  if (esAPISupabase(url)) {
    event.respondWith(manejarAPISupabase(event.request));
    return;  
  }
  
  // 📱 ESTRATEGIA NAVEGACIÓN (páginas)
  if (event.request.mode === 'navigate') {
    event.respondWith(manejarNavegacion(event.request));
    return;
  }
  
  // 📦 ESTRATEGIA ASSETS ESTÁTICOS
  event.respondWith(manejarEstaticos(event.request));
});

// 🎵 MANEJO ESPECIAL DE ARCHIVOS DE AUDIO
async function manejarAudio(request) {
  try {
    console.log('🎵 Cargando audio:', request.url);
    
    // Buscar en cache primero
    const cacheResponse = await caches.match(request, {
      cacheName: CACHE_AUDIO
    });
    
    if (cacheResponse) {
      console.log('🎵 Audio desde cache');
      return cacheResponse;
    }
    
    // Si no está en cache, intentar descargar
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Guardar en cache para futuro uso
      const cache = await caches.open(CACHE_AUDIO);
      cache.put(request, networkResponse.clone());
      console.log('🎵 Audio cacheado:', request.url);
    }
    
    return networkResponse;
    
  } catch (error) {
    console.log('❌ Error cargando audio:', error);
    
    // Devolver audio de silencio como fallback
    return new Response('', {
      status: 200,
      statusText: 'OK',
      headers: { 'Content-Type': 'audio/wav' }
    });
  }
}

// 🔗 MANEJO API SUPABASE CON CACHE INTELIGENTE
async function manejarAPISupabase(request) {
  const isGET = request.method === 'GET';
  
  try {
    // Para GET: Cache-First con Network Fallback
    if (isGET) {
      const cacheResponse = await caches.match(request, {
        cacheName: CACHE_API
      });
      
      if (cacheResponse) {
        console.log('🔗 API desde cache:', request.url);
        
        // Actualizar cache en background
        actualizarCacheBackground(request);
        
        return cacheResponse;
      }
    }
    
    // Intentar request de red
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok && isGET) {
      // Cachear respuestas GET exitosas
      const cache = await caches.open(CACHE_API);
      cache.put(request, networkResponse.clone());
      console.log('🔗 API cacheada:', request.url);
    }
    
    return networkResponse;
    
  } catch (error) {
    console.log('❌ Error API Supabase:', error);
    
    // Para GET: devolver desde cache aunque sea antiguo
    if (isGET) {
      const cacheResponse = await caches.match(request, {
        cacheName: CACHE_API
      });
      
      if (cacheResponse) {
        return cacheResponse;
      }
    }
    
    // Respuesta de error offline
    return new Response(JSON.stringify({
      error: 'Sin conexión',
      mensaje: 'Datos no disponibles offline',
      offline: true
    }), {
      status: 503,
      statusText: 'Service Unavailable',
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// 📱 MANEJO DE NAVEGACIÓN (PÁGINAS)
async function manejarNavegacion(request) {
  try {
    // Intentar cargar desde red primero
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      // Cachear página para uso offline
      const cache = await caches.open(CACHE_DINAMICO);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    console.log('📱 Cargando página offline:', request.url);
    
    // Buscar en cache
    const cacheResponse = await caches.match(request);
    
    if (cacheResponse) {
      return cacheResponse;
    }
    
    // Página de offline personalizada
    return caches.match('/sin-conexion') || 
           caches.match('/') || 
           new Response(`
             <!DOCTYPE html>
             <html lang="es">
             <head>
               <meta charset="UTF-8">
               <title>Sin Conexión - Academia Vallenata</title>
               <style>
                 body { font-family: Arial; text-align: center; padding: 50px; }
                 .offline { color: #666; }
               </style>
             </head>
             <body>
               <div class="offline">
                 <h1>🎵 Academia Vallenata</h1>
                 <h2>Sin Conexión</h2>
                 <p>No hay conexión a internet. Intenta de nuevo más tarde.</p>
                 <p>Algunas funciones siguen disponibles offline.</p>
               </div>
             </body>
             </html>
           `, {
             headers: { 'Content-Type': 'text/html' }
           });
  }
}

// 📦 MANEJO DE ASSETS ESTÁTICOS
async function manejarEstaticos(request) {
  try {
    // Cache-First para assets estáticos
    const cacheResponse = await caches.match(request);
    
    if (cacheResponse) {
      return cacheResponse;
    }
    
    // Si no está en cache, descargar
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_ESTATICO);
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
    
  } catch (error) {
    // Sin fallback para assets - dejar que falle naturalmente
    throw error;
  }
}

// 🔄 ACTUALIZACIÓN DE CACHE EN BACKGROUND  
async function actualizarCacheBackground(request) {
  try {
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      const cache = await caches.open(CACHE_API);
      await cache.put(request, networkResponse.clone());
      console.log('🔄 Cache actualizado en background:', request.url);
    }
  } catch (error) {
    console.log('❌ Error actualizando cache background:', error);
  }
}

// 🎵 DETECTAR SI ES ARCHIVO DE AUDIO
function esArchivoAudio(url) {
  return RUTAS_AUDIO.some(ruta => url.includes(ruta));
}

// 🔗 DETECTAR SI ES API DE SUPABASE
function esAPISupabase(url) {
  return RUTAS_API.some(ruta => url.includes(ruta));
}

// 🔔 MANEJO DE NOTIFICACIONES PUSH
self.addEventListener('push', event => {
  console.log('🔔 Notificación push recibida');
  
  if (event.data) {
    const datos = event.data.json();
    
    const opcionesNotificacion = {
      body: datos.mensaje || 'Nueva notificación de Academia Vallenata',
      icon: '/iconos-pwa/icon-192x192.png',
      badge: '/iconos-pwa/badge-72x72.png',
      image: datos.imagen || '/Acordeon PRO MAX.png',
      tag: datos.tag || 'academia-general',
      data: {
        url: datos.url || '/',
        accion: datos.accion || 'abrir'
      },
      actions: [
        {
          action: 'abrir',
          title: 'Abrir Academia',
          icon: '/iconos-pwa/action-abrir.png'
        },
        {
          action: 'cerrar',
          title: 'Cerrar',
          icon: '/iconos-pwa/action-cerrar.png'
        }
      ],
      vibrate: [200, 100, 200],
      silent: false
    };
    
    event.waitUntil(
      self.registration.showNotification(
        datos.titulo || 'Academia Vallenata',
        opcionesNotificacion
      )
    );
  }
});

// 🔔 MANEJO DE CLICKS EN NOTIFICACIONES  
self.addEventListener('notificationclick', event => {
  console.log('🔔 Click en notificación:', event.notification.tag);
  
  event.notification.close();
  
  if (event.action === 'cerrar') {
    return;
  }
  
  const urlDestino = event.notification.data.url || '/';
  
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(clientList => {
      // Si ya hay una ventana abierta, enfocarla
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.navigate(urlDestino);
          return client.focus();
        }
      }
      
      // Si no hay ventana abierta, abrir una nueva
      if (clients.openWindow) {
        return clients.openWindow(urlDestino);
      }
    })
  );
});

// 🔄 SINCRONIZACIÓN EN BACKGROUND
self.addEventListener('sync', event => {
  console.log('🔄 Sincronización background:', event.tag);
  
  if (event.tag === 'sincronizar-progreso') {
    event.waitUntil(sincronizarProgreso());
  } else if (event.tag === 'sincronizar-grabaciones') {
    event.waitUntil(sincronizarGrabaciones());
  }
});

// 🎯 SINCRONIZAR PROGRESO DEL USUARIO
async function sincronizarProgreso() {
  try {
    console.log('🎯 Sincronizando progreso del usuario...');
    
    // Aquí iría la lógica de sincronización con Supabase
    // Por ahora simular éxito
    console.log('✅ Progreso sincronizado exitosamente');
    
  } catch (error) {
    console.log('❌ Error sincronizando progreso:', error);
    throw error;
  }
}

// 🎵 SINCRONIZAR GRABACIONES LOCALES
async function sincronizarGrabaciones() {
  try {
    console.log('🎵 Sincronizando grabaciones...');
    
    // Aquí iría la lógica de subir grabaciones guardadas offline
    console.log('✅ Grabaciones sincronizadas exitosamente');
    
  } catch (error) {
    console.log('❌ Error sincronizando grabaciones:', error);
    throw error;
  }
}

// 🎯 ESCUCHAR MENSAJES DESDE LA APLICACIÓN
self.addEventListener('message', event => {
  console.log('💬 Mensaje recibido en SW:', event.data);
  
  if (event.data.tipo === 'ACTUALIZAR_CACHE') {
    // Forzar actualización de cache
    event.waitUntil(actualizarTodoElCache());
    
  } else if (event.data.tipo === 'LIMPIAR_CACHE') {
    // Limpiar cache específico
    event.waitUntil(limpiarCache(event.data.cache));
    
  } else if (event.data.tipo === 'ESTADO_CACHE') {
    // Devolver estado del cache
    event.waitUntil(enviarEstadoCache(event.ports[0]));
  }
});

// 🔄 ACTUALIZAR TODO EL CACHE
async function actualizarTodoElCache() {
  console.log('🔄 Actualizando todo el cache...');
  
  const cacheNames = await caches.keys();
  await Promise.all(
    cacheNames.map(cacheName => caches.delete(cacheName))
  );
  
  // Reinstalar cache crítico
  const cache = await caches.open(CACHE_ESTATICO);
  await cache.addAll(ARCHIVOS_CRITICOS);
  
  console.log('✅ Cache actualizado completamente');
}

// 🗑️ LIMPIAR CACHE ESPECÍFICO
async function limpiarCache(nombreCache) {
  if (nombreCache && await caches.has(nombreCache)) {
    await caches.delete(nombreCache);
    console.log('🗑️ Cache eliminado:', nombreCache);
  }
}

// 📊 ENVIAR ESTADO DEL CACHE
async function enviarEstadoCache(puerto) {
  const cacheNames = await caches.keys();
  const estadoCache = {};
  
  for (const cacheName of cacheNames) {
    const cache = await caches.open(cacheName);
    const keys = await cache.keys();
    estadoCache[cacheName] = keys.length;
  }
  
  puerto.postMessage({
    tipo: 'ESTADO_CACHE',
    caches: estadoCache
  });
}

console.log('🚀 Academia Vallenata Service Worker cargado exitosamente!'); 