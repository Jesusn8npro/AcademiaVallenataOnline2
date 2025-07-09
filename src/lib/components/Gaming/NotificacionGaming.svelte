<!--
🔔 ACADEMIA VALLENATA ONLINE - NOTIFICACIÓN GAMING
=====================================================
Componente de notificación gaming con diseño premium
Diferentes tipos: logros, subida de nivel, ranking, etc.
Animaciones impresionantes y efectos visuales
=====================================================
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import { tweened } from 'svelte/motion';
	import { quintOut } from 'svelte/easing';
	import { fade, fly } from 'svelte/transition';
	import type { NotificacionGaming } from '../../services/gamificacionService';
	import GamificacionService from '../../services/gamificacionService';

	// =====================================================
	// 🎯 PROPIEDADES
	// =====================================================
	export let notificacion: NotificacionGaming;
	export let autoClose: boolean = true;
	export let autoCloseDelay: number = 5000;
	export let position: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' | 'center' = 'top-right';
	export let allowManualClose: boolean = true;
	export let showProgress: boolean = true;
	export let onClose: () => void = () => {};
	export let onClick: () => void = () => {};
	
	// =====================================================
	// 🎮 ESTADO LOCAL
	// =====================================================
	let visible: boolean = true;
	let timerProgress: number = 100;
	let intervalo: NodeJS.Timeout | null = null;
	
	// Animaciones
	const progreso = tweened(100, {
		duration: autoCloseDelay,
		easing: quintOut
	});
	
	const escala = tweened(1, {
		duration: 200,
		easing: quintOut
	});
	
	// =====================================================
	// 🎨 ESTILOS DINÁMICOS
	// =====================================================
	$: tiposNotificacion = {
		logro_conseguido: {
			fondo: 'from-yellow-500 to-orange-600',
			borde: 'border-yellow-400',
			texto: 'text-yellow-100',
			icono: '🏆',
			animacion: 'bounce'
		},
		subida_nivel: {
			fondo: 'from-purple-500 to-pink-600',
			borde: 'border-purple-400',
			texto: 'text-purple-100',
			icono: '⭐',
			animacion: 'pulse'
		},
		nuevo_ranking: {
			fondo: 'from-blue-500 to-indigo-600',
			borde: 'border-blue-400',
			texto: 'text-blue-100',
			icono: '🏅',
			animacion: 'swing'
		},
		racha_perdida: {
			fondo: 'from-red-500 to-red-600',
			borde: 'border-red-400',
			texto: 'text-red-100',
			icono: '💔',
			animacion: 'shake'
		},
		desafio_completado: {
			fondo: 'from-green-500 to-emerald-600',
			borde: 'border-green-400',
			texto: 'text-green-100',
			icono: '✅',
			animacion: 'bounce'
		},
		monedas_ganadas: {
			fondo: 'from-yellow-400 to-yellow-600',
			borde: 'border-yellow-300',
			texto: 'text-yellow-100',
			icono: '🪙',
			animacion: 'spin'
		},
		evento_especial: {
			fondo: 'from-indigo-500 to-purple-600',
			borde: 'border-indigo-400',
			texto: 'text-indigo-100',
			icono: '🎉',
			animacion: 'bounce'
		},
		meta_alcanzada: {
			fondo: 'from-teal-500 to-cyan-600',
			borde: 'border-teal-400',
			texto: 'text-teal-100',
			icono: '🎯',
			animacion: 'pulse'
		}
	};
	
	$: tipoConfig = tiposNotificacion[notificacion.tipo] || tiposNotificacion.logro_conseguido;
	
	$: prioridadConfig = {
		baja: 'opacity-80',
		normal: 'opacity-90',
		alta: 'opacity-100 shadow-lg',
		critica: 'opacity-100 shadow-2xl animate-pulse'
	};
	
	$: posicionConfig = {
		'top-right': 'fixed top-4 right-4 z-50',
		'top-left': 'fixed top-4 left-4 z-50',
		'bottom-right': 'fixed bottom-4 right-4 z-50',
		'bottom-left': 'fixed bottom-4 left-4 z-50',
		'center': 'fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 z-50'
	};
	
	// =====================================================
	// 🚀 FUNCIONES
	// =====================================================
	
	/**
	 * 🎯 Cerrar notificación
	 */
	function cerrarNotificacion() {
		visible = false;
		onClose();
		
		// Marcar como leída
		if (!notificacion.leida) {
			marcarComoLeida();
		}
	}
	
	/**
	 * 🎯 Manejar click en notificación
	 */
	function handleClick() {
		// Animar click
		escala.set(0.95);
		setTimeout(() => escala.set(1), 100);
		
		onClick();
		
		// Marcar como mostrada
		if (!notificacion.mostrada) {
			marcarComoMostrada();
		}
	}
	
	/**
	 * 🎯 Marcar como leída
	 */
	async function marcarComoLeida() {
		// Aquí iría la lógica para marcar como leída en la base de datos
		// Por ahora es placeholder
		console.log('Notificación marcada como leída:', notificacion.id);
	}
	
	/**
	 * 🎯 Marcar como mostrada
	 */
	async function marcarComoMostrada() {
		// Aquí iría la lógica para marcar como mostrada en la base de datos
		// Por ahora es placeholder
		console.log('Notificación marcada como mostrada:', notificacion.id);
	}
	
	/**
	 * 🎯 Formatear tiempo relativo
	 */
	function formatearTiempoRelativo(fecha: string): string {
		const ahora = new Date();
		const fechaNotificacion = new Date(fecha);
		const diff = ahora.getTime() - fechaNotificacion.getTime();
		
		const segundos = Math.floor(diff / 1000);
		const minutos = Math.floor(segundos / 60);
		const horas = Math.floor(minutos / 60);
		const dias = Math.floor(horas / 24);
		
		if (dias > 0) return `hace ${dias} día${dias > 1 ? 's' : ''}`;
		if (horas > 0) return `hace ${horas} hora${horas > 1 ? 's' : ''}`;
		if (minutos > 0) return `hace ${minutos} minuto${minutos > 1 ? 's' : ''}`;
		return 'hace un momento';
	}
	
	/**
	 * 🎯 Iniciar temporizador auto-close
	 */
	function iniciarTemporizador() {
		if (!autoClose) return;
		
		progreso.set(0);
		
		setTimeout(() => {
			cerrarNotificacion();
		}, autoCloseDelay);
	}
	
	/**
	 * 🎯 Obtener datos específicos del tipo
	 */
	function obtenerDatosEspecificos(): { titulo: string; descripcion: string; extras: any } {
		const datos = notificacion.datos_notificacion;
		
		switch (notificacion.tipo) {
			case 'logro_conseguido':
				return {
					titulo: notificacion.titulo,
					descripcion: `¡Has conseguido el logro "${datos.nombre}"!`,
					extras: {
						categoria: datos.categoria,
						xp_ganado: datos.xp_ganado,
						monedas_ganadas: datos.monedas_ganadas
					}
				};
			case 'subida_nivel':
				return {
					titulo: notificacion.titulo,
					descripcion: `¡Has subido del nivel ${datos.nivel_anterior} al ${datos.nivel_nuevo}!`,
					extras: {
						xp_ganado: datos.xp_ganado,
						nuevo_nivel: datos.nivel_nuevo
					}
				};
			case 'nuevo_ranking':
				return {
					titulo: notificacion.titulo,
					descripcion: `¡Nueva posición en el ranking ${datos.tipo_ranking}!`,
					extras: {
						posicion: datos.posicion,
						mejora: datos.mejora
					}
				};
			default:
				return {
					titulo: notificacion.titulo,
					descripcion: notificacion.mensaje,
					extras: datos
				};
		}
	}
	
	// =====================================================
	// 🎮 LIFECYCLE
	// =====================================================
	
	onMount(() => {
		iniciarTemporizador();
		
		// Limpiar intervalo al desmontar
		return () => {
			if (intervalo) clearInterval(intervalo);
		};
	});
	
	$: datosEspecificos = obtenerDatosEspecificos();
</script>

<!-- ===================================== -->
<!-- 🎮 TEMPLATE PRINCIPAL -->
<!-- ===================================== -->

{#if visible}
	<div 
		class="notificacion-gaming {posicionConfig[position]} {prioridadConfig[notificacion.prioridad]} max-w-sm w-full"
		transition:fly={{ y: position.includes('top') ? -100 : 100, duration: 300 }}
		style="transform: scale({$escala})"
	>
		<div class="bg-gradient-to-r {tipoConfig.fondo} rounded-lg border-2 {tipoConfig.borde} shadow-2xl backdrop-blur-md relative overflow-hidden">
			<!-- Efecto de brillo animado -->
			<div class="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-20 animate-pulse"></div>
			
			<!-- Contenido principal -->
			<div class="relative p-4 {tipoConfig.texto}">
				<!-- Header -->
				<div class="flex items-start space-x-3">
					<!-- Icono principal -->
					<div class="flex-shrink-0">
						<div class="text-2xl animate-{tipoConfig.animacion}">
							{notificacion.icono || tipoConfig.icono}
						</div>
					</div>
					
					<!-- Contenido -->
					<div class="flex-1 min-w-0">
						<div class="flex items-start justify-between">
							<div class="flex-1">
								<h3 class="text-sm font-bold leading-tight">
									{datosEspecificos.titulo}
								</h3>
								<p class="mt-1 text-xs opacity-90 leading-tight">
									{datosEspecificos.descripcion}
								</p>
							</div>
							
							<!-- Botón cerrar -->
							{#if allowManualClose}
								<button
									class="ml-2 text-white hover:text-gray-200 transition-colors duration-200"
									on:click={cerrarNotificacion}
								>
									<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
										<path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
									</svg>
								</button>
							{/if}
						</div>
						
						<!-- Extras específicos del tipo -->
						{#if datosEspecificos.extras}
							<div class="mt-3 space-y-1">
								{#if datosEspecificos.extras.xp_ganado}
									<div class="flex items-center space-x-1 text-xs opacity-80">
										<span>⚡</span>
										<span>{datosEspecificos.extras.xp_ganado} XP ganado</span>
									</div>
								{/if}
								{#if datosEspecificos.extras.monedas_ganadas}
									<div class="flex items-center space-x-1 text-xs opacity-80">
										<span>🪙</span>
										<span>{datosEspecificos.extras.monedas_ganadas} monedas</span>
									</div>
								{/if}
								{#if datosEspecificos.extras.posicion}
									<div class="flex items-center space-x-1 text-xs opacity-80">
										<span>🏅</span>
										<span>Posición #{datosEspecificos.extras.posicion}</span>
									</div>
								{/if}
							</div>
						{/if}
						
						<!-- Timestamp -->
						<div class="mt-2 text-xs opacity-70">
							{formatearTiempoRelativo(notificacion.created_at)}
						</div>
					</div>
				</div>
			</div>
			
			<!-- Barra de progreso auto-close -->
			{#if showProgress && autoClose}
				<div class="absolute bottom-0 left-0 right-0 h-1 bg-black bg-opacity-20">
					<div 
						class="h-full bg-white bg-opacity-60 transition-all duration-100 ease-linear"
						style="width: {$progreso}%"
					></div>
				</div>
			{/if}
			
			<!-- Partículas para notificaciones críticas -->
			{#if notificacion.prioridad === 'critica'}
				<div class="particulas-criticas">
					{#each Array(6) as _, i}
						<div 
							class="particula-critica"
							style="left: {Math.random() * 100}%; animation-delay: {i * 0.2}s"
						></div>
					{/each}
				</div>
			{/if}
		</div>
		
		<!-- Efecto de click -->
		<div 
			class="absolute inset-0 bg-white bg-opacity-10 rounded-lg cursor-pointer"
			on:click={handleClick}
			on:keydown={(e) => e.key === 'Enter' && handleClick()}
			role="button"
			tabindex="0"
		></div>
	</div>
{/if}

<!-- ===================================== -->
<!-- 🎨 ESTILOS GAMING -->
<!-- ===================================== -->

<style>
	.notificacion-gaming {
		animation: aparecer 0.3s ease-out;
	}
	
	.particulas-criticas {
		position: absolute;
		inset: 0;
		pointer-events: none;
		overflow: hidden;
	}
	
	.particula-critica {
		position: absolute;
		width: 4px;
		height: 4px;
		background: radial-gradient(circle, #ffffff 0%, #fbbf24 100%);
		border-radius: 50%;
		animation: particula-float 3s ease-in-out infinite;
	}
	
	/* Animaciones específicas */
	@keyframes aparecer {
		from {
			opacity: 0;
			transform: translateY(-20px) scale(0.95);
		}
		to {
			opacity: 1;
			transform: translateY(0) scale(1);
		}
	}
	
	@keyframes particula-float {
		0%, 100% {
			transform: translateY(0px);
			opacity: 0.7;
		}
		50% {
			transform: translateY(-10px);
			opacity: 1;
		}
	}
	
	/* Animaciones de iconos */
	.animate-bounce {
		animation: bounce 1s infinite;
	}
	
	.animate-pulse {
		animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
	}
	
	.animate-spin {
		animation: spin 1s linear infinite;
	}
	
	.animate-swing {
		animation: swing 1s ease-in-out infinite;
	}
	
	.animate-shake {
		animation: shake 0.5s ease-in-out infinite;
	}
	
	@keyframes swing {
		0%, 100% { transform: rotate(0deg); }
		25% { transform: rotate(-10deg); }
		75% { transform: rotate(10deg); }
	}
	
	@keyframes shake {
		0%, 100% { transform: translateX(0); }
		25% { transform: translateX(-5px); }
		75% { transform: translateX(5px); }
	}
	
	/* Responsive */
	@media (max-width: 640px) {
		.notificacion-gaming {
			max-width: calc(100vw - 2rem);
			margin: 0 1rem;
		}
	}
	
	/* Efectos hover */
	.notificacion-gaming:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
	}
	
	/* Tema oscuro */
	:global(.dark) .notificacion-gaming {
		backdrop-filter: blur(20px);
	}
</style> 