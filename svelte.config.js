import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: { 
		adapter: adapter(),
		alias: {
			'$lib': 'src/lib'
		},
		// Configuración para producción
		env: {
			privatePrefix: 'PRIVATE_',
			publicPrefix: 'VITE_'
		},
		// CSP Corregido para desarrollo y producción
		csp: {
			mode: 'auto',
			directives: {
				'default-src': ['self'],
				'script-src': ['self', 'unsafe-inline', 'unsafe-eval', 'https://checkout.epayco.co', 'https://www.google-analytics.com', 'https://www.googletagmanager.com', 'https://cdn.jsdelivr.net'],
				'style-src': ['self', 'unsafe-inline', 'https://fonts.googleapis.com'],
				'font-src': ['self', 'https://fonts.gstatic.com'],
				'img-src': ['self', 'data:', 'https:', 'blob:'],
				'connect-src': ['self', 'https://tbijzvtyyewhtwgakgka.supabase.co', 'https://api.epayco.co', 'https://www.google-analytics.com'],
				'frame-src': ['self', 'https://checkout.epayco.co'],
				'object-src': ['none'],
				'base-uri': ['self'],
				'form-action': ['self']
			}
		}
	}
};

export default config;
