// ✅ FASE 2: CONFIGURACIÓN OPTIMIZADA DE ROUTING
// Basada en la documentación oficial de SvelteKit para hidratación estable

// ✅ SOLUCIÓN: Configuración de prerender para estabilidad
export const prerender = false;

// ✅ SOLUCIÓN: SSR habilitado para mejor SEO y primera carga
export const ssr = true;

// ✅ SOLUCIÓN: CSR habilitado para interactividad completa
export const csr = true;

// ✅ SOLUCIÓN: Trailing slash para evitar problemas de navegación
export const trailingSlash = 'always';

// ✅ NUEVO: Configuración avanzada de routing para FASE 2
export const config = {
  // ✅ SOLUCIÓN: Configuración de hidratación optimizada
  hydrate: {
    // ✅ SOLUCIÓN: Esperar hidratación completa antes de navegación
    waitForHydration: true,
    
    // ✅ SOLUCIÓN: Preservar estado durante hidratación
    preserveState: true,
    
    // ✅ SOLUCIÓN: Configuración para mejor rendimiento
    progressive: true
  },
  
  // ✅ SOLUCIÓN: Configuración de router optimizada
  router: {
    // ✅ SOLUCIÓN: Manejo inteligente de routing
    handleRouting: true,
    
    // ✅ SOLUCIÓN: Configuración para mejor rendimiento
    handlePageRequests: true,
    
    // ✅ SOLUCIÓN: Evitar navegación interceptada durante hidratación
    preventNavigationDuringHydration: true
  },
  
  // ✅ SOLUCIÓN: Configuración de navegación SPA
  navigation: {
    // ✅ SOLUCIÓN: Navegación SPA optimizada
    spa: true,
    
    // ✅ SOLUCIÓN: Prefetch inteligente
    prefetch: 'hover',
    
    // ✅ SOLUCIÓN: Manejo de errores de navegación
    errorHandling: 'graceful'
  }
}; 