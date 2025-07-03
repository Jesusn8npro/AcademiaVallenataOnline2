import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url, request }) => {
  try {
    const targetUrl = url.searchParams.get('url');
    if (!targetUrl) {
      throw error(400, 'URL no proporcionada');
    }

    // Verificar que la URL es de Bunny.net
    if (!targetUrl.includes('iframe.mediadelivery.net') && !targetUrl.includes('video.bunnycdn.com')) {
      throw error(400, 'URL no válida');
    }

    const response = await fetch(targetUrl, {
      headers: {
        'User-Agent': request.headers.get('User-Agent') || 'SvelteKit',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'es-ES,es;q=0.8,en-US;q=0.5,en;q=0.3',
        'Referer': url.origin,
        'Origin': url.origin
      }
    });

    if (!response.ok) {
      console.error('Error en proxy Bunny:', {
        status: response.status,
        statusText: response.statusText,
        url: targetUrl
      });
      throw error(response.status, 'Error al obtener el video');
    }

    // Copiar los headers relevantes
    const headers = new Headers();
    response.headers.forEach((value, key) => {
      if (key.toLowerCase() === 'content-type' || 
          key.toLowerCase() === 'content-length' ||
          key.toLowerCase() === 'cache-control') {
        headers.set(key, value);
      }
    });

    // Agregar headers CORS
    headers.set('Access-Control-Allow-Origin', '*');
    headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
    headers.set('Access-Control-Allow-Headers', 'Content-Type');

    return new Response(response.body, {
      status: 200,
      headers
    });
  } catch (err) {
    console.error('Error en proxy Bunny:', err);
    throw error(500, 'Error interno del servidor');
  }
}; 