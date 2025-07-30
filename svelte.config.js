import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: { 
		adapter: adapter({
			out: 'build',
			precompress: false,
			envPrefix: ''
		}),
		alias: {
			'$lib': 'src/lib'
		},
		// Configuración para producción
		env: {
			privatePrefix: 'PRIVATE_',
			publicPrefix: 'VITE_'
		},
		// CSP Corregido para desarrollo, producción y reproductores de video
		csp: {
			mode: 'auto',
			directives: {
				'default-src': ['self'],
				'script-src': ['self', 'unsafe-inline', 'unsafe-eval', 'https://checkout.epayco.co', 'https://www.google-analytics.com', 'https://www.googletagmanager.com', 'https://cdn.jsdelivr.net', 'https://www.youtube.com', 'https://s.ytimg.com', 'https://iframe.mediadelivery.net', 'https://*.mediadelivery.net', 'https://*.bunnycdn.com'],
				'style-src': ['self', 'unsafe-inline', 'https://fonts.googleapis.com'],
				'font-src': ['self', 'https://fonts.gstatic.com'],
				'img-src': ['self', 'data:', 'https:', 'blob:', 'https://i.ytimg.com', 'https://img.youtube.com'],
				'connect-src': ['self', process.env.VITE_SUPABASE_URL || 'https://tbijzvtyyewhtwgakgka.supabase.co', 'wss://*.supabase.co', 'https://api.epayco.co', 'https://www.google-analytics.com', 'https://www.youtube.com', 'https://iframe.mediadelivery.net', 'https://*.mediadelivery.net', 'https://*.bunnycdn.com'],
				'frame-src': ['self', 'https://checkout.epayco.co', 'https://www.youtube.com', 'https://www.youtube-nocookie.com', 'https://iframe.mediadelivery.net', 'https://*.mediadelivery.net', 'https://*.bunnycdn.com'],
				'object-src': ['none'],
				'base-uri': ['self'],
				'form-action': ['self'],
				'media-src': ['self', 'https:', 'blob:', 'data:']
			}
		}
	}
};

export default config;
