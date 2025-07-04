/**
 * Utilidades para el manejo de slugs en la aplicación
 */

/**
 * Genera un slug a partir de un texto
 * @param text Texto del que se generará el slug
 * @returns Slug generado
 */
export function generateSlug(text: string): string {
  return text
    .toString()
    .normalize('NFD')                   // Normaliza caracteres acentuados
    .replace(/[\u0300-\u036f]/g, '')    // Elimina diacríticos
    .toLowerCase()
    .replace(/[^\w\s-]/g, '')           // Elimina caracteres especiales
    .replace(/\s+/g, '-')               // Reemplaza espacios con guiones
    .replace(/--+/g, '-')               // Elimina guiones múltiples
    .trim();                            // Elimina espacios al inicio y final
}

/**
 * Genera un slug único añadiendo timestamp
 * @param text Texto del que se generará el slug
 * @returns Slug único generado
 */
export function generateUniqueSlug(text: string): string {
  const baseSlug = generateSlug(text);
  const timestamp = Date.now();
  return `${baseSlug}-${timestamp}`;
}

/**
 * Obtiene el ID de un curso desde una URL que usa slug
 * @param slug Slug del curso/módulo/lección
 * @param items Array de objetos que contienen id y título
 * @returns ID correspondiente al slug o null si no existe
 */
export function getIdFromSlug(slug: string, items: Array<{ id: string, titulo: string }>): string | null {
  // Primera opción: Buscar por slug exacto
  const foundByExactSlug = items.find(item => generateSlug(item.titulo) === slug);
  if (foundByExactSlug) return foundByExactSlug.id;
  
  // Segunda opción: Buscar por slug parcial (para manejar slugs con timestamp)
  // Primero extraemos la parte base del slug (sin el timestamp)
  const slugBase = slug.split('-').slice(0, -1).join('-');
  // Si el slug no tiene un timestamp o es muy corto, omitimos esta búsqueda
  if (slugBase.length > 3) {
    const foundByBaseSlug = items.find(item => {
      const itemSlug = generateSlug(item.titulo);
      return itemSlug === slugBase || slug.startsWith(itemSlug + '-');
    });
    if (foundByBaseSlug) return foundByBaseSlug.id;
  }
  
  // Tercera opción: Asumimos que podría ser un ID directo
  const foundById = items.find(item => item.id === slug);
  return foundById ? foundById.id : null;
}

/**
 * Obtiene el slug a partir de un ID
 * @param id ID del elemento
 * @param items Array de objetos que contienen id y título
 * @returns Slug generado o el ID original si no se encuentra
 */
export function getSlugFromId(id: string, items: Array<{ id: string, titulo: string }>): string {
  const item = items.find(item => item.id === id);
  return item ? generateSlug(item.titulo) : id;
} 