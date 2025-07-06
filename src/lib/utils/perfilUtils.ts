/**
 * Genera la URL del perfil público de un usuario
 * @param nombreUsuario - El nombre_usuario del perfil
 * @returns URL del perfil público o null si no hay nombre_usuario
 */
export function generarUrlPerfilPublico(nombreUsuario: string | null | undefined): string | null {
  if (!nombreUsuario) return null;
  return `/usuario/${nombreUsuario}`;
}

/**
 * Verifica si un nombre de usuario es válido para URLs
 * @param nombreUsuario - Nombre de usuario a validar
 * @returns boolean
 */
export function esNombreUsuarioValido(nombreUsuario: string | null | undefined): boolean {
  if (!nombreUsuario) return false;
  // Solo letras, números, guiones y guiones bajos
  return /^[a-zA-Z0-9_-]+$/.test(nombreUsuario);
}

/**
 * Normaliza un nombre de usuario para uso en URLs
 * @param nombreUsuario - Nombre a normalizar
 * @returns Nombre normalizado o null si no es válido
 */
export function normalizarNombreUsuario(nombreUsuario: string | null | undefined): string | null {
  if (!nombreUsuario) return null;
  
  // Convertir a minúsculas y reemplazar espacios con guiones
  const normalizado = nombreUsuario
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9_-]/g, '');
  
  return normalizado.length > 0 ? normalizado : null;
} 