import { supabase } from '$lib/supabase/clienteSupabase';
import { createClient } from '@supabase/supabase-js';
import { generarReferencia } from './ePaycoService';

// Cliente admin para operaciones que requieren bypass de RLS
const supabaseAdmin = createClient(
    import.meta.env.VITE_SUPABASE_URL,
    import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    }
);

// Tipos
export interface PaqueteTutorial {
    id?: string;
    titulo: string;
    descripcion?: string;
    descripcion_corta?: string;
    imagen_url?: string;
    precio_normal: number;
    precio_rebajado?: number;
    descuento_porcentaje?: number;
    estado: 'borrador' | 'publicado' | 'archivado';
    categoria?: string;
    nivel: 'principiante' | 'intermedio' | 'avanzado';
    destacado?: boolean;
    total_tutoriales?: number;
    duracion_total_estimada?: number;
    instructor_id?: string;
    tipo_acceso: 'gratuito' | 'premium' | 'vip';
    fecha_expiracion?: string;
    objetivos?: string;
    requisitos?: string;
    incluye?: string;
    ventajas?: string;
    slug?: string;
    meta_titulo?: string;
    meta_descripcion?: string;
    tags?: string[];
    orden_mostrar?: number;
    visible?: boolean;
    created_at?: string;
    updated_at?: string;
}

export interface PaqueteItem {
    id?: string;
    paquete_id: string;
    tutorial_id: string;
    orden: number;
    incluido: boolean;
    precio_individual_referencia?: number;
    notas?: string;
}

export interface ProgresoPaquete {
    id?: string;
    usuario_id: string;
    paquete_id: string;
    tutoriales_completados: number;
    tutoriales_totales: number;
    porcentaje_completado: number;
    ultimo_tutorial_id?: string;
    ultima_actividad: string;
    completado: boolean;
    fecha_completado?: string;
    tiempo_total_visto: number;
}

export interface ResultadoOperacion {
    success: boolean;
    data?: any;
    error?: string;
    message?: string;
}

// ===========================================
// FUNCIONES DE PAQUETES
// ===========================================

/**
 * Obtener todos los paquetes (para admin)
 */
export async function obtenerTodosPaquetes(): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .from('vista_paquetes_completos')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error obteniendo paquetes:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error: any) {
        console.error('Error en obtenerTodosPaquetes:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtener paquetes publicados (para usuarios)
 */
export async function obtenerPaquetesPublicados(): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .from('vista_paquetes_completos')
            .select('*')
            .eq('estado', 'publicado')
            .eq('visible', true)
            .order('destacado', { ascending: false })
            .order('orden_mostrar', { ascending: true });

        if (error) {
            console.error('Error obteniendo paquetes publicados:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error: any) {
        console.error('Error en obtenerPaquetesPublicados:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtener paquete por ID
 */
export async function obtenerPaquetePorId(id: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .from('paquetes_tutoriales')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Error obteniendo paquete:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Error en obtenerPaquetePorId:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtener paquete por slug
 */
export async function obtenerPaquetePorSlug(slug: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .from('vista_paquetes_completos')
            .select('*')
            .eq('slug', slug)
            .eq('estado', 'publicado')
            .single();

        if (error) {
            console.error('Error obteniendo paquete por slug:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data };
    } catch (error: any) {
        console.error('Error en obtenerPaquetePorSlug:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Crear nuevo paquete
 */
export async function crearPaquete(paquete: PaqueteTutorial): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .from('paquetes_tutoriales')
            .insert([paquete])
            .select('*')
            .single();

        if (error) {
            console.error('Error creando paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            data, 
            message: 'Paquete creado exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en crearPaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Actualizar paquete
 */
export async function actualizarPaquete(id: string, paquete: Partial<PaqueteTutorial>): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .from('paquetes_tutoriales')
            .update(paquete)
            .eq('id', id)
            .select('*')
            .single();

        if (error) {
            console.error('Error actualizando paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            data, 
            message: 'Paquete actualizado exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en actualizarPaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Eliminar paquete
 */
export async function eliminarPaquete(id: string): Promise<ResultadoOperacion> {
    try {
        const { error } = await supabaseAdmin
            .from('paquetes_tutoriales')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('Error eliminando paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            message: 'Paquete eliminado exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en eliminarPaquete:', error);
        return { success: false, error: error.message };
    }
}

// ===========================================
// FUNCIONES DE ITEMS DE PAQUETES
// ===========================================

/**
 * Obtener tutoriales de un paquete
 */
export async function obtenerTutorialesPaquete(paqueteId: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .from('paquetes_tutoriales_items')
            .select(`
                *,
                tutoriales:tutorial_id (
                    id,
                    titulo,
                    descripcion_corta,
                    imagen_url,
                    duracion_estimada,
                    precio_normal,
                    nivel,
                    categoria,
                    artista,
                    tonalidad
                )
            `)
            .eq('paquete_id', paqueteId)
            .eq('incluido', true)
            .order('orden', { ascending: true });

        if (error) {
            console.error('Error obteniendo tutoriales del paquete:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error: any) {
        console.error('Error en obtenerTutorialesPaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Agregar tutorial a paquete
 */
export async function agregarTutorialAPaquete(item: PaqueteItem): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .from('paquetes_tutoriales_items')
            .insert([item])
            .select('*')
            .single();

        if (error) {
            console.error('Error agregando tutorial a paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            data, 
            message: 'Tutorial agregado al paquete exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en agregarTutorialAPaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Remover tutorial de paquete
 */
export async function removerTutorialDePaquete(paqueteId: string, tutorialId: string): Promise<ResultadoOperacion> {
    try {
        const { error } = await supabaseAdmin
            .from('paquetes_tutoriales_items')
            .delete()
            .eq('paquete_id', paqueteId)
            .eq('tutorial_id', tutorialId);

        if (error) {
            console.error('Error removiendo tutorial del paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            message: 'Tutorial removido del paquete exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en removerTutorialDePaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Actualizar orden de tutoriales en paquete
 */
export async function actualizarOrdenTutoriales(items: { id: string; orden: number }[]): Promise<ResultadoOperacion> {
    try {
        const updates = items.map(item => 
            supabaseAdmin
                .from('paquetes_tutoriales_items')
                .update({ orden: item.orden })
                .eq('id', item.id)
        );

        const results = await Promise.all(updates);
        
        const errores = results.filter(result => result.error);
        if (errores.length > 0) {
            console.error('Errores actualizando orden:', errores);
            return { success: false, error: 'Error actualizando orden de tutoriales' };
        }

        return { 
            success: true, 
            message: 'Orden actualizado exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en actualizarOrdenTutoriales:', error);
        return { success: false, error: error.message };
    }
}

// ===========================================
// FUNCIONES DE PROGRESO
// ===========================================

/**
 * Obtener progreso de usuario en paquetes
 */
export async function obtenerProgresoUsuarioPaquetes(usuarioId: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .from('vista_progreso_usuario_paquetes')
            .select('*')
            .eq('usuario_id', usuarioId)
            .order('ultima_actividad', { ascending: false });

        if (error) {
            console.error('Error obteniendo progreso de paquetes:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error: any) {
        console.error('Error en obtenerProgresoUsuarioPaquetes:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Inscribir usuario en paquete
 */
export async function inscribirUsuarioEnPaquete(usuarioId: string, paqueteId: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabaseAdmin
            .rpc('inscribir_usuario_paquete', {
                p_usuario_id: usuarioId,
                p_paquete_id: paqueteId
            });

        if (error) {
            console.error('Error inscribiendo usuario en paquete:', error);
            return { success: false, error: error.message };
        }

        return { 
            success: true, 
            data: data, 
            message: 'Usuario inscrito en paquete exitosamente' 
        };
    } catch (error: any) {
        console.error('Error en inscribirUsuarioEnPaquete:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Calcular descuento de paquete
 */
export async function calcularDescuentoPaquete(paqueteId: string): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .rpc('calcular_descuento_paquete', {
                p_paquete_id: paqueteId
            });

        if (error) {
            console.error('Error calculando descuento:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data?.[0] || null };
    } catch (error: any) {
        console.error('Error en calcularDescuentoPaquete:', error);
        return { success: false, error: error.message };
    }
}

// ===========================================
// FUNCIONES DE BÚSQUEDA Y FILTROS
// ===========================================

/**
 * Buscar paquetes
 */
export async function buscarPaquetes(
    termino: string, 
    filtros?: { 
        categoria?: string; 
        nivel?: string; 
        precio_min?: number; 
        precio_max?: number; 
    }
): Promise<ResultadoOperacion> {
    try {
        let query = supabase
            .from('vista_paquetes_completos')
            .select('*')
            .eq('estado', 'publicado')
            .eq('visible', true);

        // Búsqueda por texto
        if (termino) {
            query = query.or(`titulo.ilike.%${termino}%,descripcion.ilike.%${termino}%,categoria.ilike.%${termino}%`);
        }

        // Aplicar filtros
        if (filtros?.categoria) {
            query = query.eq('categoria', filtros.categoria);
        }
        if (filtros?.nivel) {
            query = query.eq('nivel', filtros.nivel);
        }
        if (filtros?.precio_min) {
            query = query.gte('precio_normal', filtros.precio_min);
        }
        if (filtros?.precio_max) {
            query = query.lte('precio_normal', filtros.precio_max);
        }

        const { data, error } = await query
            .order('destacado', { ascending: false })
            .order('created_at', { ascending: false });

        if (error) {
            console.error('Error buscando paquetes:', error);
            return { success: false, error: error.message };
        }

        return { success: true, data: data || [] };
    } catch (error: any) {
        console.error('Error en buscarPaquetes:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Obtener categorías de paquetes
 */
export async function obtenerCategoriasPaquetes(): Promise<ResultadoOperacion> {
    try {
        const { data, error } = await supabase
            .from('paquetes_tutoriales')
            .select('categoria')
            .eq('estado', 'publicado')
            .not('categoria', 'is', null);

        if (error) {
            console.error('Error obteniendo categorías:', error);
            return { success: false, error: error.message };
        }

                 const categorias = [...new Set(data?.map((item: any) => item.categoria).filter(Boolean))];
        return { success: true, data: categorias };
    } catch (error: any) {
        console.error('Error en obtenerCategoriasPaquetes:', error);
        return { success: false, error: error.message };
    }
}

// ===========================================
// UTILIDADES
// ===========================================

/**
 * Validar datos de paquete
 */
export function validarPaquete(paquete: Partial<PaqueteTutorial>): { valido: boolean; errores: string[] } {
    const errores: string[] = [];

    if (!paquete.titulo?.trim()) {
        errores.push('El título es requerido');
    }

    if (!paquete.precio_normal || paquete.precio_normal <= 0) {
        errores.push('El precio normal debe ser mayor a 0');
    }

    if (paquete.precio_rebajado && paquete.precio_rebajado >= paquete.precio_normal!) {
        errores.push('El precio rebajado debe ser menor al precio normal');
    }

    if (!paquete.nivel) {
        errores.push('El nivel es requerido');
    }

    if (!paquete.tipo_acceso) {
        errores.push('El tipo de acceso es requerido');
    }

    return {
        valido: errores.length === 0,
        errores
    };
}

/**
 * Formatear precio
 */
export function formatearPrecio(precio: number): string {
    return new Intl.NumberFormat('es-CO', {
        style: 'currency',
        currency: 'COP',
        minimumFractionDigits: 0
    }).format(precio);
}

/**
 * Calcular porcentaje de descuento
 */
export function calcularPorcentajeDescuento(precioNormal: number, precioRebajado: number): number {
    if (precioNormal <= 0 || precioRebajado >= precioNormal) return 0;
    return Math.round(((precioNormal - precioRebajado) / precioNormal) * 100);
} 