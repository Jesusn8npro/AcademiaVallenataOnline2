<!--
🏅 ACADEMIA VALLENATA ONLINE - PÁGINA DE RANKING GAMING
=====================================================
Página de ranking gaming con scroll infinito real
Carga pocos usuarios inicialmente, luego más automáticamente
=====================================================
-->

<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { fade, fly } from 'svelte/transition';
	import { cubicOut } from 'svelte/easing';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import GamificacionService from '../../lib/services/gamificacionService';
	import BarraXP from '../../lib/components/Gaming/BarraXP.svelte';
	import type { RankingGlobal } from '../../lib/services/gamificacionService';
	import { estadoUsuarioActual } from '../../lib/supabase/estadoUsuarioActual';
	import { obtenerSlugUsuario } from '../../lib/utilidades/utilidadesSlug';

	// =====================================================
	// 🎮 ESTADO LOCAL
	// =====================================================
	let rankingCompleto: RankingGlobal[] = []; // Todo el ranking
	let rankingMostrado: RankingGlobal[] = []; // Solo los que se muestran
	let cargando: boolean = true;
	let cargandoMas: boolean = false;
	let error: string = '';
	let categoriaActiva: string = 'general';
	let busqueda: string = '';
	let miPosicion: RankingGlobal | null = null;
	let mostrarSoloTop: boolean = false;
	let filtroNivel: string = 'todos';
	
	// =====================================================
	// 🔄 SCROLL INFINITO
	// =====================================================
	let usuariosMostrados: number = 6; // Empezar con 6 usuarios
	let incrementoPorScroll: number = 4; // Cargar 4 más cada vez
	let observador: IntersectionObserver;
	let elementoTrigger: HTMLElement;
	
	// =====================================================
	// 🎨 CONFIGURACIÓN
	// =====================================================
	const categorias = [
		{
			id: 'general',
			nombre: 'General',
			descripcion: 'Ranking global de la academia',
			icono: '🏆',
			color: 'from-yellow-500 to-orange-600'
		},
		{
			id: 'simulador',
			nombre: 'Simulador',
			descripcion: 'Mejores en el simulador de acordeón',
			icono: '🎮',
			color: 'from-blue-500 to-purple-600'
		},
		{
			id: 'cursos',
			nombre: 'Cursos',
			descripcion: 'Progreso en cursos y tutoriales',
			icono: '📚',
			color: 'from-green-500 to-blue-600'
		},
		{
			id: 'precision',
			nombre: 'Precisión',
			descripcion: 'Mejor precisión en interpretación',
			icono: '🎯',
			color: 'from-red-500 to-pink-600'
		},
		{
			id: 'constancia',
			nombre: 'Constancia',
			descripcion: 'Usuarios más constantes',
			icono: '🔥',
			color: 'from-orange-500 to-red-600'
		},
		{
			id: 'comunidad',
			nombre: 'Comunidad',
			descripcion: 'Participación en la comunidad',
			icono: '👥',
			color: 'from-purple-500 to-indigo-600'
		}
	];
	
	// =====================================================
	// 🚀 FUNCIONES
	// =====================================================
	
	/**
	 * 🎯 Cargar ranking completo
	 */
	async function cargarRanking() {
		try {
			cargando = true;
			error = '';
			usuariosMostrados = 6; // Reset a 6 usuarios
			
			console.log(`🎮 Cargando ranking completo: ${categoriaActiva}`);
			
			// Cargar ranking completo (hasta 200 usuarios)
			const ranking = await GamificacionService.obtenerRanking(categoriaActiva, 200);
			
			// Asignar datos completos
			rankingCompleto = ranking;
			
			// Mostrar solo los primeros 6
			actualizarUsuariosMostrados();
			
			// Cargar mi posición si estoy logueado
			if ($estadoUsuarioActual.user?.id) {
				const posicion = await GamificacionService.obtenerPosicionUsuario(
					$estadoUsuarioActual.user.id,
					categoriaActiva
				);
				miPosicion = posicion;
			}
			
			console.log(`✅ Ranking cargado: ${ranking.length} usuarios total, mostrando ${usuariosMostrados}`);
			
		} catch (err) {
			console.error('💥 Error cargando ranking:', err);
			error = 'Error al cargar el ranking: ' + ((err as any)?.message || 'Error desconocido');
		} finally {
			cargando = false;
		}
	}
	
	/**
	 * 🔄 Actualizar usuarios mostrados
	 */
	function actualizarUsuariosMostrados() {
		const rankingFiltrado = filtrarRanking();
		rankingMostrado = rankingFiltrado.slice(0, usuariosMostrados);
		
		console.log(`📊 Mostrando ${rankingMostrado.length} de ${rankingFiltrado.length} usuarios`);
	}
	
	/**
	 * 🔄 Cargar más usuarios (scroll infinito)
	 */
	function cargarMasUsuarios() {
		if (cargandoMas) return;
		
		const rankingFiltrado = filtrarRanking();
		
		// Si ya se están mostrando todos, no hacer nada
		if (usuariosMostrados >= rankingFiltrado.length) {
			console.log('🎯 Ya se muestran todos los usuarios');
			return;
		}
		
		cargandoMas = true;
		
		// Simular un pequeño delay para mejor UX
		setTimeout(() => {
			usuariosMostrados += incrementoPorScroll;
			
			console.log(`🔄 Cargando más usuarios: ${usuariosMostrados}`);
			
			actualizarUsuariosMostrados();
			cargandoMas = false;
		}, 300);
	}
	
	/**
	 * 🎯 Cambiar categoría
	 */
	function cambiarCategoria(categoria: string) {
		if (categoria === categoriaActiva) return;
		
		console.log(`🔄 Cambiando categoría a: ${categoria}`);
		categoriaActiva = categoria;
		cargarRanking();
	}
	
	/**
	 * 🎯 Filtrar ranking
	 */
	function filtrarRanking(): RankingGlobal[] {
		// Si no hay datos, devolver array vacío
		if (!rankingCompleto || !Array.isArray(rankingCompleto) || rankingCompleto.length === 0) {
			return [];
		}
		
		let ranking = rankingCompleto;
		
		// Filtro por búsqueda
		if (busqueda) {
			ranking = ranking.filter(item => 
				item.perfiles?.nombre?.toLowerCase().includes(busqueda.toLowerCase()) ||
				item.perfiles?.apellido?.toLowerCase().includes(busqueda.toLowerCase())
			);
		}
		
		// Filtro por nivel
		if (filtroNivel !== 'todos') {
			// Aquí se filtrarían por nivel cuando tengamos esa data
		}
		
		// Mostrar solo top 10 si está activado
		if (mostrarSoloTop) {
			ranking = ranking.slice(0, 10);
		}
		
		return ranking;
	}
	
	/**
	 * 🎨 Obtener color de posición
	 */
	function obtenerColorPosicion(posicion: number): string {
		if (posicion === 1) return 'text-yellow-400';
		if (posicion === 2) return 'text-gray-400';
		if (posicion === 3) return 'text-orange-400';
		if (posicion <= 10) return 'text-blue-400';
		if (posicion <= 50) return 'text-green-400';
		return 'text-gray-500';
	}
	
	/**
	 * 🎨 Obtener icono de posición
	 */
	function obtenerIconoPosicion(posicion: number): string {
		if (posicion === 1) return '🥇';
		if (posicion === 2) return '🥈';
		if (posicion === 3) return '🥉';
		if (posicion <= 10) return '🏅';
		return '📊';
	}
	
	/**
	 * 🎨 Obtener estilo de tarjeta por posición
	 */
	function obtenerEstiloTarjeta(posicion: number): string {
		if (posicion === 1) return 'bg-gradient-to-r from-yellow-500/20 to-orange-500/20 border-yellow-400';
		if (posicion === 2) return 'bg-gradient-to-r from-gray-400/20 to-gray-600/20 border-gray-400';
		if (posicion === 3) return 'bg-gradient-to-r from-orange-400/20 to-orange-600/20 border-orange-400';
		if (posicion <= 10) return 'bg-gradient-to-r from-blue-500/20 to-purple-500/20 border-blue-400';
		return 'bg-gradient-to-r from-gray-700/20 to-gray-800/20 border-gray-600';
	}
	
	/**
	 * 🎯 Formatear puntuación
	 */
	function formatearPuntuacion(puntuacion: number): string {
		if (puntuacion >= 1000000) {
			return (puntuacion / 1000000).toFixed(1) + 'M';
		}
		if (puntuacion >= 1000) {
			return (puntuacion / 1000).toFixed(1) + 'K';
		}
		return puntuacion.toLocaleString('es-CO');
	}

	/**
	 * 🖼️ Obtener URL de avatar con fallback
	 */
	function obtenerUrlAvatar(item: RankingGlobal): string | null {
		return item.perfiles?.url_foto_perfil || null;
	}

	/**
	 * 🎨 Obtener iniciales del usuario
	 */
	function obtenerIniciales(item: RankingGlobal): string {
		const nombre = item.perfiles?.nombre || '';
		const apellido = item.perfiles?.apellido || '';
		
		if (nombre && apellido) {
			return (nombre.charAt(0) + apellido.charAt(0)).toUpperCase();
		}
		if (nombre) {
			return nombre.charAt(0).toUpperCase();
		}
		return 'U';
	}

	/**
	 * 🎨 Obtener nombre completo del usuario
	 */
	function obtenerNombreCompleto(item: RankingGlobal): string {
		const nombre = item.perfiles?.nombre || '';
		const apellido = item.perfiles?.apellido || '';
		
		if (nombre && apellido) {
			return `${nombre} ${apellido}`;
		}
		if (nombre) {
			return nombre;
		}
		return 'Usuario';
	}

	/**
	 * 🏅 Navegar a perfil de usuario
	 */
	function navegarAlPerfil(item: RankingGlobal) {
		console.log(`🔗 Navegando al perfil de:`, item.perfiles);
		
		// Crear objeto con datos del usuario para obtener el slug
		const datosUsuario = {
			nombre_usuario: null,
			nombre: item.perfiles?.nombre,
			apellido: item.perfiles?.apellido,
			nombre_completo: obtenerNombreCompleto(item),
			usuario_nombre: item.perfiles?.nombre || null,
			usuario_id: item.usuario_id
		};
		
		// Obtener slug usando la función unificada
		const slug = obtenerSlugUsuario(datosUsuario);
		
		console.log(`✅ Slug generado: ${slug}`);
		console.log(`🔗 Navegando a: /usuarios/${slug}`);
		
		// Navegar al perfil
		goto(`/usuarios/${slug}`);
	}
	
	/**
	 * 🎯 Obtener cambio de posición
	 */
	function obtenerCambioPosicion(posicion: number, posicionAnterior: number | null): { tipo: string; valor: number } {
		if (!posicionAnterior) return { tipo: 'nuevo', valor: 0 };
		
		const diferencia = posicionAnterior - posicion;
		if (diferencia > 0) return { tipo: 'subida', valor: diferencia };
		if (diferencia < 0) return { tipo: 'bajada', valor: Math.abs(diferencia) };
		return { tipo: 'igual', valor: 0 };
	}
	
	/**
	 * 🔄 Configurar observer para scroll infinito
	 */
	function configurarScrollInfinito() {
		if (observador) {
			observador.disconnect();
		}
		
		observador = new IntersectionObserver((entries) => {
			entries.forEach(entry => {
				if (entry.isIntersecting) {
					console.log('🔄 Trigger scroll infinito detectado');
					cargarMasUsuarios();
				}
			});
		}, {
			rootMargin: '200px' // Empezar a cargar cuando esté 200px antes del final
		});
		
		if (elementoTrigger) {
			observador.observe(elementoTrigger);
		}
	}
	
	/**
	 * 🔄 Verificar si hay más usuarios para mostrar
	 */
	function hayMasUsuarios(): boolean {
		const rankingFiltrado = filtrarRanking();
		return usuariosMostrados < rankingFiltrado.length;
	}
	
	// =====================================================
	// 🎮 LIFECYCLE
	// =====================================================
	
	onMount(() => {
		cargarRanking();
	});
	
	onDestroy(() => {
		if (observador) {
			observador.disconnect();
		}
	});
	
	// Reactivo a cambios
	$: {
		// Cuando cambien los filtros, actualizar usuarios mostrados
		actualizarUsuariosMostrados();
	}
	
	$: categoriaInfo = categorias.find(c => c.id === categoriaActiva);
	
	// Configurar scroll infinito cuando cambie el elemento trigger
	$: if (elementoTrigger) {
		configurarScrollInfinito();
	}
</script>

<!-- ===================================== -->
<!-- 🎮 TEMPLATE PRINCIPAL -->
<!-- ===================================== -->

<div class="ranking-container min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 py-8">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		
		<!-- Header principal -->
		<div class="text-center mb-12">
			<h1 class="text-4xl md:text-5xl font-bold text-white mb-4 tracking-tight">
				🏆 Ranking Gaming
			</h1>
			<p class="text-xl text-gray-300 max-w-2xl mx-auto">
				Compite con otros músicos y alcanza la cima de la Academia Vallenata Online
			</p>
		</div>
		
		<!-- Selector de categorías -->
		<div class="mb-8">
			<div class="flex flex-wrap justify-center gap-4 mb-6">
				{#each categorias as categoria}
					<button
						class="categoria-btn {categoriaActiva === categoria.id ? 'activa' : ''}"
						class:activa={categoriaActiva === categoria.id}
						on:click={() => cambiarCategoria(categoria.id)}
					>
						<span class="text-xl mr-2">{categoria.icono}</span>
						<span class="font-medium">{categoria.nombre}</span>
					</button>
				{/each}
			</div>
			
			<!-- Descripción de categoría actual -->
			{#if categoriaInfo}
				<div class="text-center">
					<div class="inline-flex items-center bg-gray-800/50 backdrop-blur-sm rounded-lg px-4 py-2 border border-gray-700">
						<span class="text-2xl mr-3">{categoriaInfo.icono}</span>
						<div class="text-left">
							<h2 class="text-lg font-semibold text-white">{categoriaInfo.nombre}</h2>
							<p class="text-sm text-gray-400">{categoriaInfo.descripcion}</p>
						</div>
					</div>
				</div>
			{/if}
		</div>
		
		<!-- Filtros y búsqueda -->
		<div class="mb-8">
			<div class="flex flex-wrap justify-center gap-4 mb-6">
				<!-- Búsqueda -->
				<div class="relative">
					<input
						type="text"
						placeholder="Buscar usuario..."
						bind:value={busqueda}
						class="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-lg px-4 py-2 pl-10 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
					/>
					<div class="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
						🔍
					</div>
				</div>
				
				<!-- Filtros -->
				<div class="flex gap-2">
					<button
						class="filtro-btn {mostrarSoloTop ? 'activo' : ''}"
						on:click={() => mostrarSoloTop = !mostrarSoloTop}
					>
						🔝 Top 10
					</button>
					
					<select
						bind:value={filtroNivel}
						class="bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
					>
						<option value="todos">Todos los niveles</option>
						<option value="principiante">Principiante (1-10)</option>
						<option value="intermedio">Intermedio (11-25)</option>
						<option value="avanzado">Avanzado (26-50)</option>
						<option value="experto">Experto (51+)</option>
					</select>
				</div>
			</div>
		</div>
		
		<!-- Mi posición (si está logueado) -->
		{#if miPosicion && $estadoUsuarioActual.user}
			<div class="mb-8">
				<div class="bg-gradient-to-r from-blue-600/20 to-purple-600/20 backdrop-blur-sm rounded-xl p-6 border border-blue-400/30">
					<div class="flex items-center justify-between">
						<div class="flex items-center space-x-4">
							<div class="text-4xl">{obtenerIconoPosicion(miPosicion.posicion)}</div>
							<div>
								<h3 class="text-xl font-bold text-white">Tu Posición</h3>
								<p class="text-blue-300">#{miPosicion.posicion} en {categoriaInfo?.nombre}</p>
							</div>
						</div>
						<div class="text-right">
							<div class="text-2xl font-bold text-white">
								{formatearPuntuacion(miPosicion.puntuacion)}
							</div>
							<div class="text-sm text-gray-400">puntos</div>
						</div>
					</div>
				</div>
			</div>
		{/if}
		
		<!-- Contenido principal -->
		{#if cargando}
			<!-- Estado de carga -->
			<div class="text-center py-16">
				<div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
				<p class="mt-4 text-gray-400">Cargando ranking...</p>
			</div>
		{:else if error}
			<!-- Estado de error -->
			<div class="text-center py-16">
				<div class="text-6xl mb-4">❌</div>
				<h3 class="text-xl font-semibold text-white mb-2">Error al cargar</h3>
				<p class="text-gray-400 mb-4">{error}</p>
				<button
					class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg transition-colors"
					on:click={cargarRanking}
				>
					Intentar de nuevo
				</button>
			</div>
		{:else if !rankingCompleto || rankingCompleto.length === 0}
			<!-- Sin datos después de cargar -->
			<div class="text-center py-16">
				<div class="text-6xl mb-4">📊</div>
				<h3 class="text-xl font-semibold text-white mb-2">No hay datos disponibles</h3>
				<p class="text-gray-400">Aún no hay usuarios en el ranking de esta categoría.</p>
			</div>
		{:else if rankingMostrado.length === 0}
			<!-- Sin resultados de filtro -->
			<div class="text-center py-16">
				<div class="text-6xl mb-4">🔍</div>
				<h3 class="text-xl font-semibold text-white mb-2">Sin resultados</h3>
				<p class="text-gray-400">No se encontraron usuarios que coincidan con tu búsqueda.</p>
			</div>
		{:else}
			<!-- Lista de ranking -->
			<div class="space-y-4">
				{#each rankingMostrado as item, index (item.id)}
					<div 
						class="ranking-item {obtenerEstiloTarjeta(item.posicion)} backdrop-blur-sm rounded-xl p-6 border transition-all duration-300 hover:scale-105 hover:shadow-2xl"
						in:fly={{ y: 20, duration: 300, delay: index * 50 }}
					>
						<div class="flex items-center justify-between">
							<!-- Posición y usuario -->
							<div class="flex items-center space-x-4">
								<!-- Posición -->
								<div class="text-center min-w-[4rem]">
									<div class="text-3xl mb-1">{obtenerIconoPosicion(item.posicion)}</div>
									<div class="text-lg font-bold {obtenerColorPosicion(item.posicion)}">
										#{item.posicion}
									</div>
								</div>
								
								<!-- Avatar y nombre -->
								<div class="flex items-center space-x-3">
									<button 
										class="avatar-container cursor-pointer transition-all duration-300 hover:scale-110 hover:shadow-lg"
										on:click={() => navegarAlPerfil(item)}
										on:keydown={(e) => e.key === 'Enter' && navegarAlPerfil(item)}
										title="Ver perfil de {obtenerNombreCompleto(item)}"
									>
										{#if obtenerUrlAvatar(item)}
											<img 
												src={obtenerUrlAvatar(item)} 
												alt="Avatar de {obtenerNombreCompleto(item)}"
												class="w-12 h-12 rounded-full object-cover border-2 border-gray-600"
												loading="lazy"
											/>
										{:else}
											<div class="w-12 h-12 rounded-full bg-gradient-to-r from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg">
												{obtenerIniciales(item)}
											</div>
										{/if}
									</button>
									<div>
										<button 
											class="text-left cursor-pointer hover:text-blue-400 transition-colors duration-300"
											on:click={() => navegarAlPerfil(item)}
											on:keydown={(e) => e.key === 'Enter' && navegarAlPerfil(item)}
											title="Ver perfil de {obtenerNombreCompleto(item)}"
										>
											<h3 class="text-lg font-semibold text-white">
												{obtenerNombreCompleto(item)}
											</h3>
										</button>
										<div class="flex items-center space-x-2 text-sm text-gray-400">
											<span>⚡ Nivel {item.metricas?.nivel || 1}</span>
											<span>•</span>
											<span>🎯 {item.metricas?.precision_promedio || 0}% precisión</span>
										</div>
									</div>
								</div>
							</div>
							
							<!-- Puntuación y cambio -->
							<div class="text-right">
								<div class="flex items-center space-x-2">
									<div class="text-2xl font-bold text-white">
										{formatearPuntuacion(item.puntuacion)}
									</div>
									{#if item.posicion_anterior}
										{@const cambio = obtenerCambioPosicion(item.posicion, item.posicion_anterior)}
										<div class="cambio-posicion {cambio.tipo}">
											{#if cambio.tipo === 'subida'}
												<span class="text-green-400">▲{cambio.valor}</span>
											{:else if cambio.tipo === 'bajada'}
												<span class="text-red-400">▼{cambio.valor}</span>
											{:else if cambio.tipo === 'nuevo'}
												<span class="text-blue-400">NEW</span>
											{:else}
												<span class="text-gray-400">-</span>
											{/if}
										</div>
									{/if}
								</div>
								<div class="text-sm text-gray-400">puntos</div>
							</div>
						</div>
						
						<!-- Métricas adicionales -->
						{#if item.metricas}
							<div class="mt-4 pt-4 border-t border-gray-700/50">
								<div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
									{#if item.metricas.total_sesiones}
										<div class="text-center">
											<div class="text-blue-400 font-semibold">{item.metricas.total_sesiones}</div>
											<div class="text-gray-500">Sesiones</div>
										</div>
									{/if}
									{#if item.metricas.tiempo_total_minutos}
										<div class="text-center">
											<div class="text-green-400 font-semibold">{Math.round(item.metricas.tiempo_total_minutos / 60)}h</div>
											<div class="text-gray-500">Tiempo</div>
										</div>
									{/if}
									{#if item.metricas.logros_conseguidos}
										<div class="text-center">
											<div class="text-yellow-400 font-semibold">{item.metricas.logros_conseguidos}</div>
											<div class="text-gray-500">Logros</div>
										</div>
									{/if}
									{#if item.metricas.racha_maxima}
										<div class="text-center">
											<div class="text-orange-400 font-semibold">{item.metricas.racha_maxima}</div>
											<div class="text-gray-500">Racha máx</div>
										</div>
									{/if}
								</div>
							</div>
						{/if}
					</div>
				{/each}
			</div>
			
			<!-- Elemento trigger para scroll infinito -->
			{#if hayMasUsuarios()}
				<div 
					bind:this={elementoTrigger}
					class="trigger-scroll-infinito h-20 flex items-center justify-center mt-8"
				>
					{#if cargandoMas}
						<div class="text-center">
							<div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
							<p class="mt-2 text-gray-400 text-sm">Cargando más usuarios...</p>
						</div>
					{:else}
						<div class="text-center">
							<div class="text-2xl mb-2">📊</div>
							<p class="text-gray-500 text-sm">Haz scroll para ver más usuarios</p>
						</div>
					{/if}
				</div>
			{:else}
				<!-- Mensaje de final -->
				<div class="text-center mt-8">
					<div class="text-4xl mb-2">🎯</div>
					<p class="text-gray-400">¡Has visto todos los usuarios del ranking!</p>
					<p class="text-sm text-gray-500 mt-2">
						Total: {filtrarRanking().length} usuarios
					</p>
				</div>
			{/if}
		{/if}
	</div>
</div>

<!-- ===================================== -->
<!-- 🎨 ESTILOS GAMING -->
<!-- ===================================== -->

<style>
	.ranking-container {
		min-height: 100vh;
		background-attachment: fixed;
	}
	
	.categoria-btn {
		@apply bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-lg px-4 py-2 text-white transition-all duration-300 hover:bg-gray-700/50;
	}
	
	.categoria-btn.activa {
		@apply bg-blue-600 border-blue-500 text-white shadow-lg shadow-blue-500/25;
	}
	
	.filtro-btn {
		@apply bg-gray-800/50 backdrop-blur-sm border border-gray-700 rounded-lg px-3 py-2 text-white transition-all duration-300 hover:bg-gray-700/50;
	}
	
	.filtro-btn.activo {
		@apply bg-green-600 border-green-500 text-white shadow-lg;
	}
	
	.ranking-item {
		transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
	}
	
	.ranking-item:hover {
		transform: translateY(-2px);
	}
	
	.avatar-container {
		position: relative;
		display: inline-block;
	}
	
	.avatar-container::after {
		content: '';
		position: absolute;
		inset: -2px;
		background: linear-gradient(45deg, #3b82f6, #8b5cf6);
		border-radius: 50%;
		z-index: -1;
		opacity: 0;
		transition: opacity 0.3s ease;
	}
	
	.avatar-container:hover::after {
		opacity: 1;
	}
	
	.trigger-scroll-infinito {
		min-height: 80px;
		opacity: 0.7;
		transition: opacity 0.3s ease;
	}
	
	.trigger-scroll-infinito:hover {
		opacity: 1;
	}
	
	.cambio-posicion {
		@apply text-xs font-bold px-2 py-1 rounded-full;
	}
	
	.cambio-posicion.subida {
		@apply bg-green-500/20 text-green-400;
	}
	
	.cambio-posicion.bajada {
		@apply bg-red-500/20 text-red-400;
	}
	
	.cambio-posicion.nuevo {
		@apply bg-blue-500/20 text-blue-400;
	}
	
	/* Animaciones */
	@keyframes glow {
		0%, 100% { box-shadow: 0 0 5px rgba(59, 130, 246, 0.5); }
		50% { box-shadow: 0 0 20px rgba(59, 130, 246, 0.8); }
	}
	
	.ranking-item:nth-child(1) {
		animation: glow 3s ease-in-out infinite;
	}
	
	/* Elementos clickeables */
	.ranking-item button {
		background: none;
		border: none;
		padding: 0;
		font-family: inherit;
		font-size: inherit;
		color: inherit;
		text-align: inherit;
	}
	
	.ranking-item button:focus {
		outline: 2px solid #3b82f6;
		outline-offset: 2px;
		border-radius: 4px;
	}
	
	/* Responsive */
	@media (max-width: 768px) {
		.ranking-item {
			padding: 1rem;
		}
		
		.categoria-btn {
			padding: 0.5rem 1rem;
			font-size: 0.875rem;
		}
	}
	
	/* Tema oscuro */
	:global(.dark) .ranking-container {
		background: linear-gradient(135deg, rgba(15, 23, 42, 0.95) 0%, rgba(30, 41, 59, 0.95) 100%);
	}
</style>

<!-- ===================================== -->
<!-- 🎯 METADATOS DE PÁGINA -->
<!-- ===================================== -->

<svelte:head>
	<title>Ranking Gaming | Academia Vallenata Online</title>
	<meta name="description" content="Compite con otros músicos en el ranking gaming de la Academia Vallenata Online. Múltiples categorías, estadísticas detalladas y competencias épicas." />
	<meta name="keywords" content="ranking, gaming, acordeón, vallenato, competencia, música, academia" />
</svelte:head> 