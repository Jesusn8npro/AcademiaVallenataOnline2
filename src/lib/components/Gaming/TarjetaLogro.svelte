<!--
🏆 ACADEMIA VALLENATA ONLINE - TARJETA LOGRO GAMING
=====================================================
Componente de tarjeta para mostrar logros individuales
Diseño gaming premium con animaciones y efectos visuales
Estados: bloqueado, en progreso, conseguido
=====================================================
-->

<script lang="ts">
	import { onMount } from 'svelte';
	import { tweened } from 'svelte/motion';
	import { quintOut } from 'svelte/easing';
	import { fade } from 'svelte/transition';
	import type { LogroSistema, LogroUsuario } from '../../services/gamificacionService';

	// =====================================================
	// 🎯 PROPIEDADES
	// =====================================================
	export let logro: LogroSistema;
	export let logroUsuario: LogroUsuario | null = null;
	export let size: 'pequeño' | 'mediano' | 'grande' = 'mediano';
	export let mostrarProgreso: boolean = true;
	export let mostrarRecompensas: boolean = true;
	export let animarHover: boolean = true;
	export let clickeable: boolean = true;
	
	// =====================================================
	// 🎮 ESTADO LOCAL
	// =====================================================
	let mostrarDetalles: boolean = false;
	let animandoConseguido: boolean = false;
	
	// Animaciones
	const progreso = tweened(0, {
		duration: 1000,
		easing: quintOut
	});
	
	const brillo = tweened(0, {
		duration: 500,
		easing: quintOut
	});
	
	// =====================================================
	// 🎨 ESTILOS DINÁMICOS
	// =====================================================
	$: tamaños = {
		pequeño: {
			contenedor: 'w-64 h-32',
			icono: 'text-3xl',
			titulo: 'text-sm',
			descripcion: 'text-xs',
			padding: 'p-3'
		},
		mediano: {
			contenedor: 'w-80 h-40',
			icono: 'text-4xl',
			titulo: 'text-base',
			descripcion: 'text-sm',
			padding: 'p-4'
		},
		grande: {
			contenedor: 'w-96 h-48',
			icono: 'text-5xl',
			titulo: 'text-lg',
			descripcion: 'text-base',
			padding: 'p-6'
		}
	};
	
	// Estados del logro
	$: conseguido = logroUsuario?.conseguido || false;
	$: bloqueado = !logroUsuario;
	$: enProgreso = logroUsuario && !conseguido && logroUsuario.progreso_actual > 0;
	$: porcentajeProgreso = logroUsuario?.porcentaje_progreso || 0;
	
	// Colores por dificultad
	$: coloresDificultad = {
		facil: {
			fondo: 'from-green-500 to-green-600',
			borde: 'border-green-400',
			texto: 'text-green-300',
			brillo: 'shadow-green-500/50'
		},
		medio: {
			fondo: 'from-blue-500 to-blue-600',
			borde: 'border-blue-400',
			texto: 'text-blue-300',
			brillo: 'shadow-blue-500/50'
		},
		dificil: {
			fondo: 'from-purple-500 to-purple-600',
			borde: 'border-purple-400',
			texto: 'text-purple-300',
			brillo: 'shadow-purple-500/50'
		},
		legendario: {
			fondo: 'from-yellow-500 to-orange-600',
			borde: 'border-yellow-400',
			texto: 'text-yellow-300',
			brillo: 'shadow-yellow-500/50'
		}
	};
	
	$: colorLogro = coloresDificultad[logro.dificultad];
	
	// =====================================================
	// 🚀 FUNCIONES
	// =====================================================
	
	/**
	 * 🎯 Manejar click en la tarjeta
	 */
	function handleClick() {
		if (!clickeable) return;
		
		mostrarDetalles = !mostrarDetalles;
		
		// Animar brillo
		brillo.set(1);
		setTimeout(() => brillo.set(0), 200);
	}
	
	/**
	 * 🎉 Animar logro conseguido
	 */
	function animarConseguido() {
		animandoConseguido = true;
		setTimeout(() => {
			animandoConseguido = false;
		}, 1000);
	}
	
	/**
	 * 🎨 Obtener emoji por categoría
	 */
	function obtenerEmojiCategoria(categoria: string): string {
		const emojis: Record<string, string> = {
			constancia: '🔥',
			progreso: '📈',
			precision: '🎯',
			social: '👥',
			especial: '⭐',
			simulador: '🎮',
			cursos: '📚',
			comunidad: '🌟'
		};
		return emojis[categoria] || '🏆';
	}
	
	/**
	 * 🎯 Formatear fecha
	 */
	function formatearFecha(fecha: string): string {
		return new Date(fecha).toLocaleDateString('es-CO', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}
	
	// =====================================================
	// 🎮 LIFECYCLE
	// =====================================================
	
	onMount(() => {
		// Animar progreso
		progreso.set(porcentajeProgreso);
		
		// Si está conseguido, animar
		if (conseguido) {
			setTimeout(() => animarConseguido(), 500);
		}
	});
	
	// Reactivo al cambio de progreso
	$: if (porcentajeProgreso) {
		progreso.set(porcentajeProgreso);
	}
</script>

<!-- ===================================== -->
<!-- 🎮 TEMPLATE PRINCIPAL -->
<!-- ===================================== -->

<div 
	class="logro-tarjeta {tamaños[size].contenedor} {tamaños[size].padding} relative overflow-hidden cursor-pointer transform transition-all duration-300 {animarHover ? 'hover:scale-105' : ''}"
	class:conseguido
	class:bloqueado
	class:en-progreso={enProgreso}
	class:animando={animandoConseguido}
	on:click={handleClick}
	on:keydown={(e) => e.key === 'Enter' && handleClick()}
	role="button"
	tabindex="0"
>
	<!-- Fondo animado -->
	<div class="absolute inset-0 bg-gradient-to-br {conseguido ? colorLogro.fondo : 'from-gray-600 to-gray-700'} opacity-90"></div>
	
	<!-- Efecto de brillo -->
	<div 
		class="absolute inset-0 bg-gradient-to-r from-transparent via-white to-transparent opacity-0 transition-opacity duration-200"
		style="opacity: {$brillo * 0.3}"
	></div>
	
	<!-- Borde brillante para logros conseguidos -->
	{#if conseguido}
		<div class="absolute inset-0 border-2 {colorLogro.borde} rounded-lg animate-pulse"></div>
	{/if}
	
	<!-- Contenido principal -->
	<div class="relative z-10 h-full flex flex-col">
		<!-- Header -->
		<div class="flex items-start justify-between mb-2">
			<!-- Icono del logro -->
			<div class="logro-icono {tamaños[size].icono} {conseguido ? 'animate-bounce' : ''}">
				{#if bloqueado}
					<span class="text-gray-500">🔒</span>
				{:else}
					<span class="filter {conseguido ? 'drop-shadow-lg' : 'grayscale'}">{logro.icono}</span>
				{/if}
			</div>
			
			<!-- Indicadores -->
			<div class="flex flex-col items-end space-y-1">
				<!-- Dificultad -->
				<div class="dificultad-badge {colorLogro.texto} text-xs font-bold px-2 py-1 rounded-full bg-black bg-opacity-30">
					{logro.dificultad.toUpperCase()}
				</div>
				
				<!-- Categoría -->
				<div class="categoria-badge text-xs text-gray-300 px-2 py-1 rounded-full bg-black bg-opacity-30">
					{obtenerEmojiCategoria(logro.categoria)} {logro.categoria}
				</div>
			</div>
		</div>
		
		<!-- Título y descripción -->
		<div class="flex-1 min-h-0">
			<h3 class="logro-titulo {tamaños[size].titulo} font-bold text-white mb-1 line-clamp-2">
				{logro.nombre}
			</h3>
			<p class="logro-descripcion {tamaños[size].descripcion} text-gray-300 line-clamp-2">
				{logro.descripcion_corta || logro.descripcion}
			</p>
		</div>
		
		<!-- Barra de progreso -->
		{#if mostrarProgreso && enProgreso}
			<div class="mt-3">
				<div class="flex justify-between items-center mb-1">
					<span class="text-xs text-gray-300">Progreso</span>
					<span class="text-xs text-gray-300">{Math.round($progreso)}%</span>
				</div>
				<div class="w-full bg-gray-700 rounded-full h-2 overflow-hidden">
					<div 
						class="h-full bg-gradient-to-r {colorLogro.fondo} transition-all duration-1000 ease-out"
						style="width: {$progreso}%"
					></div>
				</div>
			</div>
		{/if}
		
		<!-- Recompensas -->
		{#if mostrarRecompensas && conseguido}
			<div class="mt-3 flex items-center justify-between text-xs">
				{#if logro.xp_recompensa > 0}
					<div class="flex items-center space-x-1 text-blue-300">
						<span>⚡</span>
						<span>{logro.xp_recompensa} XP</span>
					</div>
				{/if}
				{#if logro.monedas_recompensa > 0}
					<div class="flex items-center space-x-1 text-yellow-300">
						<span>🪙</span>
						<span>{logro.monedas_recompensa}</span>
					</div>
				{/if}
			</div>
		{/if}
		
		<!-- Fecha de conseguido -->
		{#if conseguido && logroUsuario?.conseguido_en}
			<div class="mt-2 text-xs text-gray-400">
				Conseguido el {formatearFecha(logroUsuario.conseguido_en)}
			</div>
		{/if}
	</div>
	
	<!-- Efecto de partículas para logros conseguidos -->
	{#if conseguido && animandoConseguido}
		<div class="particulas-container">
			{#each Array(8) as _, i}
				<div 
					class="particula"
					style="left: {50 + Math.sin(i * 0.785) * 40}%; top: {50 + Math.cos(i * 0.785) * 40}%"
				></div>
			{/each}
		</div>
	{/if}
	
	<!-- Overlay de detalles -->
	{#if mostrarDetalles}
		<div class="detalles-overlay" transition:fade={{ duration: 200 }}>
			<div class="detalles-contenido">
				<div class="text-center mb-4">
					<div class="text-4xl mb-2">{logro.icono}</div>
					<h3 class="text-xl font-bold text-white">{logro.nombre}</h3>
				</div>
				
				<div class="space-y-3">
					<div>
						<h4 class="text-sm font-semibold text-gray-300 mb-1">Descripción</h4>
						<p class="text-sm text-gray-400">{logro.descripcion}</p>
					</div>
					
					{#if logro.xp_recompensa > 0 || logro.monedas_recompensa > 0}
						<div>
							<h4 class="text-sm font-semibold text-gray-300 mb-1">Recompensas</h4>
							<div class="flex items-center space-x-4 text-sm">
								{#if logro.xp_recompensa > 0}
									<div class="flex items-center space-x-1 text-blue-300">
										<span>⚡</span>
										<span>{logro.xp_recompensa} XP</span>
									</div>
								{/if}
								{#if logro.monedas_recompensa > 0}
									<div class="flex items-center space-x-1 text-yellow-300">
										<span>🪙</span>
										<span>{logro.monedas_recompensa} monedas</span>
									</div>
								{/if}
							</div>
						</div>
					{/if}
					
					{#if logroUsuario && !conseguido}
						<div>
							<h4 class="text-sm font-semibold text-gray-300 mb-1">Progreso</h4>
							<div class="text-sm text-gray-400">
								{logroUsuario.progreso_actual} / {logroUsuario.progreso_objetivo}
							</div>
						</div>
					{/if}
				</div>
				
				<button 
					class="w-full mt-4 bg-gray-700 hover:bg-gray-600 text-white py-2 px-4 rounded-lg transition-colors duration-200"
					on:click|stopPropagation={() => mostrarDetalles = false}
				>
					Cerrar
				</button>
			</div>
		</div>
	{/if}
</div>

<!-- ===================================== -->
<!-- 🎨 ESTILOS GAMING -->
<!-- ===================================== -->

<style>
	.logro-tarjeta {
		background: linear-gradient(135deg, rgba(17, 24, 39, 0.8) 0%, rgba(31, 41, 55, 0.8) 100%);
		border-radius: 12px;
		border: 1px solid rgba(75, 85, 99, 0.5);
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
		backdrop-filter: blur(10px);
	}
	
	.logro-tarjeta.conseguido {
		box-shadow: 0 8px 32px -4px rgba(59, 130, 246, 0.4);
		border-color: rgba(59, 130, 246, 0.6);
	}
	
	.logro-tarjeta.bloqueado {
		opacity: 0.7;
		filter: grayscale(0.5);
	}
	
	.logro-tarjeta.en-progreso {
		border-color: rgba(168, 85, 247, 0.4);
		box-shadow: 0 4px 20px -4px rgba(168, 85, 247, 0.3);
	}
	
	.logro-tarjeta.animando {
		animation: logoConseguido 1s ease-out;
	}
	
	.logro-icono {
		filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.5));
	}
	
	.dificultad-badge {
		backdrop-filter: blur(5px);
	}
	
	.categoria-badge {
		backdrop-filter: blur(5px);
	}
	
	.detalles-overlay {
		position: absolute;
		inset: 0;
		background: rgba(0, 0, 0, 0.95);
		border-radius: 12px;
		display: flex;
		align-items: center;
		justify-content: center;
		backdrop-filter: blur(5px);
		z-index: 20;
	}
	
	.detalles-contenido {
		max-width: 90%;
		max-height: 90%;
		overflow-y: auto;
		padding: 20px;
	}
	
	.particulas-container {
		position: absolute;
		inset: 0;
		pointer-events: none;
		z-index: 15;
	}
	
	.particula {
		position: absolute;
		width: 6px;
		height: 6px;
		background: radial-gradient(circle, #fbbf24 0%, #f59e0b 100%);
		border-radius: 50%;
		animation: particula 1s ease-out forwards;
	}
	
	/* Animaciones */
	@keyframes logoConseguido {
		0% { transform: scale(1); }
		50% { transform: scale(1.05); }
		100% { transform: scale(1); }
	}
	
	@keyframes particula {
		0% {
			transform: translate(0, 0) scale(0);
			opacity: 1;
		}
		50% {
			transform: translate(var(--dx, 0), var(--dy, 0)) scale(1);
			opacity: 0.8;
		}
		100% {
			transform: translate(calc(var(--dx, 0) * 2), calc(var(--dy, 0) * 2)) scale(0);
			opacity: 0;
		}
	}
	
	/* Utilidades */
	.line-clamp-2 {
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}
	
	/* Transiciones */
	.transition-fade {
		transition: opacity 0.2s ease-in-out;
	}
	
	/* Responsive */
	@media (max-width: 768px) {
		.logro-tarjeta {
			transform: none !important;
		}
		
		.logro-tarjeta:hover {
			transform: none !important;
		}
	}
	
	/* Tema oscuro */
	:global(.dark) .logro-tarjeta {
		background: linear-gradient(135deg, rgba(15, 23, 42, 0.9) 0%, rgba(30, 41, 59, 0.9) 100%);
		border-color: rgba(51, 65, 85, 0.6);
	}
</style> 