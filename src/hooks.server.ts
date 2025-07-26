import type { Handle } from '@sveltejs/kit';

// CORRECCIÓN: Prevenir problemas de cache de HTML que refiera a assets inexistentes
// Esto soluciona el problema de pantallas en blanco tras deploys
export const handle: Handle = async ({ event, resolve }) => {
	const response = await resolve(event);
	
	// Evitar cache de HTML para prevenir que se use HTML viejo con assets nuevos
	if (response.headers.get('content-type')?.includes('text/html')) {
		response.headers.set('cache-control', 'no-cache, no-store, must-revalidate');
		response.headers.set('pragma', 'no-cache');
		response.headers.set('expires', '0');
	}
	
	// Permitir cache de assets estáticos (JS, CSS, imágenes)
	if (event.url.pathname.includes('/assets/') || 
		event.url.pathname.includes('/_app/') ||
		event.url.pathname.includes('/static/')) {
		response.headers.set('cache-control', 'public, max-age=31536000, immutable');
	}
	
	return response;
}; 