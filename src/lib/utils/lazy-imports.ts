// 🚀 LAZY IMPORTS - Optimización de Rendimiento
// Importaciones dinámicas para componentes pesados

// 🎨 COMPONENTES PESADOS (> 50KB)
export const lazyCalendarioEventos = () => import('$lib/components/Eventos/CalendarioEventos.svelte');
export const lazyFeedPublicaciones = () => import('$lib/components/Comunidad/FeedPublicaciones.svelte');

// 📊 COMPONENTES DE ADMIN (existentes)
export const lazyTarjetaEstadistica = () => import('$lib/components/Administrador/TarjetaEstadistica.svelte');

// 📱 FUNCIONES DE SERVICIOS PESADOS (importación dinámica)
export const lazySupabaseAdmin = () => import('$lib/services/adminService');
export const lazyGamificacion = () => import('$lib/services/gamificacionService');
export const lazyComunidadService = () => import('$lib/services/comunidadService');
export const lazyCancionesService = () => import('$lib/services/cancionesService');

// 💳 SERVICIOS DE PAGO (solo cuando se necesiten)
export const lazyEPayco = () => import('$lib/services/pagoService');
export const lazyMembership = () => import('$lib/services/membershipService');

// 🔔 NOTIFICACIONES Y MENSAJERÍA
export const lazyNotificaciones = () => import('$lib/services/notificacionesService');
export const lazyMensajeria = () => import('$lib/services/mensajeriaService');

// 📈 UTILIDADES PARA LAZY LOADING
export function createLazyComponent(importFn: () => Promise<any>, fallback?: any) {
  return {
    component: importFn,
    fallback: fallback || null
  };
}

// 🎯 PRESETS COMUNES
export const LAZY_PRESETS = {
  // Para página de administrador
  admin: {
    tarjeta: createLazyComponent(lazyTarjetaEstadistica),
    service: createLazyComponent(lazySupabaseAdmin)
  },
  
  // Para comunidad
  community: {
    feed: createLazyComponent(lazyFeedPublicaciones),
    service: createLazyComponent(lazyComunidadService)
  },
  
  // Para eventos
  events: {
    calendario: createLazyComponent(lazyCalendarioEventos)
  },
  
  // Para servicios pesados
  services: {
    gamificacion: createLazyComponent(lazyGamificacion),
    pagos: createLazyComponent(lazyEPayco),
    mensajeria: createLazyComponent(lazyMensajeria)
  }
};

// 🔍 DETECTOR DE FUNCIONES CRÍTICAS
export function shouldLazyLoad(componentName: string): boolean {
  const criticalComponents = [
    'Navigation', 'Header', 'Footer', 'Layout'
  ];
  
  return !criticalComponents.some(critical => 
    componentName.toLowerCase().includes(critical.toLowerCase())
  );
}

// ⚡ PRELOAD CONDICIONAL
export async function conditionalPreload(condition: boolean, importFn: () => Promise<any>) {
  if (condition) {
    // Preload en el próximo tick
    setTimeout(() => importFn(), 0);
  }
}

// 🎯 PRELOAD BASADO EN INTERSECCIÓN
export function preloadOnHover(element: HTMLElement, importFn: () => Promise<any>) {
  let preloaded = false;
  
  const preload = () => {
    if (!preloaded) {
      preloaded = true;
      importFn();
    }
  };
  
  element.addEventListener('mouseenter', preload, { once: true });
  element.addEventListener('touchstart', preload, { once: true });
}

// 📊 MÉTRICAS DE LAZY LOADING (solo en desarrollo)
export const LazyMetrics = {
  loaded: new Set<string>(),
  
  track(componentName: string) {
    this.loaded.add(componentName);
    if (import.meta.env.DEV) {
      console.log(`📦 Lazy loaded: ${componentName} (${this.loaded.size} total)`);
    }
  },
  
  getStats() {
    return {
      totalLazyLoaded: this.loaded.size,
      components: Array.from(this.loaded)
    };
  }
}; 