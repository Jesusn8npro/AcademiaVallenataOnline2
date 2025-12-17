<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { fade, slide } from 'svelte/transition';
	import { notificacionesService, type Notificacion, type EstadisticasNotificaciones } from '$lib/services/notificacionesService';
	import { goto } from '$app/navigation';

	// Estado de la página
	let notificaciones: Notificacion[] = [];
	let notificacionesFiltradas: Notificacion[] = [];
	let estadisticas: EstadisticasNotificaciones | null = null;
	let cargando = true;
	let error = '';

	// Filtros
	let filtroCategoria = 'todas';
	let filtroLeida = 'todas';
	let busqueda = '';

	// UI
	let vistaActual: 'lista' | 'estadisticas' = 'lista';
	let mostrarFiltros = false;

	// Categorías disponibles
	const categorias = [
		{ valor: 'todas', nombre: 'Todas las categorías', icono: '📋' },
		{ valor: 'contenido', nombre: 'Contenido Educativo', icono: '🎓' },
		{ valor: 'pago', nombre: 'Pagos y Transacciones', icono: '💳' },
		{ valor: 'comunidad', nombre: 'Comunidad', icono: '👥' },
		{ valor: 'progreso', nombre: 'Progreso', icono: '📈' },
		{ valor: 'sistema', nombre: 'Sistema', icono: '⚙️' },
		{ valor: 'promocion', nombre: 'Promociones', icono: '🎁' }
	];

	/**
	 * 🚀 Cargar datos iniciales
	 */
	onMount(async () => {
		await cargarNotificaciones();
		await cargarEstadisticas();

		// Suscribirse a notificaciones en tiempo real
		await notificacionesService.suscribirseANotificaciones((nuevaNotificacion) => {
			notificaciones = [nuevaNotificacion, ...notificaciones];
			aplicarFiltros();
			cargarEstadisticas(); // Actualizar estadísticas
		});

		// Suscribirse al contador en tiempo real
		notificacionesService.suscribirseAContador((nuevoContador) => {
			// Actualizar estadísticas cuando cambie el contador
			cargarEstadisticas();
		});
	});

	/**
	 * 🧹 Limpiar suscripciones
	 */
	onDestroy(() => {
		notificacionesService.desuscribirseDeNotificaciones();
	});

	/**
	 * 📥 Cargar notificaciones
	 */
	async function cargarNotificaciones() {
		cargando = true;
		error = '';

		const { notificaciones: data, error: errorNotif } = await notificacionesService.obtenerNotificaciones({
			limite: 100
		});

		if (errorNotif) {
			error = `Error al cargar notificaciones: ${errorNotif}`;
		} else {
			notificaciones = data;
			aplicarFiltros();
		}

		cargando = false;
	}

	/**
	 * 📊 Cargar estadísticas
	 */
	async function cargarEstadisticas() {
		const { estadisticas: data, error: errorEst } = await notificacionesService.obtenerEstadisticas();
		
		if (!errorEst) {
			estadisticas = data;
		}
	}

	/**
	 * 🔍 Aplicar filtros a las notificaciones
	 */
	function aplicarFiltros() {
		notificacionesFiltradas = notificaciones.filter(notif => {
			// Filtro por categoría
			if (filtroCategoria !== 'todas' && notif.categoria !== filtroCategoria) {
				return false;
			}

			// Filtro por estado de lectura
			if (filtroLeida === 'leidas' && !notif.leida) return false;
			if (filtroLeida === 'no_leidas' && notif.leida) return false;

			// Filtro por búsqueda
			if (busqueda) {
				const termino = busqueda.toLowerCase();
				return (
					notif.titulo.toLowerCase().includes(termino) ||
					notif.mensaje.toLowerCase().includes(termino)
				);
			}

			return true;
		});
	}

	/**
	 * ✅ Marcar notificación como leída
	 */
	async function marcarComoLeida(notificacion: Notificacion) {
		if (notificacion.leida) return;

		const { exito } = await notificacionesService.marcarComoLeida([notificacion.id]);
		
		if (exito) {
			// Actualizar localmente
			notificaciones = notificaciones.map(n => 
				n.id === notificacion.id ? { ...n, leida: true, fecha_lectura: new Date().toISOString() } : n
			);
			aplicarFiltros();
			cargarEstadisticas();
		}
	}

	/**
	 * ✅ Marcar todas como leídas
	 */
	async function marcarTodasComoLeidas() {
		if (!confirm('¿Estás seguro de marcar todas las notificaciones como leídas?')) {
			return;
		}

		const { exito } = await notificacionesService.marcarTodasComoLeidas();
		
		if (exito) {
			// Actualizar localmente
			notificaciones = notificaciones.map(n => ({ 
				...n, 
				leida: true, 
				fecha_lectura: new Date().toISOString() 
			}));
			aplicarFiltros();
			cargarEstadisticas();
		}
	}

	/**
	 * 🗑️ Archivar notificación
	 */
	async function archivarNotificacion(notificacion: Notificacion) {
		if (!confirm('¿Estás seguro de archivar esta notificación?')) {
			return;
		}

		const { exito } = await notificacionesService.archivarNotificacion(notificacion.id);
		
		if (exito) {
			// Remover de la lista local
			notificaciones = notificaciones.filter(n => n.id !== notificacion.id);
			aplicarFiltros();
			cargarEstadisticas();
		}
	}

	/**
	 * 🔗 Manejar clic en notificación
	 */
	async function manejarClicNotificacion(notificacion: Notificacion) {
		// Marcar como leída si no lo está
		await marcarComoLeida(notificacion);

		// Navegar a URL de acción si existe
		if (notificacion.url_accion) {
			goto(notificacion.url_accion);
		}
	}

	/**
	 * 🎨 Obtener clase CSS para prioridad
	 */
	function obtenerClasePrioridad(prioridad: string): string {
		switch (prioridad) {
			case 'alta': return 'prioridad-alta';
			case 'normal': return 'prioridad-normal';
			case 'baja': return 'prioridad-baja';
			default: return 'prioridad-normal';
		}
	}

	/**
	 * 🎯 Obtener descripción de categoría
	 */
	function obtenerDescripcionCategoria(categoria: string): string {
		const cat = categorias.find(c => c.valor === categoria);
		return cat ? cat.nombre : categoria;
	}

	// Reactivos
	$: if (notificaciones) aplicarFiltros();
	$: if (filtroCategoria || filtroLeida || busqueda !== undefined) aplicarFiltros();
</script>

<!-- 📱 Meta tags -->
<svelte:head>
	<title>Notificaciones - Academia Vallenata Online</title>
	<meta name="description" content="Mantente al día con todas las novedades de Academia Vallenata Online" />
</svelte:head>

<div class="contenedor-notificaciones">
	<!-- 🔝 Header Mejorado -->
	<div class="header-notificaciones">
		<div class="titulo-seccion">
			<div class="icono-principal">
				<div class="icono-campana">🔔</div>
				{#if estadisticas && estadisticas.no_leidas > 0}
					<div class="badge-contador-header">{estadisticas.no_leidas}</div>
				{/if}
			</div>
			<div class="info-header">
				<h1>Centro de Notificaciones</h1>
				<p class="subtitulo">
					{#if estadisticas}
						{estadisticas.total} notificaciones totales • 
						<span class="highlight">{estadisticas.no_leidas} pendientes</span> • 
						Actualizado: {new Date().toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' })}
					{:else}
						Mantente al día con todas las novedades de tu academia
					{/if}
				</p>
			</div>
		</div>

		<!-- 📊 Estadísticas mejoradas -->
		{#if estadisticas}
			<div class="estadisticas-rapidas" transition:fade>
				<div class="stat-card">
					<div class="stat-icono">📋</div>
					<div class="stat-info">
						<span class="numero">{estadisticas.total}</span>
						<span class="label">Total</span>
					</div>
				</div>
				<div class="stat-card destacado">
					<div class="stat-icono">🔴</div>
					<div class="stat-info">
						<span class="numero">{estadisticas.no_leidas}</span>
						<span class="label">Sin leer</span>
					</div>
				</div>
				<div class="stat-card exito">
					<div class="stat-icono">✅</div>
					<div class="stat-info">
						<span class="numero">{estadisticas.total - estadisticas.no_leidas}</span>
						<span class="label">Leídas</span>
					</div>
				</div>
			</div>
		{/if}

		<!-- 🎛️ Controles -->
		<div class="controles-header">
			<button 
				class="boton-vista" 
				class:activo={vistaActual === 'lista'}
				on:click={() => vistaActual = 'lista'}
			>
				<span class="icono">📋</span>
				Lista
			</button>
			
			<button 
				class="boton-vista" 
				class:activo={vistaActual === 'estadisticas'}
				on:click={() => vistaActual = 'estadisticas'}
			>
				<span class="icono">📊</span>
				Estadísticas
			</button>

			<button 
				class="boton-filtros" 
				class:activo={mostrarFiltros}
				on:click={() => mostrarFiltros = !mostrarFiltros}
			>
				<span class="icono">🔍</span>
				Filtros
			</button>

			{#if estadisticas && estadisticas.no_leidas > 0}
				<button class="boton-marcar-todas" on:click={marcarTodasComoLeidas}>
					<span class="icono">✅</span>
					Marcar todas como leídas
				</button>
			{/if}
		</div>
	</div>

	<!-- 🔍 Panel de filtros -->
	{#if mostrarFiltros}
		<div class="panel-filtros" transition:slide>
			<div class="filtros-grid">
				<!-- Búsqueda -->
				<div class="filtro-busqueda">
					<label for="busqueda">Buscar notificaciones:</label>
					<input 
						id="busqueda"
						type="text" 
						bind:value={busqueda} 
						placeholder="Buscar por título o mensaje..."
						class="campo-busqueda"
					/>
				</div>

				<!-- Filtro por categoría -->
				<div class="filtro-categoria">
					<label for="categoria">Categoría:</label>
					<select id="categoria" bind:value={filtroCategoria} class="selector-categoria">
						{#each categorias as categoria}
							<option value={categoria.valor}>
								{categoria.icono} {categoria.nombre}
							</option>
						{/each}
					</select>
				</div>

				<!-- Filtro por estado -->
				<div class="filtro-estado">
					<label for="estado">Estado:</label>
					<select id="estado" bind:value={filtroLeida} class="selector-estado">
						<option value="todas">📬 Todas</option>
						<option value="no_leidas">🔴 Sin leer</option>
						<option value="leidas">✅ Leídas</option>
					</select>
				</div>
			</div>
		</div>
	{/if}

	<!-- 📊 Vista de estadísticas -->
	{#if vistaActual === 'estadisticas' && estadisticas}
		<div class="vista-estadisticas" transition:fade>
			<div class="estadisticas-grid">
				<!-- Resumen general -->
				<div class="tarjeta-estadistica">
					<h3>📊 Resumen General</h3>
					<div class="stats-grid">
						<div class="stat-item">
							<span class="numero-grande">{estadisticas.total}</span>
							<span class="descripcion">Total de notificaciones</span>
						</div>
						<div class="stat-item">
							<span class="numero-grande destacado">{estadisticas.no_leidas}</span>
							<span class="descripcion">Sin leer</span>
						</div>
						<div class="stat-item">
							<span class="numero-grande">{estadisticas.total - estadisticas.no_leidas}</span>
							<span class="descripcion">Leídas</span>
						</div>
					</div>
				</div>

				<!-- Por categoría -->
				<div class="tarjeta-estadistica">
					<h3>📂 Por Categoría</h3>
					<div class="lista-categorias">
						{#each Object.entries(estadisticas.por_categoria) as [categoria, cantidad]}
							<div class="item-categoria">
								<span class="nombre-categoria">
									{categorias.find(c => c.valor === categoria)?.icono || '📋'}
									{obtenerDescripcionCategoria(categoria)}
								</span>
								<span class="cantidad-categoria">{cantidad}</span>
							</div>
						{/each}
					</div>
				</div>

				<!-- Por prioridad -->
				<div class="tarjeta-estadistica">
					<h3>⚡ Por Prioridad</h3>
					<div class="lista-prioridades">
						{#each Object.entries(estadisticas.por_prioridad) as [prioridad, cantidad]}
							<div class="item-prioridad" class:alta={prioridad === 'alta'} class:normal={prioridad === 'normal'} class:baja={prioridad === 'baja'}>
								<span class="nombre-prioridad">
									{prioridad === 'alta' ? '🔴' : prioridad === 'normal' ? '🟡' : '🟢'}
									{prioridad.charAt(0).toUpperCase() + prioridad.slice(1)}
								</span>
								<span class="cantidad-prioridad">{cantidad}</span>
							</div>
						{/each}
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- 📋 Vista de lista -->
	{#if vistaActual === 'lista'}
		<div class="vista-lista">
			{#if cargando}
				<div class="cargando">
					<div class="spinner"></div>
					<p>Cargando notificaciones...</p>
				</div>
			{:else if error}
				<div class="error-mensaje">
					<span class="icono-error">❌</span>
					<p>{error}</p>
					<button class="boton-reintentar" on:click={cargarNotificaciones}>
						Reintentar
					</button>
				</div>
			{:else if notificacionesFiltradas.length === 0}
				<div class="sin-notificaciones">
					<span class="icono-vacio">📭</span>
					<h3>No hay notificaciones</h3>
					<p>
						{#if busqueda || filtroCategoria !== 'todas' || filtroLeida !== 'todas'}
							No se encontraron notificaciones con los filtros aplicados.
						{:else}
							¡Estás al día! No tienes notificaciones nuevas.
						{/if}
					</p>
				</div>
			{:else}
				<div class="lista-notificaciones">
					{#each notificacionesFiltradas as notificacion (notificacion.id)}
						<div 
							class="tarjeta-notificacion" 
							class:no-leida={!notificacion.leida}
							class:prioridad-alta={notificacion.prioridad === 'alta'}
							class:clickeable={notificacion.url_accion}
							on:click={() => manejarClicNotificacion(notificacion)}
							transition:slide
						>
							<!-- Icono de categoría -->
							<div 
								class="icono-categoria" 
								style="background-color: {notificacionesService.obtenerColorPorCategoria(notificacion.categoria)}"
							>
								{notificacion.icono || notificacionesService.obtenerIconoPorTipo(notificacion.tipo)}
							</div>

							<!-- Contenido -->
							<div class="contenido-notificacion">
								<div class="header-notificacion">
									<h4 class="titulo-notificacion">{notificacion.titulo}</h4>
									<div class="metadatos">
										<span class="categoria">{obtenerDescripcionCategoria(notificacion.categoria)}</span>
										<span class="tiempo">{notificacionesService.formatearTiempoTranscurrido(notificacion.fecha_creacion)}</span>
									</div>
								</div>
								
								<p class="mensaje-notificacion">{notificacion.mensaje}</p>

								{#if notificacion.url_accion}
									<span class="enlace-accion">👉 Hacer clic para ver más</span>
								{/if}
							</div>

							<!-- Acciones -->
							<div class="acciones-notificacion">
								{#if !notificacion.leida}
									<button 
										class="boton-accion marcar-leida"
										on:click|stopPropagation={() => marcarComoLeida(notificacion)}
										title="Marcar como leída"
									>
										✅
									</button>
								{/if}
								
								<button 
									class="boton-accion archivar"
									on:click|stopPropagation={() => archivarNotificacion(notificacion)}
									title="Archivar notificación"
								>
									🗑️
								</button>
							</div>

							<!-- Indicador de no leída -->
							{#if !notificacion.leida}
								<div class="indicador-no-leida"></div>
							{/if}
						</div>
					{/each}
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
.contenedor-notificaciones {
	min-height: 100vh;
	background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
	padding: 2rem;
	font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
}

/* 🔝 Header */
.header-notificaciones {
	background: white;
	border-radius: 16px;
	padding: 2rem;
	margin-bottom: 2rem;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
	border: 1px solid #e2e8f0;
}

.titulo-seccion {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 1.5rem;
	margin-bottom: 2rem;
}

.icono-principal {
	position: relative;
	display: flex;
	align-items: center;
	justify-content: center;
}

.icono-campana {
	font-size: 3rem;
	animation: campanaBalance 2s ease-in-out infinite;
}

.badge-contador-header {
	position: absolute;
	top: -8px;
	right: -8px;
	background: linear-gradient(135deg, #ef4444, #dc2626);
	color: white;
	font-size: 0.8rem;
	font-weight: 700;
	padding: 0.25rem 0.5rem;
	border-radius: 12px;
	min-width: 24px;
	text-align: center;
	box-shadow: 0 2px 8px rgba(239, 68, 68, 0.4);
	animation: pulso 2s infinite;
}

.info-header {
	text-align: left;
}

.info-header h1 {
	font-size: 2.5rem;
	font-weight: 700;
	color: #1e293b;
	margin: 0 0 0.5rem 0;
	background: linear-gradient(135deg, #1e293b, #3b82f6);
	-webkit-background-clip: text;
	-webkit-text-fill-color: transparent;
	background-clip: text;
}

.subtitulo {
	color: #64748b;
	font-size: 1.1rem;
	margin: 0;
	line-height: 1.5;
}

.highlight {
	color: #ef4444;
	font-weight: 600;
}

.estadisticas-rapidas {
	display: flex;
	justify-content: center;
	gap: 2rem;
	margin-bottom: 2rem;
	flex-wrap: wrap;
}

.stat-card {
	display: flex;
	align-items: center;
	gap: 1rem;
	padding: 1.5rem;
	background: #f8fafc;
	border-radius: 16px;
	min-width: 140px;
	border: 2px solid transparent;
	transition: all 0.3s ease;
}

.stat-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.stat-card.destacado {
	background: linear-gradient(135deg, #ef4444, #dc2626);
	color: white;
	border-color: #ef4444;
}

.stat-card.exito {
	background: linear-gradient(135deg, #10b981, #059669);
	color: white;
	border-color: #10b981;
}

.stat-icono {
	font-size: 1.5rem;
	opacity: 0.8;
}

.stat-info {
	display: flex;
	flex-direction: column;
}

.stat-info .numero {
	font-size: 1.75rem;
	font-weight: 700;
	line-height: 1;
}

.stat-info .label {
	font-size: 0.875rem;
	margin-top: 0.25rem;
	opacity: 0.8;
}

.controles-header {
	display: flex;
	justify-content: center;
	gap: 1rem;
	flex-wrap: wrap;
}

.boton-vista,
.boton-filtros,
.boton-marcar-todas {
	display: flex;
	align-items: center;
	gap: 0.5rem;
	padding: 0.75rem 1.5rem;
	border: 2px solid #e2e8f0;
	background: white;
	border-radius: 12px;
	font-weight: 600;
	color: #64748b;
	cursor: pointer;
	transition: all 0.3s ease;
}

.boton-vista:hover,
.boton-filtros:hover,
.boton-marcar-todas:hover {
	border-color: #3b82f6;
	color: #3b82f6;
	transform: translateY(-2px);
}

.boton-vista.activo,
.boton-filtros.activo {
	background: #3b82f6;
	border-color: #3b82f6;
	color: white;
}

.boton-marcar-todas {
	background: linear-gradient(135deg, #10b981, #059669);
	border-color: #10b981;
	color: white;
}

/* 🔍 Panel de filtros */
.panel-filtros {
	background: white;
	border-radius: 16px;
	padding: 2rem;
	margin-bottom: 2rem;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
	border: 1px solid #e2e8f0;
}

.filtros-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
	gap: 1.5rem;
}

.filtro-busqueda label,
.filtro-categoria label,
.filtro-estado label {
	display: block;
	font-weight: 600;
	color: #374151;
	margin-bottom: 0.5rem;
}

.campo-busqueda,
.selector-categoria,
.selector-estado {
	width: 100%;
	padding: 0.75rem;
	border: 2px solid #e5e7eb;
	border-radius: 8px;
	font-size: 1rem;
	transition: all 0.3s ease;
}

.campo-busqueda:focus,
.selector-categoria:focus,
.selector-estado:focus {
	outline: none;
	border-color: #3b82f6;
	box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* 📊 Vista de estadísticas */
.vista-estadisticas {
	background: white;
	border-radius: 16px;
	padding: 2rem;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
	border: 1px solid #e2e8f0;
}

.estadisticas-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
	gap: 2rem;
}

.tarjeta-estadistica {
	background: #f8fafc;
	border-radius: 12px;
	padding: 1.5rem;
}

.tarjeta-estadistica h3 {
	margin: 0 0 1rem 0;
	color: #1e293b;
	font-size: 1.25rem;
}

.stats-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
	gap: 1rem;
}

.stat-item {
	text-align: center;
	padding: 1rem;
	background: white;
	border-radius: 8px;
}

.numero-grande {
	display: block;
	font-size: 2rem;
	font-weight: 700;
	color: #1e293b;
}

.numero-grande.destacado {
	color: #3b82f6;
}

.descripcion {
	display: block;
	font-size: 0.875rem;
	color: #64748b;
	margin-top: 0.25rem;
}

.lista-categorias,
.lista-prioridades {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
}

.item-categoria,
.item-prioridad {
	display: flex;
	justify-content: space-between;
	align-items: center;
	padding: 0.75rem;
	background: white;
	border-radius: 8px;
}

.cantidad-categoria,
.cantidad-prioridad {
	font-weight: 700;
	color: #1e293b;
	background: #e2e8f0;
	padding: 0.25rem 0.75rem;
	border-radius: 20px;
	font-size: 0.875rem;
}

/* 📋 Vista de lista */
.vista-lista {
	background: white;
	border-radius: 16px;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
	border: 1px solid #e2e8f0;
	overflow: hidden;
}

.lista-notificaciones {
	display: flex;
	flex-direction: column;
}

.tarjeta-notificacion {
	display: flex;
	align-items: flex-start;
	gap: 1rem;
	padding: 1.5rem;
	border-bottom: 1px solid #f1f5f9;
	position: relative;
	transition: all 0.3s ease;
}

.tarjeta-notificacion:hover {
	background: #f8fafc;
}

.tarjeta-notificacion.clickeable {
	cursor: pointer;
}

.tarjeta-notificacion.clickeable:hover {
	background: #f1f5f9;
	transform: translateX(4px);
}

.tarjeta-notificacion.no-leida {
	background: linear-gradient(90deg, #eff6ff 0%, #ffffff 100%);
	border-left: 4px solid #3b82f6;
}

.tarjeta-notificacion.prioridad-alta {
	border-left: 4px solid #ef4444;
}

.icono-categoria {
	display: flex;
	align-items: center;
	justify-content: center;
	width: 48px;
	height: 48px;
	border-radius: 12px;
	color: white;
	font-size: 1.5rem;
	font-weight: bold;
	flex-shrink: 0;
}

.contenido-notificacion {
	flex: 1;
}

.header-notificacion {
	display: flex;
	justify-content: space-between;
	align-items: flex-start;
	margin-bottom: 0.5rem;
}

.titulo-notificacion {
	font-size: 1.1rem;
	font-weight: 600;
	color: #1e293b;
	margin: 0;
	line-height: 1.4;
}

.metadatos {
	display: flex;
	gap: 1rem;
	flex-shrink: 0;
}

.categoria,
.tiempo {
	font-size: 0.75rem;
	padding: 0.25rem 0.5rem;
	border-radius: 6px;
	font-weight: 500;
}

.categoria {
	background: #e2e8f0;
	color: #475569;
}

.tiempo {
	background: #f1f5f9;
	color: #64748b;
}

.mensaje-notificacion {
	color: #64748b;
	margin: 0;
	line-height: 1.5;
}

.enlace-accion {
	display: inline-block;
	margin-top: 0.5rem;
	font-size: 0.875rem;
	color: #3b82f6;
	font-weight: 500;
}

.acciones-notificacion {
	display: flex;
	gap: 0.5rem;
	flex-shrink: 0;
}

.boton-accion {
	width: 36px;
	height: 36px;
	border: none;
	border-radius: 8px;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 1rem;
	transition: all 0.3s ease;
}

.boton-accion.marcar-leida {
	background: #dcfce7;
	color: #16a34a;
}

.boton-accion.marcar-leida:hover {
	background: #16a34a;
	color: white;
}

.boton-accion.archivar {
	background: #fef2f2;
	color: #dc2626;
}

.boton-accion.archivar:hover {
	background: #dc2626;
	color: white;
}

.indicador-no-leida {
	position: absolute;
	top: 1rem;
	right: 1rem;
	width: 12px;
	height: 12px;
	background: #3b82f6;
	border-radius: 50%;
}

/* 🎯 Estados especiales */
.cargando,
.error-mensaje,
.sin-notificaciones {
	text-align: center;
	padding: 4rem 2rem;
}

.spinner {
	width: 48px;
	height: 48px;
	border: 4px solid #e5e7eb;
	border-top: 4px solid #3b82f6;
	border-radius: 50%;
	animation: spin 1s linear infinite;
	margin: 0 auto 1rem;
}

@keyframes spin {
	0% { transform: rotate(0deg); }
	100% { transform: rotate(360deg); }
}

@keyframes campanaBalance {
	0%, 100% { transform: rotate(0deg); }
	25% { transform: rotate(-10deg); }
	75% { transform: rotate(10deg); }
}

@keyframes pulso {
	0% { transform: scale(1); opacity: 1; }
	50% { transform: scale(1.1); opacity: 0.8; }
	100% { transform: scale(1); opacity: 1; }
}

.icono-error,
.icono-vacio {
	font-size: 4rem;
	display: block;
	margin-bottom: 1rem;
}

.boton-reintentar {
	background: #3b82f6;
	color: white;
	border: none;
	padding: 0.75rem 1.5rem;
	border-radius: 8px;
	font-weight: 600;
	cursor: pointer;
	margin-top: 1rem;
}

/* 📱 Responsive */
@media (max-width: 768px) {
	.contenedor-notificaciones {
		padding: 1rem;
	}

	.header-notificaciones {
		padding: 1.5rem;
	}

	.titulo-seccion h1 {
		font-size: 2rem;
	}

	.estadisticas-rapidas {
		gap: 1rem;
	}

	.controles-header {
		gap: 0.5rem;
	}

	.boton-vista,
	.boton-filtros,
	.boton-marcar-todas {
		padding: 0.5rem 1rem;
		font-size: 0.875rem;
	}

	.tarjeta-notificacion {
		padding: 1rem;
		flex-direction: column;
		gap: 1rem;
	}

	.header-notificacion {
		flex-direction: column;
		gap: 0.5rem;
	}

	.metadatos {
		justify-content: flex-start;
	}
}
</style> 