/**
 * Utilidades para manejar avatares de usuario
 */

/**
 * Genera una URL de avatar por defecto usando UI Avatars
 */
export function generarAvatarPorDefecto(nombre: string, opciones?: {
  background?: string;
  color?: string;
  size?: number;
}): string {
  const config = {
    background: opciones?.background || '667eea',
    color: opciones?.color || 'fff',
    size: opciones?.size || 200
  };
  
  const nombreLimpio = nombre?.trim() || 'Usuario';
  const iniciales = nombreLimpio
    .split(' ')
    .map(palabra => palabra.charAt(0))
    .join('')
    .toUpperCase()
    .slice(0, 2);
  
  return `https://ui-avatars.com/api/?name=${encodeURIComponent(iniciales)}&background=${config.background}&color=${config.color}&size=${config.size}&font-size=0.6`;
}

/**
 * Obtiene el avatar del usuario con fallback
 */
export function obtenerAvatarUsuario(usuario: any): string {
  // Prioridad de campos para el avatar
  const urlAvatar = usuario?.url_foto_perfil || 
                   usuario?.imagen_perfil || 
                   usuario?.avatar;
  
  if (urlAvatar && urlAvatar.trim()) {
    return urlAvatar;
  }
  
  // Generar nombre para el avatar por defecto
  const nombre = usuario?.nombre_completo || 
                usuario?.nombre || 
                usuario?.usuario_nombre || 
                usuario?.nombre_usuario ||
                'Usuario';
  
  return generarAvatarPorDefecto(nombre);
}

/**
 * Verifica si una URL de imagen es válida
 */
export async function verificarImagenValida(url: string): Promise<boolean> {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return response.ok && (response.headers.get('content-type')?.startsWith('image/') ?? false);
  } catch {
    return false;
  }
} 