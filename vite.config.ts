import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		host: '0.0.0.0',
		port: 5173,
		hmr: {
			port: 5173
		}
	},
	build: {
		// Optimizaciones para producción
		minify: 'esbuild',
		target: 'es2020'
	},
	optimizeDeps: {
		include: ['@supabase/supabase-js', 'date-fns', 'quill']
	}
});
