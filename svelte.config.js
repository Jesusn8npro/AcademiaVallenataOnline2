import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: { 
		adapter: adapter({
			// Configuración específica para producción en Docker
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
		// CSP COMPLETAMENTE DESHABILITADO EN DESARROLLO
		// csp: {
		// 	mode: 'auto',
		// 	directives: {
		// 		'script-src': ['self', 'unsafe-inline', 'https://checkout.epayco.co', 'https://tbijzvtyyewhtwgakgka.supabase.co'],
		// 		'style-src': ['self', 'unsafe-inline'],
		// 		'img-src': ['self', 'data:', 'https:'],
		// 		'connect-src': ['self', 'https://checkout.epayco.co', 'https://tbijzvtyyewhtwgakgka.supabase.co', 'wss://'],
		// 		'frame-src': ['self', 'unsafe-inline', 'https:', 'data:', '*']
		// 	}
		// }
	}
};

export default config;
