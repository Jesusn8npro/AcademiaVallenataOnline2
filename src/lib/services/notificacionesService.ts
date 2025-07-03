import { supabase } from '$lib/supabase/clienteSupabase';
import type { RealtimeChannel } from '@supabase/supabase-js';

// Tipos de notificaciones
export interface Notificacion {
	id: string;
	usuario_id: string;
	tipo: string;
	titulo: string;
	mensaje: string;
	icono: string;
	categoria: 'contenido' | 'pago' | 'comunidad' | 'progreso' | 'sistema' | 'promocion';
	prioridad: 'alta' | 'normal' | 'baja';
	leida: boolean;
	archivada: boolean;
	url_accion?: string;
	entidad_id?: string;
	entidad_tipo?: string;
	datos_adicionales: any;
	fecha_creacion: string;
	fecha_lectura?: string;
	fecha_expiracion?: string;
	tiempo_transcurrido?: string;
}

export interface PreferenciaNotificacion {
	id: string;
	usuario_id: string;
	tipo_notificacion: string;
	habilitado: boolean;
	via_plataforma: boolean;
	via_email: boolean;
	via_push: boolean;
	frecuencia: 'inmediata' | 'diaria' | 'semanal' | 'nunca';
}

export interface EstadisticasNotificaciones {
	total: number;
	no_leidas: number;
	por_categoria: { [key: string]: number };
	por_prioridad: { [key: string]: number };
}

class NotificacionesService {
	private channel: RealtimeChannel | null = null;
	private callbacks: ((notificacion: Notificacion) => void)[] = [];

	/**
	 * 🔔 Obtener todas las notificaciones del usuario actual
	 */
	async obtenerNotificaciones(filtros?: {
		categoria?: string;
		leida?: boolean;
		limite?: number;
		offset?: number;
	}): Promise<{ notificaciones: Notificacion[]; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { notificaciones: [], error: 'Usuario no autenticado' };
			}

			let query = supabase
				.from('vista_notificaciones')
				.select('*')
				.eq('usuario_id', user.id)
				.order('fecha_creacion', { ascending: false });

			// Aplicar filtros
			if (filtros?.categoria) {
				query = query.eq('categoria', filtros.categoria);
			}
			if (filtros?.leida !== undefined) {
				query = query.eq('leida', filtros.leida);
			}
			if (filtros?.limite) {
				query = query.limit(filtros.limite);
			}
			if (filtros?.offset) {
				query = query.range(filtros.offset, filtros.offset + (filtros.limite || 20) - 1);
			}

			const { data, error } = await query;

			if (error) {
				console.error('Error al obtener notificaciones:', error);
				return { notificaciones: [], error: error.message };
			}

			return { notificaciones: data || [], error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { notificaciones: [], error: 'Error inesperado al obtener notificaciones' };
		}
	}

	/**
	 * 📊 Obtener estadísticas de notificaciones
	 */
	async obtenerEstadisticas(): Promise<{ estadisticas: EstadisticasNotificaciones | null; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { estadisticas: null, error: 'Usuario no autenticado' };
			}

			const { data, error } = await supabase
				.from('notificaciones')
				.select('categoria, prioridad, leida')
				.eq('usuario_id', user.id);

			if (error) {
				return { estadisticas: null, error: error.message };
			}

			const estadisticas: EstadisticasNotificaciones = {
				total: data.length,
				no_leidas: data.filter((n: any) => !n.leida).length,
				por_categoria: {},
				por_prioridad: {}
			};

			// Agrupar por categoría
			data.forEach((notif: any) => {
				estadisticas.por_categoria[notif.categoria] = 
					(estadisticas.por_categoria[notif.categoria] || 0) + 1;
				estadisticas.por_prioridad[notif.prioridad] = 
					(estadisticas.por_prioridad[notif.prioridad] || 0) + 1;
			});

			return { estadisticas, error: null };
		} catch (err) {
			console.error('Error al obtener estadísticas:', err);
			return { estadisticas: null, error: 'Error inesperado' };
		}
	}

	/**
	 * 🔢 Obtener contador de notificaciones no leídas
	 */
	async obtenerContadorNoLeidas(): Promise<number> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) return 0;

			const { count, error } = await supabase
				.from('notificaciones')
				.select('*', { count: 'exact', head: true })
				.eq('usuario_id', user.id)
				.eq('leida', false)
				.eq('archivada', false);

			if (error) {
				console.error('Error en contador de notificaciones:', error);
				return 0;
			}
			
			console.log('📊 Contador de notificaciones no leídas:', count);
			return count || 0;
		} catch (error) {
			console.error('Error al obtener contador de notificaciones:', error);
			return 0;
		}
	}

	/**
	 * ✅ Marcar notificación(es) como leída(s)
	 */
	async marcarComoLeida(notificacionIds: string[]): Promise<{ exito: boolean; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { exito: false, error: 'Usuario no autenticado' };
			}

			const { error } = await supabase.rpc('marcar_notificaciones_leidas', {
				p_usuario_id: user.id,
				p_notificacion_ids: notificacionIds
			});

			if (error) {
				console.error('Error al marcar como leída:', error);
				return { exito: false, error: error.message };
			}

			return { exito: true, error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { exito: false, error: 'Error inesperado' };
		}
	}

	/**
	 * ✅ Marcar TODAS las notificaciones como leídas
	 */
	async marcarTodasComoLeidas(): Promise<{ exito: boolean; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { exito: false, error: 'Usuario no autenticado' };
			}

			const { error } = await supabase.rpc('marcar_notificaciones_leidas', {
				p_usuario_id: user.id,
				p_notificacion_ids: null
			});

			if (error) {
				console.error('Error al marcar todas como leídas:', error);
				return { exito: false, error: error.message };
			}

			return { exito: true, error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { exito: false, error: 'Error inesperado' };
		}
	}

	/**
	 * 🗑️ Archivar notificación
	 */
	async archivarNotificacion(notificacionId: string): Promise<{ exito: boolean; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { exito: false, error: 'Usuario no autenticado' };
			}

			const { error } = await supabase
				.from('notificaciones')
				.update({ archivada: true })
				.eq('id', notificacionId)
				.eq('usuario_id', user.id);

			if (error) {
				console.error('Error al archivar notificación:', error);
				return { exito: false, error: error.message };
			}

			return { exito: true, error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { exito: false, error: 'Error inesperado' };
		}
	}

	/**
	 * 🔔 Crear notificación manual (para admins)
	 */
	async crearNotificacion(datos: {
		tipo: string;
		titulo: string;
		mensaje: string;
		categoria?: string;
		prioridad?: string;
		url_accion?: string;
		icono?: string;
	}): Promise<{ exito: boolean; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { exito: false, error: 'Usuario no autenticado' };
			}

			const { error } = await supabase.rpc('crear_notificacion', {
				p_usuario_id: user.id,
				p_tipo: datos.tipo,
				p_titulo: datos.titulo,
				p_mensaje: datos.mensaje,
				p_categoria: datos.categoria || 'sistema',
				p_prioridad: datos.prioridad || 'normal',
				p_url_accion: datos.url_accion,
				p_icono: datos.icono || '🔔'
			});

			if (error) {
				console.error('Error al crear notificación:', error);
				return { exito: false, error: error.message };
			}

			return { exito: true, error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { exito: false, error: 'Error inesperado' };
		}
	}

	/**
	 * ⚙️ Obtener preferencias de notificaciones
	 */
	async obtenerPreferencias(): Promise<{ preferencias: PreferenciaNotificacion[]; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { preferencias: [], error: 'Usuario no autenticado' };
			}

			const { data, error } = await supabase
				.from('notificaciones_preferencias')
				.select('*')
				.eq('usuario_id', user.id);

			if (error) {
				console.error('Error al obtener preferencias:', error);
				return { preferencias: [], error: error.message };
			}

			return { preferencias: data || [], error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { preferencias: [], error: 'Error inesperado' };
		}
	}

	/**
	 * ⚙️ Actualizar preferencias de notificaciones
	 */
	async actualizarPreferencias(preferencias: Partial<PreferenciaNotificacion>[]): Promise<{ exito: boolean; error: string | null }> {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			if (!user) {
				return { exito: false, error: 'Usuario no autenticado' };
			}

			// Actualizar cada preferencia
			for (const pref of preferencias) {
				const { error } = await supabase
					.from('notificaciones_preferencias')
					.upsert({
						...pref,
						usuario_id: user.id,
						updated_at: new Date().toISOString()
					});

				if (error) {
					console.error('Error al actualizar preferencia:', error);
					return { exito: false, error: error.message };
				}
			}

			return { exito: true, error: null };
		} catch (err) {
			console.error('Error inesperado:', err);
			return { exito: false, error: 'Error inesperado' };
		}
	}

	/**
	 * 🎧 Suscribirse a notificaciones en tiempo real
	 */
	suscribirseANotificaciones(callback: (notificacion: Notificacion) => void): void {
		if (this.channel) {
			this.channel.unsubscribe();
		}

		this.callbacks.push(callback);

		// Crear canal de Supabase Realtime
		this.channel = supabase
			.channel('notificaciones-cambios')
			.on(
				'postgres_changes',
				{
					event: 'INSERT',
					schema: 'public',
					table: 'notificaciones'
				},
				(payload: any) => {
					console.log('📨 Nueva notificación en tiempo real:', payload.new);
					this.callbacks.forEach(cb => cb(payload.new as Notificacion));
				}
			)
			.subscribe();

		console.log('🎧 Suscrito a notificaciones en tiempo real');
	}

	/**
	 * 🔇 Desuscribirse de notificaciones en tiempo real
	 */
	desuscribirseDeNotificaciones(): void {
		if (this.channel) {
			this.channel.unsubscribe();
			this.channel = null;
		}
		this.callbacks = [];
		console.log('🔇 Desuscrito de notificaciones en tiempo real');
	}

	/**
	 * 🎨 Obtener ícono por tipo de notificación
	 */
	obtenerIconoPorTipo(tipo: string): string {
		const iconos: { [key: string]: string } = {
			'curso_nuevo': '🎓',
			'tutorial_nuevo': '🎬',
			'pago_aprobado': '✅',
			'pago_rechazado': '❌',
			'comentario_nuevo': '💬',
			'me_gusta_nuevo': '❤️',
			'articulo_nuevo': '📰',
			'progreso_completado': '🏆',
			'evento_nuevo': '📅',
			'actualizacion_sistema': '🔔',
			'publicacion_nueva': '📝',
			'sistema': '⚙️'
		};

		return iconos[tipo] || '🔔';
	}

	/**
	 * 🎨 Obtener color por categoría
	 */
	obtenerColorPorCategoria(categoria: string): string {
		const colores: { [key: string]: string } = {
			'contenido': '#3b82f6',
			'pago': '#10b981',
			'comunidad': '#8b5cf6',
			'progreso': '#f59e0b',
			'sistema': '#6b7280',
			'promocion': '#ef4444'
		};

		return colores[categoria] || '#6b7280';
	}

	/**
	 * ⏰ Formatear tiempo transcurrido
	 */
	formatearTiempoTranscurrido(fecha: string): string {
		const ahora = new Date();
		const fechaNotificacion = new Date(fecha);
		const diferencia = ahora.getTime() - fechaNotificacion.getTime();

		const minutos = Math.floor(diferencia / 60000);
		const horas = Math.floor(diferencia / 3600000);
		const dias = Math.floor(diferencia / 86400000);

		if (minutos < 1) return 'Hace unos momentos';
		if (minutos < 60) return `Hace ${minutos} minuto${minutos > 1 ? 's' : ''}`;
		if (horas < 24) return `Hace ${horas} hora${horas > 1 ? 's' : ''}`;
		if (dias < 7) return `Hace ${dias} día${dias > 1 ? 's' : ''}`;
		
		return fechaNotificacion.toLocaleDateString('es-ES', {
			day: '2-digit',
			month: '2-digit',
			year: 'numeric'
		});
	}
}

// Exportar instancia singleton
export const notificacionesService = new NotificacionesService();
export default notificacionesService; 