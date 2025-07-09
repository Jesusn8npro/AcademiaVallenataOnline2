<!--
🔔 ACADEMIA VALLENATA ONLINE - GESTOR NOTIFICACIONES GAMING
=====================================================
Sistema completo de gestión de notificaciones gaming
Manejo de cola, posicionamiento y efectos visuales
Integración con el servicio de gamificación
=====================================================
-->

<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { writable } from 'svelte/store';
	import { flip } from 'svelte/animate';
	import { fly } from 'svelte/transition';
	import NotificacionGaming from './NotificacionGaming.svelte';
	import type { NotificacionGaming as TipoNotificacion } from '../../services/gamificacionService';
	import GamificacionService from '../../services/gamificacionService';
	import { estadoUsuarioActual } from '../../supabase/estadoUsuarioActual';

	// =====================================================
	// 🎯 PROPIEDADES
	// =====================================================
	export let position: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' = 'top-right';
	export let maxNotificaciones: number = 5;
	export let autoCloseDelay: number = 5000;
	export let espaciadoEntreNotificaciones: number = 16;
	export let permitirSonidos: boolean = true;
	export let mostrarContador: boolean = false;
	
	// =====================================================
	// 🎮 ESTADO LOCAL
	// =====================================================
	let notificaciones = writable<TipoNotificacion[]>([]);
	let colaNotificaciones: TipoNotificacion[] = [];
	let intervaloPoll: NodeJS.Timeout | null = null;
	let audioLogro: HTMLAudioElement | null = null;
	let audioNivel: HTMLAudioElement | null = null;
	let audioGeneral: HTMLAudioElement | null = null;
	
	// =====================================================
	// 🎨 ESTILOS DINÁMICOS
	// =====================================================
	$: posicionConfig = {
		'top-right': {
			container: 'fixed top-4 right-4 z-50 flex flex-col space-y-4',
			direction: 'flex-col'
		},
		'top-left': {
			container: 'fixed top-4 left-4 z-50 flex flex-col space-y-4',
			direction: 'flex-col'
		},
		'bottom-right': {
			container: 'fixed bottom-4 right-4 z-50 flex flex-col-reverse space-y-reverse space-y-4',
			direction: 'flex-col-reverse'
		},
		'bottom-left': {
			container: 'fixed bottom-4 left-4 z-50 flex flex-col-reverse space-y-reverse space-y-4',
			direction: 'flex-col-reverse'
		}
	};
	
	// =====================================================
	// 🚀 FUNCIONES PRINCIPALES
	// =====================================================
	
	/**
	 * 🎯 Cargar notificaciones del usuario
	 */
		async function cargarNotificaciones() {
		try {
			const usuario = $estadoUsuarioActual.user;
			if (!usuario || !usuario.id) return;
			
			const notificacionesDB = await GamificacionService.obtenerNotificacionesUsuario(
				usuario.id,
				20
			);
			
			// Filtrar solo no leídas recientes
			const noLeidas = notificacionesDB.filter(n => !n.leida);
			
			// Actualizar store
			notificaciones.set(noLeidas);
			
		} catch (error) {
			console.error('Error cargando notificaciones:', error);
		}
	}
	
	/**
	 * 🎯 Agregar nueva notificación
	 */
	function agregarNotificacion(nuevaNotificacion: TipoNotificacion) {
		notificaciones.update(notifs => {
			// Verificar si ya existe
			const existe = notifs.some(n => n.id === nuevaNotificacion.id);
			if (existe) return notifs;
			
			// Agregar al inicio
			const nuevasNotifs = [nuevaNotificacion, ...notifs];
			
			// Limitar cantidad máxima
			if (nuevasNotifs.length > maxNotificaciones) {
				nuevasNotifs.splice(maxNotificaciones);
			}
			
			// Reproducir sonido si está habilitado
			if (permitirSonidos) {
				reproducirSonido(nuevaNotificacion.tipo);
			}
			
			return nuevasNotifs;
		});
	}
	
	/**
	 * 🎯 Remover notificación
	 */
	function removerNotificacion(id: string) {
		notificaciones.update(notifs => 
			notifs.filter(n => n.id !== id)
		);
	}
	
	/**
	 * 🎯 Limpiar todas las notificaciones
	 */
	function limpiarTodas() {
		notificaciones.set([]);
	}
	
	/**
	 * 🎯 Marcar todas como leídas
	 */
	async function marcarTodasComoLeidas() {
		try {
			const notificacionesActuales = $notificaciones;
			
			// Marcar en base de datos (placeholder)
			for (const notif of notificacionesActuales) {
				if (!notif.leida) {
					console.log('Marcando como leída:', notif.id);
					// Aquí iría la lógica real de BD
				}
			}
			
			// Limpiar localmente
			limpiarTodas();
			
		} catch (error) {
			console.error('Error marcando como leídas:', error);
		}
	}
	
	/**
	 * 🎵 Reproducir sonido según tipo
	 */
	function reproducirSonido(tipo: string) {
		try {
			switch (tipo) {
				case 'logro_conseguido':
					audioLogro?.play();
					break;
				case 'subida_nivel':
					audioNivel?.play();
					break;
				default:
					audioGeneral?.play();
			}
		} catch (error) {
			console.log('Error reproduciendo sonido:', error);
		}
	}
	
	/**
	 * 🎯 Inicializar audios
	 */
	function inicializarAudios() {
		if (!permitirSonidos) return;
		
		// Crear elementos de audio
		audioLogro = new Audio('/sounds/logro.mp3');
		audioNivel = new Audio('/sounds/nivel.mp3');
		audioGeneral = new Audio('/sounds/notificacion.mp3');
		
		// Configurar volumen
		[audioLogro, audioNivel, audioGeneral].forEach(audio => {
			if (audio) {
				audio.volume = 0.3;
				audio.preload = 'auto';
			}
		});
	}
	
	/**
	 * 🎯 Obtener estadísticas de notificaciones
	 */
	function obtenerEstadisticas() {
		const notifs = $notificaciones;
		return {
			total: notifs.length,
			porTipo: {
				logros: notifs.filter(n => n.tipo === 'logro_conseguido').length,
				niveles: notifs.filter(n => n.tipo === 'subida_nivel').length,
				ranking: notifs.filter(n => n.tipo === 'nuevo_ranking').length,
				otros: notifs.filter(n => !['logro_conseguido', 'subida_nivel', 'nuevo_ranking'].includes(n.tipo)).length
			},
			porPrioridad: {
				critica: notifs.filter(n => n.prioridad === 'critica').length,
				alta: notifs.filter(n => n.prioridad === 'alta').length,
				normal: notifs.filter(n => n.prioridad === 'normal').length,
				baja: notifs.filter(n => n.prioridad === 'baja').length
			}
		};
	}
	
	/**
	 * 🎯 Polling para nuevas notificaciones
	 */
	function iniciarPolling() {
		intervaloPoll = setInterval(async () => {
			await cargarNotificaciones();
		}, 30000); // Cada 30 segundos
	}
	
	/**
	 * 🎯 Función pública para crear notificación desde fuera
	 */
	export function crearNotificacion(tipo: TipoNotificacion['tipo'], titulo: string, mensaje: string, datos: any = {}) {
		const nuevaNotificacion: TipoNotificacion = {
			id: `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
			usuario_id: $estadoUsuarioActual.user?.id || '',
			tipo,
			titulo,
			mensaje,
			icono: obtenerIconoPorTipo(tipo),
			datos_notificacion: datos,
			leida: false,
			mostrada: false,
			accion_realizada: false,
			prioridad: obtenerPrioridadPorTipo(tipo),
			estilo_visual: obtenerEstiloVisualPorTipo(tipo),
			fecha_expiracion: null,
			leida_en: null,
			mostrada_en: null,
			created_at: new Date().toISOString(),
			updated_at: new Date().toISOString()
		};
		
		agregarNotificacion(nuevaNotificacion);
		return nuevaNotificacion;
	}
	
	/**
	 * 🎯 Obtener icono por tipo
	 */
	function obtenerIconoPorTipo(tipo: string): string {
		const iconos: Record<string, string> = {
			logro_conseguido: '🏆',
			subida_nivel: '⭐',
			nuevo_ranking: '🏅',
			racha_perdida: '💔',
			desafio_completado: '✅',
			monedas_ganadas: '🪙',
			evento_especial: '🎉',
			meta_alcanzada: '🎯'
		};
		return iconos[tipo] || '🔔';
	}
	
	/**
	 * 🎯 Obtener prioridad por tipo
	 */
	function obtenerPrioridadPorTipo(tipo: string): 'baja' | 'normal' | 'alta' | 'critica' {
		const prioridades: Record<string, 'baja' | 'normal' | 'alta' | 'critica'> = {
			logro_conseguido: 'alta',
			subida_nivel: 'critica',
			nuevo_ranking: 'alta',
			racha_perdida: 'normal',
			desafio_completado: 'alta',
			monedas_ganadas: 'normal',
			evento_especial: 'critica',
			meta_alcanzada: 'alta'
		};
		return prioridades[tipo] || 'normal';
	}
	
	/**
	 * 🎯 Obtener estilo visual por tipo
	 */
	function obtenerEstiloVisualPorTipo(tipo: string): 'normal' | 'celebracion' | 'logro' | 'ranking' | 'especial' {
		const estilos: Record<string, 'normal' | 'celebracion' | 'logro' | 'ranking' | 'especial'> = {
			logro_conseguido: 'logro',
			subida_nivel: 'celebracion',
			nuevo_ranking: 'ranking',
			racha_perdida: 'normal',
			desafio_completado: 'logro',
			monedas_ganadas: 'normal',
			evento_especial: 'especial',
			meta_alcanzada: 'logro'
		};
		return estilos[tipo] || 'normal';
	}
	
	// =====================================================
	// 🎮 LIFECYCLE
	// =====================================================
	
	onMount(() => {
		// Inicializar
		inicializarAudios();
		cargarNotificaciones();
		iniciarPolling();
		
		// Escuchar cambios del usuario
		const unsubscribe = estadoUsuarioActual.subscribe((estado) => {
			if (estado.user?.id) {
				cargarNotificaciones();
			}
		});
		
		return unsubscribe;
	});
	
	onDestroy(() => {
		if (intervaloPoll) {
			clearInterval(intervaloPoll);
		}
	});
	
	// =====================================================
	// 🎯 STORES DERIVADOS
	// =====================================================
	$: estadisticas = obtenerEstadisticas();
	$: hayNotificaciones = $notificaciones.length > 0;
</script>

<!-- ===================================== -->
<!-- 🎮 TEMPLATE PRINCIPAL -->
<!-- ===================================== -->

<!-- Contenedor principal de notificaciones -->
<div class={posicionConfig[position].container}>
	{#each $notificaciones as notificacion (notificacion.id)}
		<div animate:flip={{ duration: 300 }}>
			<NotificacionGaming 
				{notificacion}
				autoClose={true}
				autoCloseDelay={autoCloseDelay}
				position={position}
				allowManualClose={true}
				showProgress={true}
				onClose={() => removerNotificacion(notificacion.id)}
				onClick={() => {
					// Marcar como mostrada
					console.log('Notificación clickeada:', notificacion.id);
				}}
			/>
		</div>
	{/each}
</div>

<!-- Contador de notificaciones (opcional) -->
{#if mostrarContador && hayNotificaciones}
	<div class="contador-notificaciones fixed {position.includes('right') ? 'right-2' : 'left-2'} {position.includes('top') ? 'top-2' : 'bottom-2'} z-40">
		<div class="bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold shadow-lg">
			{$notificaciones.length}
		</div>
	</div>
{/if}

<!-- Panel de control (solo en desarrollo) -->
{#if false}
	<div class="fixed bottom-4 left-4 z-50 bg-gray-800 text-white p-4 rounded-lg shadow-lg">
		<h3 class="text-sm font-bold mb-2">Control Notificaciones</h3>
		<div class="space-y-2 text-xs">
			<div>Total: {estadisticas.total}</div>
			<div>Logros: {estadisticas.porTipo.logros}</div>
			<div>Niveles: {estadisticas.porTipo.niveles}</div>
			<div>Ranking: {estadisticas.porTipo.ranking}</div>
		</div>
		<div class="mt-3 space-y-1">
			<button 
				class="w-full bg-blue-500 hover:bg-blue-600 text-white py-1 px-2 rounded text-xs"
				on:click={() => crearNotificacion('logro_conseguido', 'Logro Test', 'Logro de prueba')}
			>
				Test Logro
			</button>
			<button 
				class="w-full bg-purple-500 hover:bg-purple-600 text-white py-1 px-2 rounded text-xs"
				on:click={() => crearNotificacion('subida_nivel', 'Nivel Test', 'Subida de nivel')}
			>
				Test Nivel
			</button>
			<button 
				class="w-full bg-red-500 hover:bg-red-600 text-white py-1 px-2 rounded text-xs"
				on:click={limpiarTodas}
			>
				Limpiar
			</button>
		</div>
	</div>
{/if}

<!-- ===================================== -->
<!-- 🎨 ESTILOS GAMING -->
<!-- ===================================== -->

<style>
	.contador-notificaciones {
		animation: bounce 1s infinite;
	}
	
	@keyframes bounce {
		0%, 20%, 53%, 80%, 100% {
			transform: translate3d(0, 0, 0);
		}
		40%, 43% {
			transform: translate3d(0, -8px, 0);
		}
		70% {
			transform: translate3d(0, -4px, 0);
		}
		90% {
			transform: translate3d(0, -2px, 0);
		}
	}
	
	/* Efectos de transición para el contenedor */
	.notificacion-container {
		transition: all 0.3s ease;
	}
	
	/* Responsive */
	@media (max-width: 640px) {
		.contador-notificaciones {
			width: 24px;
			height: 24px;
			font-size: 10px;
		}
	}
</style> 