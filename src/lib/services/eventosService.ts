import { supabase } from '$lib/supabase/clienteSupabase';
import type { Database } from '$lib/types/database.types';

// Tipos de datos para eventos
export interface Evento {
  id: string;
  titulo: string;
  descripcion?: string;
  descripcion_corta?: string;
  slug: string;
  tipo_evento: 'masterclass' | 'workshop' | 'concierto' | 'concurso' | 'webinar' | 'reunion';
  fecha_inicio: string;
  fecha_fin?: string;
  es_todo_el_dia?: boolean;
  zona_horaria?: string;
  modalidad: 'online' | 'presencial' | 'hibrido';
  ubicacion_fisica?: string;
  link_transmision?: string;
  enlace_grabacion?: string;
  codigo_acceso?: string;
  instructor_id?: string;
  instructor_nombre?: string;
  instructor_avatar?: string;
  capacidad_maxima?: number;
  participantes_inscritos: number;
  precio: number;
  precio_rebajado?: number;
  moneda?: string;
  es_gratuito?: boolean;
  imagen_portada?: string;
  imagen_banner?: string;
  video_promocional?: string;
  categoria?: string;
  nivel_dificultad?: 'principiante' | 'intermedio' | 'avanzado' | 'profesional';
  tags?: string[];
  requiere_inscripcion?: boolean;
  acepta_invitados?: boolean;
  es_publico?: boolean;
  es_destacado?: boolean;
  permite_grabacion?: boolean;
  estado: 'borrador' | 'programado' | 'en_vivo' | 'finalizado' | 'cancelado' | 'pospuesto';
  created_at: string;
  updated_at: string;
  creado_por?: string;
  fecha_publicacion?: string;
  total_visualizaciones: number;
  calificacion_promedio: number;
  total_calificaciones: number;
}

export interface EventoInscripcion {
  id: string;
  evento_id: string;
  usuario_id: string;
  fecha_inscripcion: string;
  estado_inscripcion: 'pendiente' | 'confirmado' | 'cancelado' | 'asistio' | 'no_asistio';
  pago_id?: string;
  monto_pagado?: number;
  fecha_pago?: string;
  fecha_ultima_conexion?: string;
  tiempo_total_conectado: number;
  calificacion?: number;
  comentario_calificacion?: string;
  fecha_calificacion?: string;
  notas_usuario?: string;
  notificaciones_habilitadas?: boolean;
  created_at: string;
  updated_at: string;
}

export interface EventoComentario {
  id: string;
  evento_id: string;
  usuario_id: string;
  mensaje: string;
  tipo_mensaje: 'comentario' | 'pregunta' | 'respuesta';
  mensaje_padre_id?: string;
  es_destacado?: boolean;
  es_aprobado?: boolean;
  moderado_por?: string;
  minuto_stream?: number;
  created_at: string;
  updated_at: string;
  // Datos del usuario (join)
  usuario?: {
    nombre?: string;
    apellido?: string;
    url_foto_perfil?: string;
  };
}

export interface EventoMaterial {
  id: string;
  evento_id: string;
  titulo: string;
  descripcion?: string;
  tipo_material: 'pdf' | 'video' | 'audio' | 'imagen' | 'enlace' | 'partitura';
  url_archivo?: string;
  nombre_archivo?: string;
  tamano_archivo?: number;
  es_publico?: boolean;
  requiere_inscripcion?: boolean;
  disponible_antes_evento?: boolean;
  disponible_despues_evento?: boolean;
  orden_visualizacion: number;
  created_at: string;
  subido_por?: string;
}

class EventosService {
  // ========== GESTIÓN DE EVENTOS ==========

  /**
   * Obtener todos los eventos públicos con paginación
   */
  async obtenerEventos(filtros: {
    categoria?: string;
    tipo_evento?: string;
    nivel_dificultad?: string;
    estado?: string;
    es_gratuito?: boolean;
    fecha_desde?: string;
    fecha_hasta?: string;
    busqueda?: string;
    limit?: number;
    offset?: number;
  } = {}): Promise<{ eventos: Evento[]; total: number; error: string | null }> {
    try {
      let query = supabase
        .from('eventos')
        .select('*', { count: 'exact' })
        .eq('es_publico', true)
        .order('fecha_inicio', { ascending: true });

      // Aplicar filtros
      if (filtros.categoria) {
        query = query.eq('categoria', filtros.categoria);
      }
      if (filtros.tipo_evento) {
        query = query.eq('tipo_evento', filtros.tipo_evento);
      }
      if (filtros.nivel_dificultad) {
        query = query.eq('nivel_dificultad', filtros.nivel_dificultad);
      }
      if (filtros.estado) {
        query = query.eq('estado', filtros.estado);
      }
      if (filtros.es_gratuito !== undefined) {
        query = query.eq('es_gratuito', filtros.es_gratuito);
      }
      if (filtros.fecha_desde) {
        query = query.gte('fecha_inicio', filtros.fecha_desde);
      }
      if (filtros.fecha_hasta) {
        query = query.lte('fecha_inicio', filtros.fecha_hasta);
      }
      if (filtros.busqueda) {
        query = query.or(`titulo.ilike.%${filtros.busqueda}%,descripcion.ilike.%${filtros.busqueda}%`);
      }

      // Paginación
      if (filtros.limit) {
        query = query.limit(filtros.limit);
      }
      if (filtros.offset) {
        query = query.range(filtros.offset, filtros.offset + (filtros.limit || 10) - 1);
      }

      const { data, error, count } = await query;

      if (error) {
        console.error('Error obteniendo eventos:', error);
        return { eventos: [], total: 0, error: error.message };
      }

      return { eventos: data || [], total: count || 0, error: null };
    } catch (error: any) {
      console.error('Error en obtenerEventos:', error);
      return { eventos: [], total: 0, error: error.message };
    }
  }

  /**
   * Obtener eventos próximos (los más cercanos)
   */
  async obtenerEventosProximos(limite: number = 5): Promise<{ eventos: Evento[]; error: string | null }> {
    try {
      const { data, error } = await supabase
        .rpc('obtener_eventos_proximos', { limite });

      if (error) {
        console.error('Error obteniendo eventos próximos:', error);
        return { eventos: [], error: error.message };
      }

      return { eventos: data || [], error: null };
    } catch (error: any) {
      console.error('Error en obtenerEventosProximos:', error);
      return { eventos: [], error: error.message };
    }
  }

  /**
   * Obtener evento por slug
   */
  async obtenerEventoPorSlug(slug: string): Promise<{ evento: Evento | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos')
        .select('*')
        .eq('slug', slug)
        .eq('es_publico', true)
        .single();

      if (error) {
        console.error('Error obteniendo evento por slug:', error);
        return { evento: null, error: error.message };
      }

      return { evento: data, error: null };
    } catch (error: any) {
      console.error('Error en obtenerEventoPorSlug:', error);
      return { evento: null, error: error.message };
    }
  }

  /**
   * Crear un nuevo evento (solo admin/instructor)
   */
  async crearEvento(eventoData: Partial<Evento>): Promise<{ evento: Evento | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos')
        .insert([eventoData])
        .select('*')
        .single();

      if (error) {
        console.error('Error creando evento:', error);
        return { evento: null, error: error.message };
      }

      return { evento: data, error: null };
    } catch (error: any) {
      console.error('Error en crearEvento:', error);
      return { evento: null, error: error.message };
    }
  }

  /**
   * Actualizar evento
   */
  async actualizarEvento(id: string, eventoData: Partial<Evento>): Promise<{ evento: Evento | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos')
        .update(eventoData)
        .eq('id', id)
        .select('*')
        .single();

      if (error) {
        console.error('Error actualizando evento:', error);
        return { evento: null, error: error.message };
      }

      return { evento: data, error: null };
    } catch (error: any) {
      console.error('Error en actualizarEvento:', error);
      return { evento: null, error: error.message };
    }
  }

  /**
   * Eliminar evento
   */
  async eliminarEvento(id: string): Promise<{ success: boolean; error: string | null }> {
    try {
      const { error } = await supabase
        .from('eventos')
        .delete()
        .eq('id', id);

      if (error) {
        console.error('Error eliminando evento:', error);
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    } catch (error: any) {
      console.error('Error en eliminarEvento:', error);
      return { success: false, error: error.message };
    }
  }

  // ========== GESTIÓN DE INSCRIPCIONES ==========

  /**
   * Inscribirse a un evento
   */
  async inscribirseEvento(eventoId: string, usuarioId: string): Promise<{ inscripcion: EventoInscripcion | null; error: string | null }> {
    try {
      // Primero verificar disponibilidad
      const { data: disponibilidad, error: errorDisponibilidad } = await supabase
        .rpc('verificar_disponibilidad_evento', { 
          evento_uuid: eventoId, 
          usuario_uuid: usuarioId 
        });

      if (errorDisponibilidad) {
        return { inscripcion: null, error: errorDisponibilidad.message };
      }

      if (!disponibilidad.puede_inscribirse) {
        return { inscripcion: null, error: disponibilidad.mensaje };
      }

      // Proceder con la inscripción
      const { data, error } = await supabase
        .from('eventos_inscripciones')
        .insert([{
          evento_id: eventoId,
          usuario_id: usuarioId,
          estado_inscripcion: 'confirmado'
        }])
        .select('*')
        .single();

      if (error) {
        console.error('Error en inscripción:', error);
        return { inscripcion: null, error: error.message };
      }

      return { inscripcion: data, error: null };
    } catch (error: any) {
      console.error('Error en inscribirseEvento:', error);
      return { inscripcion: null, error: error.message };
    }
  }

  /**
   * Cancelar inscripción
   */
  async cancelarInscripcion(eventoId: string, usuarioId: string): Promise<{ success: boolean; error: string | null }> {
    try {
      const { error } = await supabase
        .from('eventos_inscripciones')
        .update({ estado_inscripcion: 'cancelado' })
        .eq('evento_id', eventoId)
        .eq('usuario_id', usuarioId);

      if (error) {
        console.error('Error cancelando inscripción:', error);
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    } catch (error: any) {
      console.error('Error en cancelarInscripcion:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Obtener inscripciones del usuario
   */
  async obtenerInscripcionesUsuario(usuarioId: string): Promise<{ inscripciones: (EventoInscripcion & { evento: Evento })[]; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_inscripciones')
        .select(`
          *,
          evento:eventos(*)
        `)
        .eq('usuario_id', usuarioId)
        .order('fecha_inscripcion', { ascending: false });

      if (error) {
        console.error('Error obteniendo inscripciones del usuario:', error);
        return { inscripciones: [], error: error.message };
      }

      return { inscripciones: data || [], error: null };
    } catch (error: any) {
      console.error('Error en obtenerInscripcionesUsuario:', error);
      return { inscripciones: [], error: error.message };
    }
  }

  /**
   * Verificar si el usuario está inscrito en un evento
   */
  async verificarInscripcion(eventoId: string, usuarioId: string): Promise<{ inscrito: boolean; inscripcion: EventoInscripcion | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_inscripciones')
        .select('*')
        .eq('evento_id', eventoId)
        .eq('usuario_id', usuarioId)
        .eq('estado_inscripcion', 'confirmado')
        .single();

      if (error && error.code !== 'PGRST116') {
        console.error('Error verificando inscripción:', error);
        return { inscrito: false, inscripcion: null, error: error.message };
      }

      return { inscrito: !!data, inscripcion: data || null, error: null };
    } catch (error: any) {
      console.error('Error en verificarInscripcion:', error);
      return { inscrito: false, inscripcion: null, error: error.message };
    }
  }

  /**
   * Calificar un evento
   */
  async calificarEvento(eventoId: string, usuarioId: string, calificacion: number, comentario?: string): Promise<{ success: boolean; error: string | null }> {
    try {
      const { error } = await supabase
        .from('eventos_inscripciones')
        .update({
          calificacion,
          comentario_calificacion: comentario,
          fecha_calificacion: new Date().toISOString()
        })
        .eq('evento_id', eventoId)
        .eq('usuario_id', usuarioId);

      if (error) {
        console.error('Error calificando evento:', error);
        return { success: false, error: error.message };
      }

      return { success: true, error: null };
    } catch (error: any) {
      console.error('Error en calificarEvento:', error);
      return { success: false, error: error.message };
    }
  }

  // ========== GESTIÓN DE COMENTARIOS ==========

  /**
   * Obtener comentarios de un evento
   */
  async obtenerComentariosEvento(eventoId: string): Promise<{ comentarios: EventoComentario[]; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_comentarios')
        .select(`
          *,
          usuario:perfiles!eventos_comentarios_usuario_id_fkey(nombre, apellido, url_foto_perfil)
        `)
        .eq('evento_id', eventoId)
        .order('created_at', { ascending: true });

      if (error) {
        console.error('Error obteniendo comentarios:', error);
        return { comentarios: [], error: error.message };
      }

      return { comentarios: data || [], error: null };
    } catch (error: any) {
      console.error('Error en obtenerComentariosEvento:', error);
      return { comentarios: [], error: error.message };
    }
  }

  /**
   * Agregar comentario a un evento
   */
  async agregarComentario(
    eventoId: string, 
    usuarioId: string, 
    mensaje: string, 
    tipoMensaje: 'comentario' | 'pregunta' = 'comentario',
    mensajePadreId?: string
  ): Promise<{ comentario: EventoComentario | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_comentarios')
        .insert([{
          evento_id: eventoId,
          usuario_id: usuarioId,
          mensaje,
          tipo_mensaje: tipoMensaje,
          mensaje_padre_id: mensajePadreId
        }])
        .select(`
          *,
          usuario:perfiles!eventos_comentarios_usuario_id_fkey(nombre, apellido, url_foto_perfil)
        `)
        .single();

      if (error) {
        console.error('Error agregando comentario:', error);
        return { comentario: null, error: error.message };
      }

      return { comentario: data, error: null };
    } catch (error: any) {
      console.error('Error en agregarComentario:', error);
      return { comentario: null, error: error.message };
    }
  }

  // ========== GESTIÓN DE MATERIALES ==========

  /**
   * Obtener materiales de un evento
   */
  async obtenerMaterialesEvento(eventoId: string): Promise<{ materiales: EventoMaterial[]; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_materiales')
        .select('*')
        .eq('evento_id', eventoId)
        .order('orden_visualizacion', { ascending: true });

      if (error) {
        console.error('Error obteniendo materiales:', error);
        return { materiales: [], error: error.message };
      }

      return { materiales: data || [], error: null };
    } catch (error: any) {
      console.error('Error en obtenerMaterialesEvento:', error);
      return { materiales: [], error: error.message };
    }
  }

  /**
   * Subir material a un evento
   */
  async subirMaterial(materialData: Partial<EventoMaterial>): Promise<{ material: EventoMaterial | null; error: string | null }> {
    try {
      const { data, error } = await supabase
        .from('eventos_materiales')
        .insert([materialData])
        .select('*')
        .single();

      if (error) {
        console.error('Error subiendo material:', error);
        return { material: null, error: error.message };
      }

      return { material: data, error: null };
    } catch (error: any) {
      console.error('Error en subirMaterial:', error);
      return { material: null, error: error.message };
    }
  }

  // ========== UTILIDADES ==========

  /**
   * Verificar disponibilidad de evento
   */
  async verificarDisponibilidad(eventoId: string, usuarioId: string): Promise<{ disponibilidad: any; error: string | null }> {
    try {
      const { data, error } = await supabase
        .rpc('verificar_disponibilidad_evento', { 
          evento_uuid: eventoId, 
          usuario_uuid: usuarioId 
        });

      if (error) {
        console.error('Error verificando disponibilidad:', error);
        return { disponibilidad: null, error: error.message };
      }

      return { disponibilidad: data, error: null };
    } catch (error: any) {
      console.error('Error en verificarDisponibilidad:', error);
      return { disponibilidad: null, error: error.message };
    }
  }

  /**
   * Obtener estadísticas de evento
   */
  async obtenerEstadisticasEvento(eventoId: string): Promise<{ 
    estadisticas: { 
      total_inscritos: number; 
      total_asistentes: number; 
      calificacion_promedio: number; 
      total_comentarios: number 
    } | null; 
    error: string | null 
  }> {
    try {
      const [
        { count: totalInscritos },
        { count: totalAsistentes },
        { data: evento },
        { count: totalComentarios }
      ] = await Promise.all([
        supabase
          .from('eventos_inscripciones')
          .select('*', { count: 'exact', head: true })
          .eq('evento_id', eventoId)
          .eq('estado_inscripcion', 'confirmado'),
        supabase
          .from('eventos_inscripciones')
          .select('*', { count: 'exact', head: true })
          .eq('evento_id', eventoId)
          .eq('estado_inscripcion', 'asistio'),
        supabase
          .from('eventos')
          .select('calificacion_promedio')
          .eq('id', eventoId)
          .single(),
        supabase
          .from('eventos_comentarios')
          .select('*', { count: 'exact', head: true })
          .eq('evento_id', eventoId)
          .eq('es_aprobado', true)
      ]);

      return {
        estadisticas: {
          total_inscritos: totalInscritos || 0,
          total_asistentes: totalAsistentes || 0,
          calificacion_promedio: evento?.calificacion_promedio || 0,
          total_comentarios: totalComentarios || 0
        },
        error: null
      };
    } catch (error: any) {
      console.error('Error obteniendo estadísticas:', error);
      return { estadisticas: null, error: error.message };
    }
  }
}

// Exportar instancia singleton
export const eventosService = new EventosService(); 