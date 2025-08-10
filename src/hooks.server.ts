import type { Handle } from '@sveltejs/kit';

export const handle = (async ({ event, resolve }) => {
  console.log('🔧 [HOOKS] Procesando request:', event.url.pathname);
  
  const response = await resolve(event);
  
  // 🔧 CONFIGURAR HEADERS PARA EVITAR BFCACHE PROBLEMS
  
  // Para páginas HTML, evitar cache completo
  if (response.headers.get('content-type')?.includes('text/html')) {
    response.headers.set('cache-control', 'no-cache, no-store, must-revalidate');
    response.headers.set('pragma', 'no-cache');
    response.headers.set('expires', '0');
    
    console.log('📝 [CACHE] Headers no-cache aplicados a HTML');
  }
  
  // Para assets estáticos, permitir cache pero con validación
  if (event.url.pathname.startsWith('/_app/') || 
      event.url.pathname.startsWith('/static/') ||
      event.url.pathname.match(/\.(js|css|png|jpg|svg|ico)$/)) {
    response.headers.set('cache-control', 'public, max-age=31536000, immutable');
    console.log('🎯 [CACHE] Cache largo aplicado a assets');
  }
  
  // Headers adicionales para navegación robusta
  response.headers.set('x-content-type-options', 'nosniff');
  response.headers.set('x-frame-options', 'DENY');
  
  return response;
}) satisfies Handle; 