import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: { 
		adapter: adapter({
			out: 'build',
			// 🗜️ HABILITAR PRECOMPRESIÓN PARA PRODUCCIÓN
			precompress: true, 
			envPrefix: ''
		}),
		alias: {
			'$lib': 'src/lib'
		},
		// 🔧 CONFIGURACIÓN OPTIMIZADA PARA PRODUCCIÓN
		env: {
			privatePrefix: 'PRIVATE_',
			publicPrefix: 'VITE_'
		},
		
		// 🛡️ CSP OPTIMIZADO PARA SEGURIDAD Y PERFORMANCE
		csp: {
			mode: 'auto',
			directives: {
				'default-src': ['self'],
				'script-src': [
					'self', 
					'unsafe-inline', 
					'unsafe-eval', 
					'https://checkout.epayco.co', 
					'https://www.google-analytics.com', 
					'https://www.googletagmanager.com', 
					'https://cdn.jsdelivr.net', 
					'https://www.youtube.com', 
					'https://s.ytimg.com', 
					'https://iframe.mediadelivery.net', 
					'https://*.mediadelivery.net', 
					'https://*.bunnycdn.com'
				],
				'style-src': ['self', 'unsafe-inline', 'https://fonts.googleapis.com'],
				'font-src': ['self', 'https://fonts.gstatic.com'],
				'img-src': ['self', 'data:', 'https:', 'blob:', 'https://i.ytimg.com', 'https://img.youtube.com'],
				'connect-src': [
					'self', 
					'https://*.supabase.co', 
					'wss://*.supabase.co', 
					'https://api.epayco.co', 
					'https://www.google-analytics.com', 
					'https://www.youtube.com', 
					'https://iframe.mediadelivery.net', 
					'https://*.mediadelivery.net', 
					'https://*.bunnycdn.com',
					'https://ipapi.co',
					'https://*.ipapi.co',
					'https://api.ipapi.is',
					'https://*.ipapi.is'
				],
				'frame-src': [
					'self', 
					'https://checkout.epayco.co', 
					'https://www.youtube.com', 
					'https://www.youtube-nocookie.com', 
					'https://iframe.mediadelivery.net', 
					'https://*.mediadelivery.net', 
					'https://*.bunnycdn.com'
				],
				'object-src': ['none'],
				'base-uri': ['self'],
				'form-action': ['self'],
				'media-src': ['self', 'https:', 'blob:', 'data:']
			}
		},
		
		// 📱 PWA Y PERFORMANCE OPTIMIZATIONS
		serviceWorker: {
			register: false // Deshabilitar por ahora hasta implementar correctamente
		},
		
		// 🎯 OPTIMIZACIONES DE ROUTING (removido trailingSlash por compatibilidad)
		
		// 🔧 CONFIGURACIÓN DE TYPESCRIPT
		typescript: {
			config: (config) => {
				// Optimizaciones para build de producción
				config.compilerOptions.sourceMap = false;
				return config;
			}
		}
	}
};

export default config;
