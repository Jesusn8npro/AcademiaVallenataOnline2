<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase/clienteSupabase';
	import ListaUsuarios from '$lib/components/AdministradorUsuarios/ListaUsuarios.svelte';
	import DetalleUsuario from '$lib/components/AdministradorUsuarios/DetalleUsuario.svelte';
	import CrearUsuario from '$lib/components/AdministradorUsuarios/CrearUsuario.svelte';

	interface Usuario {
		id: string;
		nombre: string;
		apellido: string;
		nombre_completo: string;
		correo_electronico: string;
		rol: string;
		suscripcion: string;
		fecha_creacion: string;
		ultima_actividad?: string;
		url_foto_perfil?: string;
		eliminado: boolean;
		whatsapp?: string;
		ciudad?: string;
		pais?: string;
		nivel_habilidad?: string;
		documento_numero?: string;
		profesion?: string;
	}

	let usuarios: Usuario[] = [];
	let usuarioSeleccionado: Usuario | null = null;
	let mostrarCrearUsuario = false;
	let cargando = true;
	let error: string | null = null;
	let busqueda = '';
	let filtroRol = 'todos';
	let filtroSuscripcion = 'todas';
	let mostrarEliminados = false;

	// Estadísticas
	let estadisticas = {
		total: 0,
		activos: 0,
		administradores: 0,
		estudiantes: 0,
		premium: 0,
		gratuitos: 0,
		nuevosHoy: 0
	};

	onMount(() => {
		cargarUsuarios();
	});

	async function cargarUsuarios() {
		try {
			cargando = true;
			error = null;

			let query = supabase
				.from('perfiles')
				.select(`
					*,
					inscripciones(curso_id, tutorial_id, fecha_inscripcion, ultima_actividad)
				`);

			if (!mostrarEliminados) {
				query = query.eq('eliminado', false);
			}

			const { data, error: errorSupabase } = await query.order('fecha_creacion', { ascending: false });

			if (errorSupabase) {
				throw errorSupabase;
			}

			usuarios = data || [];
			calcularEstadisticas();
		} catch (err: any) {
			error = `Error al cargar usuarios: ${err.message}`;
			console.error('Error:', err);
		} finally {
			cargando = false;
		}
	}

	function calcularEstadisticas() {
		const hoy = new Date();
		hoy.setHours(0, 0, 0, 0);

		estadisticas = {
			total: usuarios.length,
			activos: usuarios.filter(u => !u.eliminado).length,
			administradores: usuarios.filter(u => u.rol === 'admin').length,
			estudiantes: usuarios.filter(u => u.rol === 'user').length,
			premium: usuarios.filter(u => u.suscripcion !== 'free').length,
			gratuitos: usuarios.filter(u => u.suscripcion === 'free').length,
			nuevosHoy: usuarios.filter(u => {
				const fechaCreacion = new Date(u.fecha_creacion);
				return fechaCreacion >= hoy;
			}).length
		};
	}

	function seleccionarUsuario(usuario: Usuario) {
		usuarioSeleccionado = usuario;
		mostrarCrearUsuario = false;
	}

	function cerrarDetalles() {
		usuarioSeleccionado = null;
	}

	function abrirCrearUsuario() {
		mostrarCrearUsuario = true;
		usuarioSeleccionado = null;
	}

	function cerrarCrearUsuario() {
		mostrarCrearUsuario = false;
	}

	async function onUsuarioCreado() {
		mostrarCrearUsuario = false;
		await cargarUsuarios();
	}

	async function onUsuarioActualizado(event: CustomEvent) {
		const usuarioActualizado = event.detail;
		
		console.log('🔄 Usuario actualizado recibido:', usuarioActualizado);
		console.log('🔍 Lista usuarios antes:', usuarios.map(u => ({ id: u.id, nombre_completo: u.nombre_completo, nombre: u.nombre, apellido: u.apellido })));
		
		// Actualizar el usuario en la lista local
		const indice = usuarios.findIndex(u => u.id === usuarioActualizado.id);
		if (indice !== -1) {
			console.log(`📍 Encontrado usuario en índice ${indice}`);
			usuarios[indice] = usuarioActualizado;
			usuarios = [...usuarios]; // Trigger reactivity
			console.log('✅ Usuario actualizado en lista');
		} else {
			console.log('❌ Usuario NO encontrado en lista');
		}

		console.log('🔍 Lista usuarios después:', usuarios.map(u => ({ id: u.id, nombre_completo: u.nombre_completo, nombre: u.nombre, apellido: u.apellido })));

		// Actualizar el usuario seleccionado
		if (usuarioSeleccionado && usuarioSeleccionado.id === usuarioActualizado.id) {
			usuarioSeleccionado = usuarioActualizado;
		}

		// Recalcular estadísticas
		calcularEstadisticas();
	}

	async function onUsuarioEliminado() {
		usuarioSeleccionado = null;
		await cargarUsuarios();
	}

	// Filtros reactivos
	$: usuariosFiltrados = usuarios.filter(usuario => {
		// Filtro de búsqueda
		const coincideBusqueda = busqueda === '' || 
			usuario.nombre?.toLowerCase().includes(busqueda.toLowerCase()) ||
			usuario.apellido?.toLowerCase().includes(busqueda.toLowerCase()) ||
			usuario.nombre_completo?.toLowerCase().includes(busqueda.toLowerCase()) ||
			usuario.correo_electronico?.toLowerCase().includes(busqueda.toLowerCase());

		// Filtro de rol
		const coincideRol = filtroRol === 'todos' || usuario.rol === filtroRol;

		// Filtro de suscripción
		const coincideSuscripcion = filtroSuscripcion === 'todas' || usuario.suscripcion === filtroSuscripcion;

		return coincideBusqueda && coincideRol && coincideSuscripcion;
	});
</script>

<svelte:head>
	<title>Gestión de Usuarios - Academia Vallenata Online</title>
</svelte:head>

<div class="admin-usuarios">
	<!-- Header principal -->
	<div class="header-admin">
		<div class="header-content">
			<div class="titulo-seccion">
				<div class="icono-header">
					<svg width="32" height="32" viewBox="0 0 24 24" fill="none">
						<path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" fill="currentColor"/>
					</svg>
				</div>
				<div>
					<h1>Gestión de Usuarios</h1>
					<p>Administra todos los estudiantes y usuarios de la Academia</p>
				</div>
			</div>
			<div class="acciones-header">
				<button class="btn-crear" on:click={abrirCrearUsuario}>
					<svg width="20" height="20" viewBox="0 0 24 24" fill="none">
						<path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" fill="currentColor"/>
					</svg>
					Crear Usuario
				</button>
				<button class="btn-recargar" on:click={cargarUsuarios} disabled={cargando}>
					<svg width="20" height="20" viewBox="0 0 24 24" fill="none" class:girando={cargando}>
						<path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z" fill="currentColor"/>
					</svg>
					{cargando ? 'Cargando...' : 'Recargar'}
				</button>
			</div>
		</div>
	</div>

	<!-- Estadísticas -->
	<div class="estadisticas-grid">
		<div class="stat-card">
			<div class="stat-icono usuarios-total">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A2.997 2.997 0 0 0 17.13 7H16.87c-1.31 0-2.45.85-2.83 2.08L11.5 18H14v2h6zM12.5 11.5c.83 0 1.5-.67 1.5-1.5s-.67-1.5-1.5-1.5S11 9.17 11 10s.67 1.5 1.5 1.5zm1.5 2.5h-3c-1.31 0-2.45.85-2.83 2.08L6.5 25H9v2h6v-6h1.5l-2.5-7z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.total}</span>
				<span class="stat-label">Total Usuarios</span>
			</div>
		</div>

		<div class="stat-card">
			<div class="stat-icono usuarios-activos">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.activos}</span>
				<span class="stat-label">Usuarios Activos</span>
			</div>
		</div>

		<div class="stat-card">
			<div class="stat-icono administradores">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.administradores}</span>
				<span class="stat-label">Administradores</span>
			</div>
		</div>

		<div class="stat-card">
			<div class="stat-icono estudiantes">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 9-4.91V17h2V9L12 3z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.estudiantes}</span>
				<span class="stat-label">Estudiantes</span>
			</div>
		</div>

		<div class="stat-card">
			<div class="stat-icono premium">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.premium}</span>
				<span class="stat-label">Usuarios Premium</span>
			</div>
		</div>

		<div class="stat-card">
			<div class="stat-icono nuevos">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm4.64 6.8c-.15 1.58-.08 5.74-.08 5.74s-2.05-1.35-4.56-1.35S7.44 14.54 7.44 14.54s.07-4.16-.08-5.74C7.36 8.8 8.34 8 9.36 8c.76 0 1.42.43 1.75 1.06.33-.63.99-1.06 1.75-1.06 1.02 0 2 .8 1.78 1.8z" fill="currentColor"/>
				</svg>
			</div>
			<div class="stat-info">
				<span class="stat-numero">{estadisticas.nuevosHoy}</span>
				<span class="stat-label">Nuevos Hoy</span>
			</div>
		</div>
	</div>

	<!-- Contenido principal -->
	<div class="contenido-principal">
		{#if error}
			<div class="error-mensaje">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none">
					<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" fill="currentColor"/>
				</svg>
				<p>{error}</p>
				<button on:click={cargarUsuarios}>Reintentar</button>
			</div>
		{:else if mostrarCrearUsuario}
			<CrearUsuario 
				on:usuarioCreado={onUsuarioCreado}
				on:cerrar={cerrarCrearUsuario}
			/>
		{:else if usuarioSeleccionado}
			<DetalleUsuario 
				usuario={usuarioSeleccionado}
				on:usuarioActualizado={onUsuarioActualizado}
				on:usuarioEliminado={onUsuarioEliminado}
				on:cerrar={cerrarDetalles}
			/>
		{:else}
			<ListaUsuarios 
				usuarios={usuariosFiltrados}
				{cargando}
				bind:busqueda
				bind:filtroRol
				bind:filtroSuscripcion
				bind:mostrarEliminados
				on:seleccionarUsuario={(e: CustomEvent) => seleccionarUsuario(e.detail)}
				on:recargar={cargarUsuarios}
			/>
		{/if}
	</div>
</div>

<style>
	.admin-usuarios {
		min-height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		padding: 20px;
	}

	.header-admin {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 20px;
		padding: 30px;
		margin-bottom: 30px;
		box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
	}

	.header-content {
		display: flex;
		justify-content: space-between;
		align-items: center;
		max-width: 1400px;
		margin: 0 auto;
	}

	.titulo-seccion {
		display: flex;
		align-items: center;
		gap: 20px;
	}

	.icono-header {
		width: 60px;
		height: 60px;
		background: linear-gradient(135deg, #667eea, #764ba2);
		border-radius: 15px;
		display: flex;
		align-items: center;
		justify-content: center;
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
	}

	.titulo-seccion h1 {
		color: white;
		font-size: 32px;
		font-weight: 700;
		margin: 0;
		text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
	}

	.titulo-seccion p {
		color: rgba(255, 255, 255, 0.8);
		margin: 5px 0 0 0;
		font-size: 16px;
	}

	.acciones-header {
		display: flex;
		gap: 15px;
	}

	.btn-crear {
		background: linear-gradient(135deg, #4CAF50, #45a049);
		color: white;
		border: none;
		padding: 12px 24px;
		border-radius: 12px;
		font-weight: 600;
		display: flex;
		align-items: center;
		gap: 8px;
		cursor: pointer;
		transition: all 0.3s ease;
		box-shadow: 0 4px 15px rgba(76, 175, 80, 0.3);
	}

	.btn-crear:hover {
		transform: translateY(-2px);
		box-shadow: 0 6px 20px rgba(76, 175, 80, 0.4);
	}

	.btn-recargar {
		background: rgba(255, 255, 255, 0.2);
		color: white;
		border: 1px solid rgba(255, 255, 255, 0.3);
		padding: 12px 24px;
		border-radius: 12px;
		font-weight: 600;
		display: flex;
		align-items: center;
		gap: 8px;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.btn-recargar:hover:not(:disabled) {
		background: rgba(255, 255, 255, 0.3);
		transform: translateY(-2px);
	}

	.btn-recargar:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.girando {
		animation: girar 1s linear infinite;
	}

	@keyframes girar {
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}

	.estadisticas-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 20px;
		margin-bottom: 30px;
		max-width: 1400px;
		margin-left: auto;
		margin-right: auto;
	}

	.stat-card {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 15px;
		padding: 20px;
		display: flex;
		align-items: center;
		gap: 15px;
		transition: all 0.3s ease;
		box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	}

	.stat-card:hover {
		transform: translateY(-5px);
		box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
	}

	.stat-icono {
		width: 50px;
		height: 50px;
		border-radius: 12px;
		display: flex;
		align-items: center;
		justify-content: center;
		color: white;
	}

	.usuarios-total { background: linear-gradient(135deg, #667eea, #764ba2); }
	.usuarios-activos { background: linear-gradient(135deg, #4CAF50, #45a049); }
	.administradores { background: linear-gradient(135deg, #FF9800, #F57C00); }
	.estudiantes { background: linear-gradient(135deg, #2196F3, #1976D2); }
	.premium { background: linear-gradient(135deg, #9C27B0, #7B1FA2); }
	.nuevos { background: linear-gradient(135deg, #FF5722, #D84315); }

	.stat-info {
		display: flex;
		flex-direction: column;
	}

	.stat-numero {
		font-size: 28px;
		font-weight: 700;
		color: white;
		line-height: 1;
	}

	.stat-label {
		font-size: 14px;
		color: rgba(255, 255, 255, 0.8);
		margin-top: 5px;
	}

	.contenido-principal {
		max-width: 1400px;
		margin: 0 auto;
	}

	.error-mensaje {
		background: rgba(244, 67, 54, 0.1);
		border: 1px solid rgba(244, 67, 54, 0.3);
		border-radius: 15px;
		padding: 30px;
		text-align: center;
		color: white;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 15px;
	}

	.error-mensaje button {
		background: #f44336;
		color: white;
		border: none;
		padding: 12px 24px;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 600;
		transition: background 0.3s ease;
	}

	.error-mensaje button:hover {
		background: #d32f2f;
	}

	@media (max-width: 768px) {
		.admin-usuarios {
			padding: 15px;
		}

		.header-content {
			flex-direction: column;
			gap: 20px;
		}

		.titulo-seccion {
			text-align: center;
		}

		.titulo-seccion h1 {
			font-size: 24px;
		}

		.estadisticas-grid {
			grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
			gap: 15px;
		}

		.stat-card {
			padding: 15px;
		}

		.stat-icono {
			width: 40px;
			height: 40px;
		}

		.stat-numero {
			font-size: 24px;
		}
	}
</style>
