<!--
🎮 ACADEMIA VALLENATA ONLINE - BARRA XP GAMING
=====================================================
Componente de barra de experiencia con diseño gaming de lujo
Animaciones suaves, efectos visuales premium
Integración completa con el servicio de gamificación
=====================================================
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import { tweened } from 'svelte/motion';
	import { cubicOut } from 'svelte/easing';
	import GamificacionService from '../../services/gamificacionService';
	import type { ExperienciaUsuario } from '../../services/gamificacionService';
	import { estadoUsuarioActual } from '../../supabase/estadoUsuarioActual';

	// =====================================================
	// 🎯 PROPIEDADES
	// =====================================================
	export let usuarioId: string = '';
	export let size: 'pequeño' | 'mediano' | 'grande' = 'mediano';
	export let mostrarDetalles: boolean = true;
	export let animarSubida: boolean = true;
	export let colorTema: string = '#3B82F6';
	
	// =====================================================
	// 🎮 ESTADO LOCAL
	// =====================================================
	let experiencia: ExperienciaUsuario | null = null;
	let cargando: boolean = true;
	let error: string = '';
	let mostrarCelebracion: boolean = false;
	
	// Animaciones
	const progreso = tweened(0, {
		duration: 1000,
		easing: cubicOut
	});
	
	const nivel = tweened(1, {
		duration: 800,
		easing: cubicOut
	});
	
	// =====================================================
	// 🎨 ESTILOS DINÁMICOS
	// =====================================================
	$: tamaños = {
		pequeño: {
			altura: '8px',
			texto: 'text-xs',
			padding: 'p-2',
			icono: 'w-4 h-4'
		},
		mediano: {
			altura: '12px',
			texto: 'text-sm',
			padding: 'p-3',
			icono: 'w-5 h-5'
		},
		grande: {
			altura: '16px',
			texto: 'text-base',
			padding: 'p-4',
			icono: 'w-6 h-6'
		}
	};
	
	$: porcentaje = experiencia ? (experiencia.xp_actual / experiencia.xp_siguiente_nivel) * 100 : 0;
	
	// =====================================================
	// 🚀 FUNCIONES
	// =====================================================
	
	/**
	 * 🎯 Cargar experiencia del usuario
	 */
	async function cargarExperiencia() {
		try {
			cargando = true;
			error = '';
			
			const exp = await GamificacionService.obtenerExperienciaUsuario(usuarioId);
			if (exp) {
				experiencia = exp;
				
				// Animar progreso
				progreso.set(porcentaje);
				nivel.set(exp.nivel);
			} else {
				error = 'No se pudo cargar la experiencia';
			}
		} catch (err) {
			console.error('Error cargando experiencia:', err);
			error = 'Error al cargar datos';
		} finally {
			cargando = false;
		}
	}
	
	/**
	 * 🎉 Animar subida de nivel
	 */
	function animarSubidaNivel() {
		mostrarCelebracion = true;
		setTimeout(() => {
			mostrarCelebracion = false;
		}, 2000);
	}
	
	/**
	 * 🎨 Obtener color de nivel
	 */
	function obtenerColorNivel(nivelActual: number): string {
		if (nivelActual <= 10) return 'from-green-400 to-green-600';
		if (nivelActual <= 25) return 'from-blue-400 to-blue-600';
		if (nivelActual <= 50) return 'from-purple-400 to-purple-600';
		if (nivelActual <= 75) return 'from-orange-400 to-orange-600';
		return 'from-red-400 to-red-600';
	}
	
	/**
	 * 🎨 Obtener emoji de nivel
	 */
	function obtenerEmojiNivel(nivelActual: number): string {
		if (nivelActual <= 10) return '🌱';
		if (nivelActual <= 25) return '🎵';
		if (nivelActual <= 50) return '⭐';
		if (nivelActual <= 75) return '🔥';
		return '👑';
	}
	
	/**
	 * 🎯 Formatear número con separadores
	 */
	function formatearNumero(num: number): string {
		return num.toLocaleString('es-CO');
	}
	
	// =====================================================
	// 🎮 LIFECYCLE
	// =====================================================
	
	onMount(() => {
		// Usar usuario actual si no se especifica
		if (!usuarioId && $estadoUsuarioActual.usuario?.id) {
			usuarioId = $estadoUsuarioActual.usuario.id;
		}
		
		if (usuarioId) {
			cargarExperiencia();
		}
	});
	
	// Recargar cuando cambie el usuario
	$: if (usuarioId) {
		cargarExperiencia();
	}
</script>

<!-- ===================================== -->
<!-- 🎮 TEMPLATE PRINCIPAL -->
<!-- ===================================== -->

<div class="relative {tamaños[size].padding}">
	{#if cargando}
		<!-- 🔄 Estado de carga -->
		<div class="animate-pulse">
			<div class="bg-gray-300 dark:bg-gray-700 rounded-full h-{tamaños[size].altura}"></div>
			<div class="flex justify-between mt-2">
				<div class="bg-gray-300 dark:bg-gray-700 rounded h-4 w-16"></div>
				<div class="bg-gray-300 dark:bg-gray-700 rounded h-4 w-20"></div>
			</div>
		</div>
	{:else if error}
		<!-- ❌ Estado de error -->
		<div class="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
			<div class="flex items-center">
				<span class="text-red-500 mr-2">⚠️</span>
				<span class="{tamaños[size].texto}">{error}</span>
			</div>
		</div>
	{:else if experiencia}
		<!-- 🎮 Contenido principal -->
		<div class="gaming-xp-container">
			<!-- Header con nivel y emoji -->
			{#if mostrarDetalles}
				<div class="flex items-center justify-between mb-3">
					<div class="flex items-center space-x-2">
						<div class="nivel-badge bg-gradient-to-r {obtenerColorNivel(experiencia.nivel)} text-white px-3 py-1 rounded-full font-bold {tamaños[size].texto}">
							<span class="mr-1">{obtenerEmojiNivel(experiencia.nivel)}</span>
							Nivel {Math.floor($nivel)}
						</div>
						{#if experiencia.racha_dias > 0}
							<div class="racha-badge bg-orange-500 text-white px-2 py-1 rounded-full text-xs font-medium">
								🔥 {experiencia.racha_dias} días
							</div>
						{/if}
					</div>
					<div class="xp-info text-right">
						<div class="text-gray-600 dark:text-gray-400 {tamaños[size].texto}">
							{formatearNumero(experiencia.xp_actual)} / {formatearNumero(experiencia.xp_siguiente_nivel)} XP
						</div>
						<div class="text-xs text-gray-500 dark:text-gray-500">
							Total: {formatearNumero(experiencia.xp_total)} XP
						</div>
					</div>
				</div>
			{/if}
			
			<!-- Barra de progreso principal -->
			<div class="relative">
				<!-- Fondo de la barra -->
				<div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden" style="height: {tamaños[size].altura}">
					<!-- Progreso animado -->
					<div 
						class="h-full bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 transition-all duration-1000 ease-out relative overflow-hidden"
						style="width: {$progreso}%"
					>
						<!-- Efecto de brillo -->
						<div class="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-20 animate-pulse"></div>
						
						<!-- Partículas flotantes -->
						<div class="absolute inset-0 overflow-hidden">
							{#each Array(5) as _, i}
								<div 
									class="absolute w-1 h-1 bg-white rounded-full animate-ping"
									style="left: {20 + (i * 15)}%; top: 50%; animation-delay: {i * 0.2}s"
								></div>
							{/each}
						</div>
					</div>
				</div>
				
				<!-- Indicador de porcentaje -->
				<div class="absolute right-0 top-0 transform translate-x-full -translate-y-1/2 ml-2">
					<div class="bg-gray-800 dark:bg-gray-200 text-white dark:text-gray-800 px-2 py-1 rounded text-xs font-bold">
						{Math.round($progreso)}%
					</div>
				</div>
			</div>
			
			<!-- Detalles de categorías de XP -->
			{#if mostrarDetalles && size !== 'pequeño'}
				<div class="mt-4 grid grid-cols-2 md:grid-cols-4 gap-3">
					<div class="categoria-xp">
						<div class="text-xs text-gray-500 dark:text-gray-400">Cursos</div>
						<div class="text-sm font-semibold text-green-600 dark:text-green-400">
							📚 {formatearNumero(experiencia.xp_cursos)}
						</div>
					</div>
					<div class="categoria-xp">
						<div class="text-xs text-gray-500 dark:text-gray-400">Simulador</div>
						<div class="text-sm font-semibold text-blue-600 dark:text-blue-400">
							🎮 {formatearNumero(experiencia.xp_simulador)}
						</div>
					</div>
					<div class="categoria-xp">
						<div class="text-xs text-gray-500 dark:text-gray-400">Comunidad</div>
						<div class="text-sm font-semibold text-purple-600 dark:text-purple-400">
							👥 {formatearNumero(experiencia.xp_comunidad)}
						</div>
					</div>
					<div class="categoria-xp">
						<div class="text-xs text-gray-500 dark:text-gray-400">Logros</div>
						<div class="text-sm font-semibold text-orange-600 dark:text-orange-400">
							🏆 {formatearNumero(experiencia.xp_logros)}
						</div>
					</div>
				</div>
			{/if}
			
			<!-- Próximo nivel -->
			{#if mostrarDetalles && experiencia.nivel < 100}
				<div class="mt-3 text-center">
					<div class="text-xs text-gray-500 dark:text-gray-400">
						Próximo nivel en {formatearNumero(experiencia.xp_siguiente_nivel - experiencia.xp_actual)} XP
					</div>
				</div>
			{/if}
		</div>
		
		<!-- 🎉 Celebración de subida de nivel -->
		{#if mostrarCelebracion}
			<div class="celebracion-overlay">
				<div class="celebracion-content">
					<div class="text-4xl animate-bounce">🎉</div>
					<div class="text-xl font-bold text-yellow-400 animate-pulse">
						¡Nivel {experiencia.nivel}!
					</div>
					<div class="text-sm text-gray-300">
						¡Felicidades por tu progreso!
					</div>
				</div>
			</div>
		{/if}
	{/if}
</div>

<!-- ===================================== -->
<!-- 🎨 ESTILOS GAMING -->
<!-- ===================================== -->

<style>
	.gaming-xp-container {
		@apply relative;
		background: linear-gradient(135deg, rgba(59, 130, 246, 0.1) 0%, rgba(139, 92, 246, 0.1) 100%);
		border-radius: 12px;
		padding: 16px;
		border: 1px solid rgba(59, 130, 246, 0.2);
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
		backdrop-filter: blur(10px);
	}
	
	.gaming-xp-container::before {
		content: '';
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: linear-gradient(135deg, rgba(59, 130, 246, 0.05) 0%, rgba(139, 92, 246, 0.05) 100%);
		border-radius: 12px;
		pointer-events: none;
	}
	
	.nivel-badge {
		@apply relative;
		box-shadow: 0 4px 14px 0 rgba(0, 0, 0, 0.25);
		transform: translateY(-2px);
		transition: all 0.3s ease;
	}
	
	.nivel-badge:hover {
		transform: translateY(-4px);
		box-shadow: 0 6px 20px 0 rgba(0, 0, 0, 0.35);
	}
	
	.racha-badge {
		@apply animate-pulse;
		box-shadow: 0 2px 8px 0 rgba(251, 146, 60, 0.4);
	}
	
	.categoria-xp {
		@apply text-center p-2 rounded-lg;
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		transition: all 0.3s ease;
	}
	
	.categoria-xp:hover {
		background: rgba(255, 255, 255, 0.2);
		transform: translateY(-2px);
	}
	
	.celebracion-overlay {
		@apply fixed inset-0 z-50 flex items-center justify-center;
		background: rgba(0, 0, 0, 0.8);
		backdrop-filter: blur(5px);
		animation: fadeIn 0.3s ease-out;
	}
	
	.celebracion-content {
		@apply text-center p-8 rounded-lg;
		background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
		border: 2px solid #fbbf24;
		box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
		animation: slideUp 0.5s ease-out;
	}
	
	@keyframes fadeIn {
		from { opacity: 0; }
		to { opacity: 1; }
	}
	
	@keyframes slideUp {
		from { 
			opacity: 0;
			transform: translateY(20px);
		}
		to { 
			opacity: 1;
			transform: translateY(0);
		}
	}
	
	/* Animaciones de partículas */
	@keyframes float {
		0%, 100% { transform: translateY(0px); }
		50% { transform: translateY(-4px); }
	}
	
	/* Responsive */
	@media (max-width: 768px) {
		.gaming-xp-container {
			padding: 12px;
		}
		
		.nivel-badge {
			padding: 4px 8px;
			font-size: 12px;
		}
	}
	
	/* Tema oscuro */
	:global(.dark) .gaming-xp-container {
		background: linear-gradient(135deg, rgba(30, 41, 59, 0.8) 0%, rgba(51, 65, 85, 0.8) 100%);
		border-color: rgba(100, 116, 139, 0.3);
	}
	
	:global(.dark) .categoria-xp {
		background: rgba(30, 41, 59, 0.6);
		border-color: rgba(100, 116, 139, 0.3);
	}
</style> 