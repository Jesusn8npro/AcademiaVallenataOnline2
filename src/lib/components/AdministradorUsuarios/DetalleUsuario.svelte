<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';
	import { supabase } from '$lib/supabase/clienteSupabase';
	// Definir interface Usuario localmente
	interface Usuario {
		id: string;
		nombre: string;
		apellido: string;
		nombre_completo: string;
		correo_electronico: string;
		rol: string;
		suscripcion: string;
		fecha_creacion: string;
		fecha_actualizacion: string;
		eliminado: boolean;
		url_foto_perfil?: string;
		ciudad?: string;
		pais?: string;
		whatsapp?: string;
		nivel_habilidad?: string;
		documento_numero?: string;
		profesion?: string;
	}

	interface Curso {
		id: string;
		titulo: string;
		imagen_url: string;
		precio_normal: number;
		precio_rebajado: number | null;
		descripcion: string;
	}

	interface Tutorial {
		id: string;
		titulo: string;
		imagen_url: string;
		duracion: number;
		precio_normal: number;
		precio_rebajado: number | null;
		descripcion: string;
	}

	export let usuario: Usuario;

	const dispatch = createEventDispatcher();

	let cargando = false;
	let error = '';
	let exito = false;
	let editando = false;
	let pestanaActiva = 'personal'; // personal, cursos, pagos, actividad

	// Datos editables
	let datosEditables = { ...usuario };

	// Datos adicionales
	let cursosInscritos: any[] = [];
	let cursosDisponibles: any[] = [];
	let tutorialesDisponibles: any[] = [];
	let historialPagos: any[] = [];
	let estadisticasActividad = {
		tiempoTotal: 0,
		sesionesHoy: 0,
		ultimaActividad: null as string | null,
		paginasFavoritas: [] as Array<{ pagina: string; visitas: number }>
	};

	let cargandoCursos = false;
	let cargandoPagos = false;
	let cargandoActividad = false;
	let cargandoDisponibles = false;

	// Estados para gestión de cursos
	let mostrarAgregarCursos = false;
	let busquedaCursos = '';
	let mostrarGestionMembresia = false;

	// Estados para drag & drop
	let draggedItem: any = null;
	let draggedType: 'curso' | 'tutorial' = 'curso';

	onMount(() => {
		cargarDatosCompletos();
	});

	async function cargarDatosCompletos() {
		await Promise.all([
			cargarCursosInscritos(),
			cargarHistorialPagos(),
			cargarEstadisticasActividad(),
			cargarCursosDisponibles()
		]);
	}

	async function cargarCursosDisponibles() {
		try {
			cargandoDisponibles = true;
			
			// Obtener IDs de cursos ya inscritos
			const cursosInscritosIds = cursosInscritos
				.filter(i => i.curso_id)
				.map(i => i.curso_id);
			
			const tutorialesInscritosIds = cursosInscritos
				.filter(i => i.tutorial_id)
				.map(i => i.tutorial_id);

			// Cargar todos los cursos
			const { data: cursosData, error: cursosError } = await supabase
				.from('cursos')
				.select('id, titulo, imagen_url, precio_normal, precio_rebajado, descripcion')
				.order('titulo');

			if (cursosError) {
				console.error('Error al cargar cursos:', cursosError);
			}

			// Filtrar cursos no inscritos y formatear precio
			cursosDisponibles = (cursosData || [])
				.filter((curso: Curso) => !cursosInscritosIds.includes(curso.id))
				.map((curso: Curso) => ({
					...curso,
					precio: curso.precio_rebajado || curso.precio_normal
				}));

			// Cargar todos los tutoriales
			const { data: tutorialesData, error: tutorialesError } = await supabase
				.from('tutoriales')
				.select('id, titulo, imagen_url, duracion, precio_normal, precio_rebajado, descripcion')
				.order('titulo');

			if (tutorialesError) {
				console.error('Error al cargar tutoriales:', tutorialesError);
			}

			// Filtrar tutoriales no inscritos y formatear precio
			tutorialesDisponibles = (tutorialesData || [])
				.filter((tutorial: Tutorial) => !tutorialesInscritosIds.includes(tutorial.id))
				.map((tutorial: Tutorial) => ({
					...tutorial,
					precio: tutorial.precio_rebajado || tutorial.precio_normal
				}));
		} catch (err) {
			console.error('Error al cargar cursos disponibles:', err);
			cursosDisponibles = [];
			tutorialesDisponibles = [];
		} finally {
			cargandoDisponibles = false;
		}
	}

	async function cargarCursosInscritos() {
		try {
			cargandoCursos = true;
			
			// Cargar inscripciones básicas primero
			const { data: inscripciones, error: inscripcionesError } = await supabase
				.from('inscripciones')
				.select('*')
				.eq('usuario_id', usuario.id);

			if (inscripcionesError) throw inscripcionesError;

			cursosInscritos = [];

			// Para cada inscripción, cargar los detalles del curso o tutorial
			for (const inscripcion of inscripciones || []) {
				let detalleCurso = null;
				
				if (inscripcion.curso_id) {
					const { data: curso }: { data: any } = await supabase
						.from('cursos')
						.select('id, titulo, imagen_url, precio_normal, precio_rebajado')
						.eq('id', inscripcion.curso_id)
						.single();
					
					if (curso) {
						detalleCurso = { 
							...curso, 
							tipo: 'curso',
							precio: curso.precio_rebajado || curso.precio_normal
						};
					}
				} else if (inscripcion.tutorial_id) {
					const { data: tutorial }: { data: any } = await supabase
						.from('tutoriales')
						.select('id, titulo, imagen_url, duracion, precio_normal, precio_rebajado')
						.eq('id', inscripcion.tutorial_id)
						.single();
					
					if (tutorial) {
						detalleCurso = { 
							...tutorial, 
							tipo: 'tutorial',
							precio: tutorial.precio_rebajado || tutorial.precio_normal
						};
					}
				}

				if (detalleCurso) {
					cursosInscritos.push({
						...inscripcion,
						curso: detalleCurso
					});
				}
			}
		} catch (err) {
			console.error('Error al cargar cursos inscritos:', err);
			cursosInscritos = [];
		} finally {
			cargandoCursos = false;
		}
	}

	async function cargarHistorialPagos() {
		try {
			cargandoPagos = true;
			const { data, error } = await supabase
				.from('pagos_epayco')
				.select('*')
				.eq('usuario_id', usuario.id)
				.order('fecha_transaccion', { ascending: false })
				.limit(10);

			if (error) throw error;
			historialPagos = data || [];
		} catch (err) {
			console.error('Error al cargar pagos:', err);
			historialPagos = [];
		} finally {
			cargandoPagos = false;
		}
	}

	async function cargarEstadisticasActividad() {
		try {
			cargandoActividad = true;
			// Aquí puedes implementar consultas para obtener estadísticas de actividad
			// Por ahora, datos de ejemplo
			estadisticasActividad = {
				tiempoTotal: Math.floor(Math.random() * 1000) + 100,
				sesionesHoy: Math.floor(Math.random() * 5) + 1,
				ultimaActividad: new Date().toISOString(),
				paginasFavoritas: [
					{ pagina: '/cursos', visitas: 45 },
					{ pagina: '/mi-perfil', visitas: 23 },
					{ pagina: '/tutoriales', visitas: 18 }
				]
			};
		} catch (err) {
			console.error('Error al cargar actividad:', err);
		} finally {
			cargandoActividad = false;
		}
	}

	function cerrar() {
		dispatch('cerrar');
	}

	function cambiarPestana(pestana: string) {
		pestanaActiva = pestana;
	}

	function activarEdicion() {
		editando = true;
		datosEditables = { ...usuario };
	}

	function cancelarEdicion() {
		editando = false;
		datosEditables = { ...usuario };
		error = '';
	}

	async function guardarCambios() {
		try {
			cargando = true;
			error = '';

			// Construir nombre completo
			const nombreCompleto = `${datosEditables.nombre || ''} ${datosEditables.apellido || ''}`.trim();

			const { error: updateError } = await supabase
				.from('perfiles')
				.update({
					nombre: datosEditables.nombre,
					apellido: datosEditables.apellido,
					nombre_completo: nombreCompleto,
					correo_electronico: datosEditables.correo_electronico,
					rol: datosEditables.rol,
					suscripcion: datosEditables.suscripcion,
					ciudad: datosEditables.ciudad,
					pais: datosEditables.pais,
					whatsapp: datosEditables.whatsapp,
					nivel_habilidad: datosEditables.nivel_habilidad,
					documento_numero: datosEditables.documento_numero,
					profesion: datosEditables.profesion,
					fecha_actualizacion: new Date().toISOString()
				})
				.eq('id', usuario.id);

			if (updateError) throw updateError;

			// Actualizar usuario local con nombre completo actualizado
			usuario = { 
				...usuario,
				...datosEditables, 
				nombre_completo: nombreCompleto,
				fecha_actualizacion: new Date().toISOString()
			};
			editando = false;
			exito = true;

			setTimeout(() => {
				exito = false;
			}, 3000);

			console.log('📤 Enviando usuario actualizado desde guardarCambios:', usuario);
			dispatch('usuarioActualizado', usuario);
		} catch (err: any) {
			error = `Error al actualizar: ${err.message}`;
		} finally {
			cargando = false;
		}
	}

	async function eliminarUsuario() {
		if (!confirm('¿Estás seguro de que quieres eliminar este usuario? Esta acción no se puede deshacer.')) {
			return;
		}

		try {
			cargando = true;
			const { error: deleteError } = await supabase
				.from('perfiles')
				.update({ eliminado: true })
				.eq('id', usuario.id);

			if (deleteError) throw deleteError;

			dispatch('usuarioEliminado', usuario.id);
		} catch (err: any) {
			error = `Error al eliminar: ${err.message}`;
		} finally {
			cargando = false;
		}
	}

	async function toggleCurso(cursoId: string, tipo: 'curso' | 'tutorial', accion: 'agregar' | 'quitar') {
		try {
			if (accion === 'agregar') {
				const { error } = await supabase
					.from('inscripciones')
					.insert({
						usuario_id: usuario.id,
						[tipo === 'curso' ? 'curso_id' : 'tutorial_id']: cursoId,
						fecha_inscripcion: new Date().toISOString(),
						estado: 'activo'
					});
				if (error) throw error;
			} else {
				const { error } = await supabase
					.from('inscripciones')
					.delete()
					.eq('usuario_id', usuario.id)
					.eq(tipo === 'curso' ? 'curso_id' : 'tutorial_id', cursoId);
				if (error) throw error;
			}

			await Promise.all([cargarCursosInscritos(), cargarCursosDisponibles()]);
		} catch (err: any) {
			error = `Error al ${accion} ${tipo}: ${err.message}`;
		}
	}

	// Funciones para Drag & Drop
	function handleDragStart(event: DragEvent, item: any, tipo: 'curso' | 'tutorial') {
		draggedItem = item;
		draggedType = tipo;
		event.dataTransfer!.effectAllowed = 'move';
	}

	function handleDragOver(event: DragEvent) {
		event.preventDefault();
		event.dataTransfer!.dropEffect = 'move';
	}

	async function handleDrop(event: DragEvent) {
		event.preventDefault();
		if (draggedItem && draggedType) {
			await toggleCurso(draggedItem.id, draggedType, 'agregar');
			draggedItem = null;
		}
	}

	// Función para cambiar membresía
	async function cambiarMembresia(nuevaMembresia: string) {
		try {
			cargando = true;
			const { error: updateError } = await supabase
				.from('perfiles')
				.update({ 
					suscripcion: nuevaMembresia,
					fecha_actualizacion: new Date().toISOString()
				})
				.eq('id', usuario.id);

			if (updateError) throw updateError;

			usuario = { 
				...usuario,
				suscripcion: nuevaMembresia,
				fecha_actualizacion: new Date().toISOString()
			};
			mostrarGestionMembresia = false;
			exito = true;

			setTimeout(() => {
				exito = false;
			}, 3000);

			console.log('📤 Enviando usuario actualizado desde cambiarMembresia:', usuario);
			dispatch('usuarioActualizado', usuario);
		} catch (err: any) {
			error = `Error al cambiar membresía: ${err.message}`;
		} finally {
			cargando = false;
		}
	}

	// Filtrar cursos por búsqueda
	$: cursosDisponiblesFiltrados = cursosDisponibles.filter(curso =>
		curso.titulo.toLowerCase().includes(busquedaCursos.toLowerCase())
	);

	$: tutorialesDisponiblesFiltrados = tutorialesDisponibles.filter(tutorial =>
		tutorial.titulo.toLowerCase().includes(busquedaCursos.toLowerCase())
	);

	function formatearFecha(fecha: string) {
		return new Date(fecha).toLocaleDateString('es-ES', {
			year: 'numeric',
			month: 'long',
			day: 'numeric'
		});
	}

	function formatearPrecio(precio: number | string) {
		const numero = typeof precio === 'string' ? parseFloat(precio) : precio;
		return new Intl.NumberFormat('es-CO', {
			style: 'currency',
			currency: 'COP',
			minimumFractionDigits: 0
		}).format(numero);
	}
</script>

<div class="detalle-usuario">
	<div class="header-detalle">
		<div class="info-header">
			<div class="avatar-grande">
				{#if usuario.url_foto_perfil}
					<img src={usuario.url_foto_perfil} alt={usuario.nombre_completo || `${usuario.nombre || ''} ${usuario.apellido || ''}`.trim()} />
				{:else}
					<div class="avatar-iniciales">
						{(editando ? datosEditables.nombre : usuario.nombre)?.charAt(0) || ''}{(editando ? datosEditables.apellido : usuario.apellido)?.charAt(0) || ''}
					</div>
				{/if}
			</div>
			<div class="info-basica">
				<h2>{usuario.nombre_completo || `${usuario.nombre || ''} ${usuario.apellido || ''}`.trim() || 'Usuario'}</h2>
				<p class="correo">{usuario.correo_electronico}</p>
				<div class="badges">
					<span class="badge badge-{usuario.rol}">{usuario.rol}</span>
					<span class="badge badge-{usuario.suscripcion}">{usuario.suscripcion}</span>
					<span class="badge badge-{usuario.eliminado ? 'eliminado' : 'activo'}">
						{usuario.eliminado ? 'Eliminado' : 'Activo'}
					</span>
				</div>
			</div>
		</div>
		<div class="acciones-header">
			{#if !editando}
				<button class="btn-editar" on:click={activarEdicion}>
					<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
						<path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" fill="currentColor"/>
					</svg>
					Editar
				</button>
			{/if}
			<button class="btn-cerrar" on:click={cerrar}>×</button>
		</div>
	</div>

	{#if error}
		<div class="error">
			<svg width="20" height="20" viewBox="0 0 24 24" fill="none">
				<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" fill="currentColor"/>
			</svg>
			{error}
		</div>
	{/if}

	{#if exito}
		<div class="exito">
			<svg width="20" height="20" viewBox="0 0 24 24" fill="none">
				<path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" stroke="currentColor" stroke-width="2"/>
			</svg>
			Usuario actualizado exitosamente
		</div>
	{/if}

	<div class="pestanas">
		<button 
			class="pestana" 
			class:activa={pestanaActiva === 'personal'}
			on:click={() => cambiarPestana('personal')}
		>
			<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
				<path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" fill="currentColor"/>
			</svg>
			Información Personal
		</button>
		<button 
			class="pestana" 
			class:activa={pestanaActiva === 'cursos'}
			on:click={() => cambiarPestana('cursos')}
		>
			<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
				<path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z" fill="currentColor"/>
			</svg>
			Cursos y Progreso
		</button>
		<button 
			class="pestana" 
			class:activa={pestanaActiva === 'pagos'}
			on:click={() => cambiarPestana('pagos')}
		>
			<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
				<path d="M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 14H4v-6h16v6zm0-10H4V6h16v2z" fill="currentColor"/>
			</svg>
			Pagos y Membresía
		</button>
		<button 
			class="pestana" 
			class:activa={pestanaActiva === 'actividad'}
			on:click={() => cambiarPestana('actividad')}
		>
			<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
				<path d="M9 11H7v6h2v-6zm4 0h-2v6h2v-6zm4 0h-2v6h2v-6zm2.5-9H19V1h-2v1H7V1H5v1H4.5C3.12 2 2 3.12 2 4.5v15C2 20.88 3.12 22 4.5 22h15c1.38 0 2.5-1.12 2.5-2.5v-15C22 3.12 20.88 2 19.5 2z" fill="currentColor"/>
			</svg>
			Actividad
		</button>
	</div>

	<div class="contenido-pestanas">
		{#if pestanaActiva === 'personal'}
			<div class="pestana-contenido">
				<div class="seccion">
					<h3>Información Básica</h3>
					<div class="campos-grid">
						<div class="campo">
							<label>Nombre:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.nombre} />
							{:else}
								<span>{usuario.nombre || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Apellido:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.apellido} />
							{:else}
								<span>{usuario.apellido || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Correo:</label>
							{#if editando}
								<input type="email" bind:value={datosEditables.correo_electronico} />
							{:else}
								<span>{usuario.correo_electronico}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Rol:</label>
							{#if editando}
								<select bind:value={datosEditables.rol}>
									<option value="estudiante">Estudiante</option>
									<option value="profesor">Profesor</option>
									<option value="admin">Administrador</option>
								</select>
							{:else}
								<span class="badge badge-{usuario.rol}">{usuario.rol}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Suscripción:</label>
							{#if editando}
								<select bind:value={datosEditables.suscripcion}>
									<option value="free">Gratuita</option>
									<option value="basic">Básica</option>
									<option value="premium">Premium</option>
									<option value="pro">Profesional</option>
								</select>
							{:else}
								<span class="badge badge-{usuario.suscripcion}">{usuario.suscripcion}</span>
							{/if}
						</div>
					</div>
				</div>

				<div class="seccion">
					<h3>Información Adicional</h3>
					<div class="campos-grid">
						<div class="campo">
							<label>Ciudad:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.ciudad} />
							{:else}
								<span>{usuario.ciudad || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>País:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.pais} />
							{:else}
								<span>{usuario.pais || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>WhatsApp:</label>
							{#if editando}
								<input type="tel" bind:value={datosEditables.whatsapp} />
							{:else}
								<span>{usuario.whatsapp || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Nivel de Habilidad:</label>
							{#if editando}
								<select bind:value={datosEditables.nivel_habilidad}>
									<option value="">Seleccionar...</option>
									<option value="principiante">Principiante</option>
									<option value="intermedio">Intermedio</option>
									<option value="avanzado">Avanzado</option>
									<option value="experto">Experto</option>
								</select>
							{:else}
								<span>{usuario.nivel_habilidad || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Documento:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.documento_numero} />
							{:else}
								<span>{usuario.documento_numero || 'No especificado'}</span>
							{/if}
						</div>
						<div class="campo">
							<label>Profesión:</label>
							{#if editando}
								<input type="text" bind:value={datosEditables.profesion} />
							{:else}
								<span>{usuario.profesion || 'No especificado'}</span>
							{/if}
						</div>
					</div>
				</div>

				<div class="seccion">
					<h3>Fechas Importantes</h3>
					<div class="campos-grid">
						<div class="campo">
							<label>Fecha de Registro:</label>
							<span>{formatearFecha(usuario.fecha_creacion)}</span>
						</div>
						<div class="campo">
							<label>Última Actualización:</label>
							<span>{formatearFecha(usuario.fecha_actualizacion)}</span>
						</div>
					</div>
				</div>

				{#if editando}
					<div class="acciones-edicion">
						<button class="btn-cancelar" on:click={cancelarEdicion} disabled={cargando}>
							Cancelar
						</button>
						<button class="btn-guardar" on:click={guardarCambios} disabled={cargando}>
							{cargando ? 'Guardando...' : 'Guardar Cambios'}
						</button>
					</div>
				{:else}
					<div class="acciones-usuario">
						<button class="btn-eliminar" on:click={eliminarUsuario} disabled={cargando}>
							Eliminar Usuario
						</button>
					</div>
				{/if}
			</div>
		{/if}

		{#if pestanaActiva === 'cursos'}
			<div class="pestana-contenido">
				<!-- Zona de Drop para cursos -->
				<div 
					class="zona-drop"
					on:dragover={handleDragOver}
					on:drop={handleDrop}
					role="region"
					aria-label="Zona para arrastrar cursos"
				>
					<div class="seccion">
						<div class="header-seccion">
							<h3>Cursos y Tutoriales Inscritos</h3>
							<button 
								class="btn-agregar-cursos"
								on:click={() => mostrarAgregarCursos = !mostrarAgregarCursos}
							>
								<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
									<path d="M12 2v20M2 12h20" stroke="currentColor" stroke-width="2"/>
								</svg>
								{mostrarAgregarCursos ? 'Cerrar' : 'Agregar Cursos'}
							</button>
						</div>
						
						{#if cargandoCursos}
							<div class="cargando">Cargando cursos...</div>
						{:else if cursosInscritos.length === 0}
							<div class="vacio">
								<svg width="48" height="48" viewBox="0 0 24 24" fill="none">
									<path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z" fill="currentColor"/>
								</svg>
								<p>Este usuario no tiene cursos inscritos</p>
								<small>💡 Arrastra cursos desde la sección "Agregar Cursos" o usa el botón "Agregar Cursos"</small>
							</div>
						{:else}
							<div class="lista-cursos">
								{#each cursosInscritos as inscripcion}
									<div class="curso-item">
										<div class="curso-imagen">
											{#if inscripcion.curso}
												<img src={inscripcion.curso.imagen_url} alt={inscripcion.curso.titulo} />
											{/if}
										</div>
										<div class="curso-info">
											<h4>
												{inscripcion.curso?.titulo || 'Curso sin título'}
											</h4>
											<p class="tipo">
												{inscripcion.curso?.tipo === 'curso' ? '📚 Curso' : '🎯 Tutorial'}
												{#if inscripcion.curso?.precio}
													- {formatearPrecio(inscripcion.curso.precio)}
												{/if}
											</p>
											<p class="fecha">
												Inscrito: {formatearFecha(inscripcion.fecha_inscripcion)}
											</p>
											<span class="estado estado-{inscripcion.estado || 'activo'}">
												{inscripcion.estado || 'activo'}
											</span>
										</div>
										<div class="curso-acciones">
											<button 
												class="btn-quitar"
												on:click={() => toggleCurso(
													inscripcion.curso?.id,
													inscripcion.curso?.tipo,
													'quitar'
												)}
											>
												Quitar
											</button>
										</div>
									</div>
								{/each}
							</div>
						{/if}
					</div>
				</div>

				<!-- Panel para agregar cursos -->
				{#if mostrarAgregarCursos}
					<div class="seccion seccion-agregar">
						<h3>Agregar Cursos y Tutoriales</h3>
						
						<!-- Buscador -->
						<div class="buscador-cursos">
							<svg width="20" height="20" viewBox="0 0 24 24" fill="none">
								<path d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z" stroke="currentColor" stroke-width="2"/>
							</svg>
							<input 
								type="text" 
								placeholder="Buscar cursos y tutoriales..."
								bind:value={busquedaCursos}
							/>
						</div>

						{#if cargandoDisponibles}
							<div class="cargando">Cargando cursos disponibles...</div>
						{:else}
							<!-- Cursos disponibles -->
							{#if cursosDisponiblesFiltrados.length > 0}
								<div class="categoria-cursos">
									<h4>📚 Cursos Disponibles</h4>
									<div class="grid-cursos-disponibles">
										{#each cursosDisponiblesFiltrados as curso}
											<div 
												class="curso-disponible"
												draggable="true"
												on:dragstart={(e) => handleDragStart(e, curso, 'curso')}
												role="button"
												aria-label="Arrastrar curso {curso.titulo}"
											>
												<div class="curso-imagen-mini">
													<img src={curso.imagen_url} alt={curso.titulo} />
												</div>
												<div class="curso-info-mini">
													<h5>{curso.titulo}</h5>
													<p class="precio">{formatearPrecio(curso.precio)}</p>
												</div>
												<button 
													class="btn-agregar-curso"
													on:click={() => toggleCurso(curso.id, 'curso', 'agregar')}
													aria-label="Agregar curso"
												>
													<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
														<path d="M12 2v20M2 12h20" stroke="currentColor" stroke-width="2"/>
													</svg>
												</button>
											</div>
										{/each}
									</div>
								</div>
							{/if}

							<!-- Tutoriales disponibles -->
							{#if tutorialesDisponiblesFiltrados.length > 0}
								<div class="categoria-cursos">
									<h4>🎯 Tutoriales Disponibles</h4>
									<div class="grid-cursos-disponibles">
										{#each tutorialesDisponiblesFiltrados as tutorial}
											<div 
												class="curso-disponible"
												draggable="true"
												on:dragstart={(e) => handleDragStart(e, tutorial, 'tutorial')}
												role="button"
												aria-label="Arrastrar tutorial {tutorial.titulo}"
											>
												<div class="curso-imagen-mini">
													<img src={tutorial.imagen_url} alt={tutorial.titulo} />
												</div>
												<div class="curso-info-mini">
													<h5>{tutorial.titulo}</h5>
													<p class="duracion">⏱️ {tutorial.duracion} min</p>
													{#if tutorial.precio}
														<p class="precio">{formatearPrecio(tutorial.precio)}</p>
													{/if}
												</div>
												<button 
													class="btn-agregar-curso"
													on:click={() => toggleCurso(tutorial.id, 'tutorial', 'agregar')}
													aria-label="Agregar tutorial"
												>
													<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
														<path d="M12 2v20M2 12h20" stroke="currentColor" stroke-width="2"/>
													</svg>
												</button>
											</div>
										{/each}
									</div>
								</div>
							{/if}

							{#if cursosDisponiblesFiltrados.length === 0 && tutorialesDisponiblesFiltrados.length === 0}
								<div class="vacio">
									<svg width="48" height="48" viewBox="0 0 24 24" fill="none">
										<path d="m19 19-4-4m0-7A7 7 0 1 1 1 8a7 7 0 0 1 14 0Z" stroke="currentColor" stroke-width="2"/>
									</svg>
									<p>No se encontraron cursos disponibles</p>
									{#if busquedaCursos}
										<small>Intenta con otro término de búsqueda</small>
									{:else}
										<small>El usuario ya está inscrito en todos los cursos disponibles</small>
									{/if}
								</div>
							{/if}
						{/if}
					</div>
				{/if}
			</div>
		{/if}

		{#if pestanaActiva === 'pagos'}
			<div class="pestana-contenido">
				<!-- Gestión de Membresía -->
				<div class="seccion seccion-membresia">
					<div class="header-seccion">
						<h3>Gestión de Membresía</h3>
						<button 
							class="btn-cambiar-membresia"
							on:click={() => mostrarGestionMembresia = !mostrarGestionMembresia}
						>
							<svg width="16" height="16" viewBox="0 0 24 24" fill="none">
								<path d="M12 1L3 5l9 4 9-4-9-4zM3 5v14l9 4 9-4V5" stroke="currentColor" stroke-width="2"/>
							</svg>
							Cambiar Membresía
						</button>
					</div>

					<div class="membresia-actual">
						<div class="membresia-info">
							<div class="membresia-icon">
								{#if usuario.suscripcion === 'premium'}
									👑
								{:else if usuario.suscripcion === 'pro'}
									⭐
								{:else}
									🎓
								{/if}
							</div>
							<div class="membresia-detalles">
								<h4>Membresía Actual</h4>
								<p class="tipo-membresia">{usuario.suscripcion}</p>
								<p class="fecha-desde">Desde: {formatearFecha(usuario.fecha_creacion)}</p>
							</div>
						</div>
					</div>

					{#if mostrarGestionMembresia}
						<div class="selector-membresia">
							<h4>Seleccionar Nueva Membresía</h4>
							<div class="opciones-membresia">
								{#each ['gratis', 'basico', 'premium', 'pro', 'vip'] as tipoMembresia}
									<button
										class="opcion-membresia"
										class:activa={usuario.suscripcion === tipoMembresia}
										on:click={() => cambiarMembresia(tipoMembresia)}
										disabled={usuario.suscripcion === tipoMembresia || cargando}
									>
										<div class="membresia-icon">
											{#if tipoMembresia === 'premium'}
												👑
											{:else if tipoMembresia === 'pro'}
												⭐
											{:else if tipoMembresia === 'vip'}
												💎
											{:else if tipoMembresia === 'basico'}
												📚
											{:else}
												🎓
											{/if}
										</div>
										<span>{tipoMembresia}</span>
									</button>
								{/each}
							</div>
						</div>
					{/if}
				</div>

				<!-- Historial de Pagos -->
				<div class="seccion">
					<h3>Historial de Pagos</h3>
					
					{#if cargandoPagos}
						<div class="cargando">Cargando historial de pagos...</div>
					{:else if historialPagos.length === 0}
						<div class="vacio">
							<svg width="48" height="48" viewBox="0 0 24 24" fill="none">
								<path d="M20 4H4c-1.11 0-1.99.89-1.99 2L2 18c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V6c0-1.11-.89-2-2-2zm0 14H4v-6h16v6zm0-10H4V6h16v2z" fill="currentColor"/>
							</svg>
							<p>No hay historial de pagos</p>
						</div>
					{:else}
						<div class="lista-pagos">
							{#each historialPagos as pago}
								<div class="pago-item">
									<div class="pago-info">
										<h4>{pago.descripcion || pago.nombre_producto || 'Pago'}</h4>
										<p class="fecha">{formatearFecha(pago.fecha_transaccion || pago.created_at)}</p>
										<p class="referencia">Ref: {pago.ref_payco}</p>
									</div>
									<div class="pago-monto">
										<span class="monto">{formatearPrecio(pago.valor)}</span>
										<span class="estado estado-{pago.estado}">
											{pago.estado}
										</span>
									</div>
								</div>
							{/each}
						</div>
					{/if}
				</div>
			</div>
		{/if}

		{#if pestanaActiva === 'actividad'}
			<div class="pestana-contenido">
				<div class="seccion">
					<h3>Estadísticas de Actividad</h3>
					
					{#if cargandoActividad}
						<div class="cargando">Cargando estadísticas...</div>
					{:else}
						<div class="estadisticas-grid">
							<div class="stat-card">
								<div class="stat-valor">{estadisticasActividad.tiempoTotal}h</div>
								<div class="stat-label">Tiempo Total</div>
							</div>
							<div class="stat-card">
								<div class="stat-valor">{estadisticasActividad.sesionesHoy}</div>
								<div class="stat-label">Sesiones Hoy</div>
							</div>
							<div class="stat-card">
								<div class="stat-valor">
									{estadisticasActividad.ultimaActividad ? formatearFecha(estadisticasActividad.ultimaActividad) : 'N/A'}
								</div>
								<div class="stat-label">Última Actividad</div>
							</div>
						</div>

						<div class="paginas-favoritas">
							<h4>Páginas Más Visitadas</h4>
							{#each estadisticasActividad.paginasFavoritas as pagina}
								<div class="pagina-item">
									<span class="pagina-nombre">{pagina.pagina}</span>
									<span class="pagina-visitas">{pagina.visitas} visitas</span>
								</div>
							{/each}
						</div>
					{/if}
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.detalle-usuario {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 15px;
		color: white;
		max-height: 90vh;
		overflow: hidden;
		display: flex;
		flex-direction: column;
	}

	.header-detalle {
		padding: 30px;
		border-bottom: 1px solid rgba(255, 255, 255, 0.2);
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
	}

	.info-header {
		display: flex;
		gap: 20px;
		align-items: center;
	}

	.avatar-grande {
		width: 80px;
		height: 80px;
		border-radius: 50%;
		overflow: hidden;
		border: 3px solid rgba(255, 255, 255, 0.3);
	}

	.avatar-grande img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.avatar-iniciales {
		width: 100%;
		height: 100%;
		background: linear-gradient(135deg, #667eea, #764ba2);
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 24px;
		font-weight: bold;
		color: white;
	}

	.info-basica h2 {
		margin: 0 0 5px 0;
		font-size: 24px;
		font-weight: 700;
	}

	.correo {
		margin: 0 0 15px 0;
		color: rgba(255, 255, 255, 0.8);
		font-size: 14px;
	}

	.badges {
		display: flex;
		gap: 8px;
		flex-wrap: wrap;
	}

	.badge {
		padding: 4px 12px;
		border-radius: 20px;
		font-size: 12px;
		font-weight: 600;
		text-transform: capitalize;
	}

	.badge-estudiante, .badge-user { background: rgba(33, 150, 243, 0.3); border: 1px solid #2196F3; }
	.badge-admin { background: rgba(244, 67, 54, 0.3); border: 1px solid #f44336; }
	.badge-profesor { background: rgba(255, 152, 0, 0.3); border: 1px solid #ff9800; }
	.badge-free { background: rgba(158, 158, 158, 0.3); border: 1px solid #9e9e9e; }
	.badge-premium { background: rgba(156, 39, 176, 0.3); border: 1px solid #9c27b0; }
	.badge-activo { background: rgba(76, 175, 80, 0.3); border: 1px solid #4CAF50; }
	.badge-eliminado { background: rgba(244, 67, 54, 0.3); border: 1px solid #f44336; }

	.acciones-header {
		display: flex;
		gap: 10px;
		align-items: flex-start;
	}

	.btn-editar {
		background: rgba(102, 126, 234, 0.2);
		border: 1px solid #667eea;
		color: white;
		padding: 8px 16px;
		border-radius: 8px;
		font-size: 14px;
		font-weight: 600;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 8px;
		transition: all 0.3s ease;
	}

	.btn-editar:hover {
		background: rgba(102, 126, 234, 0.3);
	}

	.btn-cerrar {
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.3);
		border-radius: 8px;
		color: white;
		font-size: 18px;
		font-weight: bold;
		padding: 8px 12px;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.btn-cerrar:hover {
		background: rgba(255, 255, 255, 0.2);
	}

	.error {
		background: rgba(244, 67, 54, 0.2);
		border: 1px solid #f44336;
		border-radius: 8px;
		padding: 15px;
		margin: 0 30px 20px 30px;
		color: #ff6b6b;
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.exito {
		background: rgba(76, 175, 80, 0.2);
		border: 1px solid #4CAF50;
		border-radius: 8px;
		padding: 15px;
		margin: 0 30px 20px 30px;
		color: #4CAF50;
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.pestanas {
		display: flex;
		border-bottom: 1px solid rgba(255, 255, 255, 0.2);
		padding: 0 30px;
		gap: 5px;
	}

	.pestana {
		background: none;
		border: none;
		color: rgba(255, 255, 255, 0.7);
		padding: 15px 20px;
		cursor: pointer;
		border-bottom: 2px solid transparent;
		transition: all 0.3s ease;
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 14px;
		font-weight: 500;
	}

	.pestana.activa {
		color: white;
		border-bottom-color: #667eea;
		background: rgba(102, 126, 234, 0.1);
	}

	.pestana:hover:not(.activa) {
		color: rgba(255, 255, 255, 0.9);
		background: rgba(255, 255, 255, 0.05);
	}

	.contenido-pestanas {
		flex: 1;
		overflow-y: auto;
		padding: 30px;
		min-height: 0; /* FIX: Evita el doble scroll en contenedores flex */
	}

	.pestana-contenido {
		display: flex;
		flex-direction: column;
		gap: 30px;
	}

	.seccion {
		background: rgba(255, 255, 255, 0.05);
		border-radius: 12px;
		padding: 25px;
	}

	.seccion h3 {
		margin: 0 0 20px 0;
		font-size: 18px;
		font-weight: 600;
		color: rgba(255, 255, 255, 0.9);
		border-bottom: 1px solid rgba(255, 255, 255, 0.1);
		padding-bottom: 10px;
	}

	.campos-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 20px;
	}

	.campo {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.campo label {
		font-weight: 600;
		font-size: 14px;
		color: rgba(255, 255, 255, 0.9);
	}

	.campo span {
		color: rgba(255, 255, 255, 0.8);
		font-size: 14px;
	}

	.campo input, .campo select {
		padding: 12px 15px;
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.3);
		border-radius: 8px;
		color: white;
		font-size: 14px;
	}

	.campo input:focus, .campo select:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
	}

	.acciones-edicion {
		display: flex;
		gap: 15px;
		justify-content: flex-end;
		padding-top: 20px;
		border-top: 1px solid rgba(255, 255, 255, 0.2);
	}

	.btn-cancelar {
		background: rgba(255, 255, 255, 0.1);
		color: white;
		border: 1px solid rgba(255, 255, 255, 0.3);
		padding: 12px 24px;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.btn-guardar {
		background: linear-gradient(135deg, #667eea, #764ba2);
		color: white;
		border: none;
		padding: 12px 24px;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.acciones-usuario {
		display: flex;
		justify-content: flex-end;
		padding-top: 20px;
		border-top: 1px solid rgba(255, 255, 255, 0.2);
	}

	.btn-eliminar {
		background: rgba(244, 67, 54, 0.2);
		color: #ff6b6b;
		border: 1px solid #f44336;
		padding: 12px 24px;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.btn-eliminar:hover {
		background: rgba(244, 67, 54, 0.3);
	}

	.cargando, .vacio {
		text-align: center;
		padding: 40px;
		color: rgba(255, 255, 255, 0.7);
	}

	.vacio svg {
		opacity: 0.5;
		margin-bottom: 15px;
	}

	.lista-cursos, .lista-pagos {
		display: flex;
		flex-direction: column;
		gap: 15px;
	}

	.curso-item, .pago-item {
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 12px;
		padding: 20px;
		display: flex;
		align-items: center;
		gap: 15px;
	}

	.curso-imagen {
		width: 60px;
		height: 60px;
		border-radius: 8px;
		overflow: hidden;
		flex-shrink: 0;
	}

	.curso-imagen img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.curso-info {
		flex: 1;
	}

	.curso-info h4 {
		margin: 0 0 5px 0;
		font-size: 16px;
		font-weight: 600;
	}

	.curso-info p {
		margin: 0;
		font-size: 14px;
		color: rgba(255, 255, 255, 0.7);
	}

	.tipo {
		font-weight: 500;
		color: rgba(102, 126, 234, 0.8) !important;
	}

	.estado {
		padding: 4px 8px;
		border-radius: 12px;
		font-size: 12px;
		font-weight: 600;
		text-transform: capitalize;
	}

	.estado-activo { background: rgba(76, 175, 80, 0.3); color: #4CAF50; }
	.estado-pendiente { background: rgba(255, 152, 0, 0.3); color: #ff9800; }
	.estado-completado { background: rgba(33, 150, 243, 0.3); color: #2196F3; }

	.btn-quitar {
		background: rgba(244, 67, 54, 0.2);
		color: #ff6b6b;
		border: 1px solid #f44336;
		padding: 8px 16px;
		border-radius: 6px;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.pago-info {
		flex: 1;
	}

	.pago-info h4 {
		margin: 0 0 5px 0;
		font-size: 16px;
		font-weight: 600;
	}

	.pago-monto {
		text-align: right;
	}

	.monto {
		font-size: 18px;
		font-weight: 700;
		color: #4CAF50;
		display: block;
		margin-bottom: 5px;
	}

	.estadisticas-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 20px;
		margin-bottom: 30px;
	}

	.stat-card {
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 12px;
		padding: 20px;
		text-align: center;
	}

	.stat-valor {
		font-size: 24px;
		font-weight: 700;
		color: #667eea;
		margin-bottom: 5px;
	}

	.stat-label {
		font-size: 14px;
		color: rgba(255, 255, 255, 0.7);
	}

	.paginas-favoritas h4 {
		margin: 0 0 15px 0;
		font-size: 16px;
		font-weight: 600;
	}

	.pagina-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 10px 0;
		border-bottom: 1px solid rgba(255, 255, 255, 0.1);
	}

	.pagina-item:last-child {
		border-bottom: none;
	}

	.pagina-nombre {
		font-size: 14px;
		color: rgba(255, 255, 255, 0.9);
	}

	.pagina-visitas {
		font-size: 12px;
		color: rgba(255, 255, 255, 0.7);
	}

	/* ===== NIVEL 2: ESTILOS AVANZADOS ===== */

	/* Header de secciones con botones */
	.header-seccion {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 20px;
	}

	.header-seccion h3 {
		margin: 0;
	}

	/* Botón agregar cursos */
	.btn-agregar-cursos {
		background: rgba(76, 175, 80, 0.2);
		border: 1px solid #4CAF50;
		color: white;
		padding: 8px 16px;
		border-radius: 8px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 8px;
		transition: all 0.3s ease;
		font-size: 14px;
	}

	.btn-agregar-cursos:hover {
		background: rgba(76, 175, 80, 0.3);
		transform: translateY(-1px);
	}

	/* Zona de drop para drag & drop */
	.zona-drop {
		min-height: 200px;
		border: 2px dashed transparent;
		border-radius: 12px;
		transition: all 0.3s ease;
	}

	.zona-drop:hover {
		border-color: rgba(102, 126, 234, 0.5);
		background: rgba(102, 126, 234, 0.05);
	}

	/* Sección para agregar cursos */
	.seccion-agregar {
		background: rgba(33, 150, 243, 0.1);
		border: 1px solid rgba(33, 150, 243, 0.3);
		border-radius: 12px;
		margin-top: 20px;
	}

	/* Buscador de cursos */
	.buscador-cursos {
		position: relative;
		margin-bottom: 20px;
	}

	.buscador-cursos svg {
		position: absolute;
		left: 12px;
		top: 50%;
		transform: translateY(-50%);
		color: rgba(255, 255, 255, 0.5);
	}

	.buscador-cursos input {
		width: 100%;
		padding: 12px 12px 12px 40px;
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 8px;
		color: white;
		font-size: 14px;
	}

	.buscador-cursos input::placeholder {
		color: rgba(255, 255, 255, 0.5);
	}

	/* Categorías de cursos */
	.categoria-cursos {
		margin-bottom: 30px;
	}

	.categoria-cursos h4 {
		margin-bottom: 15px;
		color: rgba(255, 255, 255, 0.9);
		font-size: 16px;
	}

	/* Grid de cursos disponibles */
	.grid-cursos-disponibles {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: 15px;
	}

	/* Curso disponible (draggable) */
	.curso-disponible {
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 10px;
		padding: 15px;
		display: flex;
		align-items: center;
		gap: 12px;
		cursor: grab;
		transition: all 0.3s ease;
	}

	.curso-disponible:hover {
		background: rgba(255, 255, 255, 0.15);
		transform: translateY(-2px);
		box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
	}

	.curso-disponible:active {
		cursor: grabbing;
	}

	.curso-imagen-mini {
		width: 50px;
		height: 50px;
		border-radius: 8px;
		overflow: hidden;
		flex-shrink: 0;
	}

	.curso-imagen-mini img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.curso-info-mini {
		flex: 1;
		min-width: 0;
	}

	.curso-info-mini h5 {
		margin: 0 0 5px 0;
		font-size: 14px;
		font-weight: 600;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.curso-info-mini .precio,
	.curso-info-mini .duracion {
		margin: 0;
		font-size: 12px;
		color: rgba(255, 255, 255, 0.7);
	}

	/* Botón agregar curso individual */
	.btn-agregar-curso {
		background: rgba(76, 175, 80, 0.2);
		border: 1px solid #4CAF50;
		color: white;
		padding: 8px;
		border-radius: 6px;
		cursor: pointer;
		transition: all 0.3s ease;
		flex-shrink: 0;
	}

	.btn-agregar-curso:hover {
		background: rgba(76, 175, 80, 0.3);
		transform: scale(1.1);
	}

	/* ===== GESTIÓN DE MEMBRESÍAS ===== */

	.seccion-membresia {
		background: rgba(156, 39, 176, 0.1);
		border: 1px solid rgba(156, 39, 176, 0.3);
		border-radius: 12px;
		margin-bottom: 20px;
	}

	.btn-cambiar-membresia {
		background: rgba(156, 39, 176, 0.2);
		border: 1px solid #9c27b0;
		color: white;
		padding: 8px 16px;
		border-radius: 8px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 8px;
		transition: all 0.3s ease;
		font-size: 14px;
	}

	.btn-cambiar-membresia:hover {
		background: rgba(156, 39, 176, 0.3);
		transform: translateY(-1px);
	}

	/* Membresía actual */
	.membresia-actual {
		margin-bottom: 20px;
	}

	.membresia-info {
		display: flex;
		align-items: center;
		gap: 15px;
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 10px;
		padding: 20px;
	}

	.membresia-icon {
		font-size: 32px;
		width: 60px;
		height: 60px;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(255, 255, 255, 0.1);
		border-radius: 50%;
	}

	.membresia-detalles h4 {
		margin: 0 0 5px 0;
		font-size: 16px;
		color: rgba(255, 255, 255, 0.9);
	}

	.tipo-membresia {
		margin: 0 0 5px 0;
		font-size: 18px;
		font-weight: 700;
		color: #9c27b0;
		text-transform: capitalize;
	}

	.fecha-desde {
		margin: 0;
		font-size: 12px;
		color: rgba(255, 255, 255, 0.6);
	}

	/* Selector de membresías */
	.selector-membresia {
		border-top: 1px solid rgba(255, 255, 255, 0.2);
		padding-top: 20px;
		margin-top: 20px;
	}

	.selector-membresia h4 {
		margin-bottom: 15px;
		color: rgba(255, 255, 255, 0.9);
	}

	.opciones-membresia {
		display: flex;
		gap: 10px;
		flex-wrap: wrap;
	}

	.opcion-membresia {
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		color: white;
		padding: 12px 16px;
		border-radius: 8px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 8px;
		transition: all 0.3s ease;
		text-transform: capitalize;
	}

	.opcion-membresia:hover:not(:disabled) {
		background: rgba(156, 39, 176, 0.2);
		border-color: #9c27b0;
		transform: translateY(-1px);
	}

	.opcion-membresia.activa {
		background: rgba(156, 39, 176, 0.3);
		border-color: #9c27b0;
	}

	.opcion-membresia:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.opcion-membresia .membresia-icon {
		width: auto;
		height: auto;
		background: none;
		font-size: 16px;
	}

	/* Mejoras en lista de cursos inscritos */
	.curso-item .precio {
		color: #4CAF50;
		font-weight: 600;
	}

	@media (max-width: 768px) {
		.header-detalle {
			flex-direction: column;
			gap: 20px;
			align-items: center;
		}

		.info-header {
			flex-direction: column;
			text-align: center;
			align-items: center;
			width: 100%;
		}

		.badges {
			justify-content: center;
		}

		.campos-grid {
			grid-template-columns: 1fr;
		}

		.pestanas {
			flex-wrap: nowrap;
			overflow-x: auto;
			padding: 20px 15px;
			-ms-overflow-style: none; /* IE and Edge */
			scrollbar-width: none; /* Firefox */
		}
		.pestanas::-webkit-scrollbar {
			display: none; /* Chrome, Safari, Opera */
		}

		.pestana {
			flex-shrink: 0;
		}

		.contenido-pestanas {
			padding: 20px 15px;
		}

		.curso-item, .pago-item {
			flex-direction: column;
			text-align: center;
		}

		.grid-cursos-disponibles {
			grid-template-columns: 1fr;
		}

		.opciones-membresia {
			flex-direction: column;
		}

		.header-seccion {
			flex-direction: column;
			gap: 10px;
			align-items: stretch;
		}
	}
</style> 