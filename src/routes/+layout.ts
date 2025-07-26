// CORRECCIÓN: Evitar problemas de hydration mismatch en producción
export const prerender = false;

// CORRECCIÓN: Asegurar que SSR esté habilitado (por defecto, pero explícito)
export const ssr = true;

// CORRECCIÓN: Habilitar CSR para interactividad
export const csr = true;

// CORRECCIÓN: Configurar trailing slash para evitar problemas de navegación
export const trailingSlash = 'always'; 