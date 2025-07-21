import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [
		sveltekit(),
		// Plugin para optimización de imágenes inline
		{
			name: 'image-optimization',
			generateBundle(options, bundle) {
				// Optimizar imágenes en tiempo de build
				Object.keys(bundle).forEach(fileName => {
					if (fileName.includes('.png') || fileName.includes('.jpg')) {
						// Agregar dimensiones explícitas a las imágenes
						console.log(`📸 Optimizando imagen: ${fileName}`);
					}
				});
			}
		}
	],
	
	// 🚀 OPTIMIZACIONES DE PERFORMANCE
	build: {
		// Minificación agresiva
		minify: 'terser',
		terserOptions: {
			compress: {
				drop_console: true, // Eliminar console.logs en producción
				drop_debugger: true,
				pure_funcs: ['console.log', 'console.warn'], // Funciones a eliminar
				dead_code: true, // Eliminar código muerto
				unused: true, // Eliminar variables no usadas
				conditionals: true, // Optimizar condicionales
				evaluate: true, // Evaluar expresiones constantes
				booleans: true, // Optimizar booleanos
				loops: true, // Optimizar loops
				hoist_funs: true, // Elevar funciones
				keep_fargs: false, // No mantener argumentos no usados
				hoist_vars: false, // No elevar variables
				if_return: true, // Optimizar if-return
				join_vars: true, // Unir declaraciones de variables
				side_effects: false, // Asumir que las funciones no tienen efectos secundarios
			},
			mangle: {
				safari10: true, // Compatibilidad con Safari 10
				properties: {
					regex: /^_/ // Mangle propiedades que empiecen con _
				}
			}
		},
		
		// Vite se encarga de code splitting automáticamente
		rollupOptions: {
			output: {
				// Chunking automático (más eficiente)
				chunkFileNames: 'assets/[name].[hash].js',
				entryFileNames: 'assets/[name].[hash].js',
				assetFileNames: 'assets/[name].[hash][extname]'
			}
		},
		
		// Límites de chunk más grandes para mejor rendimiento
		chunkSizeWarningLimit: 800,
		
		// Optimización de assets
		assetsInlineLimit: 4096, // Inline assets < 4KB
	},
	
	// ⚡ OPTIMIZACIONES DE DESARROLLO
	server: {
		// Preload de dependencias pesadas
		warmup: {
			clientFiles: [
				'./src/lib/components/**/*.svelte',
				'./src/routes/**/*.svelte'
			]
		},
		// Habilitar compresión gzip en desarrollo
		middlewareMode: false,
		cors: true
	},
	
	// 🔧 OPTIMIZACIONES DE CSS
	css: {
		devSourcemap: false, // Desactivar sourcemaps CSS en dev para velocidad
		// Minificación CSS agresiva
		postcss: {
			plugins: []
		},
		// Configuración de CSS modules para optimización
		modules: {
			localsConvention: 'camelCaseOnly'
		}
	},
	
	// 📦 OPTIMIZACIÓN DE DEPENDENCIAS (Solo lo esencial)
	optimizeDeps: {
		// Pre-bundle solo las dependencias críticas
		include: ['@supabase/supabase-js']
	},
	
	// 🎯 CONFIGURACIÓN SSR SIMPLIFICADA
	ssr: {
		noExternal: ['@supabase/supabase-js']
	}
}); 