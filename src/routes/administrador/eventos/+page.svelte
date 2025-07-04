<script lang="ts">
	import { onMount } from 'svelte';
	import { eventosService, type Evento } from '$lib/services/eventosService';

	// Estados
	let eventos: Evento[] = [];
	let cargando = false;
	let error = '';
	let mostrarFormulario = false;

	// Datos del formulario
	let nuevoEvento = {
		titulo: '',
		descripcion: '',
		descripcion_corta: '',
		tipo_evento: 'masterclass',
		fecha_inicio: '',
		fecha_fin: '',
		modalidad: 'online',
		precio: 0,
		categoria: 'tecnica',
		nivel_dificultad: 'principiante',
		instructor_nombre: '',
		capacidad_maxima: 100,
		requiere_inscripcion: true,
		es_publico: true,
		estado: 'programado',
		link_transmision: '',
		imagen_portada: ''
	};

	onMount(() => {
		cargarEventos();
	});

	async function cargarEventos() {
		cargando = true;
		const resultado = await eventosService.obtenerEventos();
		
		if (resultado.error) {
			error = resultado.error;
		} else {
			eventos = resultado.eventos;
		}
		cargando = false;
	}

	function mostrarFormularioCrear() {
		mostrarFormulario = true;
		// Limpiar formulario
		nuevoEvento = {
			titulo: '',
			descripcion: '',
			descripcion_corta: '',
			tipo_evento: 'masterclass',
			fecha_inicio: '',
			fecha_fin: '',
			modalidad: 'online',
			precio: 0,
			categoria: 'tecnica',
			nivel_dificultad: 'principiante',
			instructor_nombre: '',
			capacidad_maxima: 100,
			requiere_inscripcion: true,
			es_publico: true,
			estado: 'programado',
			link_transmision: '',
			imagen_portada: ''
		};
	}

	function cancelarCreacion() {
		mostrarFormulario = false;
	}

	function generarSlug(titulo: string): string {
		return titulo
			.toLowerCase()
			.replace(/[áàäâ]/g, 'a')
			.replace(/[éèëê]/g, 'e')
			.replace(/[íìïî]/g, 'i')
			.replace(/[óòöô]/g, 'o')
			.replace(/[úùüû]/g, 'u')
			.replace(/[ñ]/g, 'n')
			.replace(/[^a-z0-9\s-]/g, '')
			.replace(/\s+/g, '-')
			.replace(/-+/g, '-')
			.trim();
	}

	async function crearEvento() {
		if (!nuevoEvento.titulo || !nuevoEvento.fecha_inicio) {
			error = 'El título y la fecha de inicio son obligatorios';
			return;
		}

		cargando = true;
		error = '';

		try {
			// Preparar datos según la estructura real de la base de datos
			const eventoData = {
				titulo: nuevoEvento.titulo,
				descripcion: nuevoEvento.descripcion || undefined,
				descripcion_corta: nuevoEvento.descripcion_corta || undefined,
				slug: generarSlug(nuevoEvento.titulo),
				tipo_evento: nuevoEvento.tipo_evento as 'masterclass' | 'workshop' | 'concierto' | 'concurso' | 'webinar' | 'reunion',
				fecha_inicio: nuevoEvento.fecha_inicio,
				fecha_fin: nuevoEvento.fecha_fin || undefined,
				modalidad: nuevoEvento.modalidad as 'online' | 'presencial' | 'hibrido',
				precio: nuevoEvento.precio,
				categoria: nuevoEvento.categoria,
				nivel_dificultad: nuevoEvento.nivel_dificultad as 'principiante' | 'intermedio' | 'avanzado' | 'profesional',
				instructor_nombre: nuevoEvento.instructor_nombre || undefined,
				capacidad_maxima: nuevoEvento.capacidad_maxima,
				requiere_inscripcion: nuevoEvento.requiere_inscripcion,
				es_publico: nuevoEvento.es_publico,
				estado: nuevoEvento.estado as 'borrador' | 'programado' | 'en_vivo' | 'finalizado' | 'cancelado' | 'pospuesto',
				link_transmision: nuevoEvento.link_transmision || undefined,
				imagen_portada: nuevoEvento.imagen_portada || undefined,
				participantes_inscritos: 0,
				total_visualizaciones: 0,
				calificacion_promedio: 0,
				total_calificaciones: 0
			};

			const resultado = await eventosService.crearEvento(eventoData);

			if (resultado.error) {
				error = `Error al crear el evento: ${resultado.error}`;
			} else {
				// Recargar lista de eventos
				await cargarEventos();
				// Ocultar formulario
				mostrarFormulario = false;
				error = '';
			}
		} catch (err: any) {
			error = `Error inesperado: ${err.message}`;
		}

		cargando = false;
	}

	async function eliminarEvento(id: string) {
		if (!confirm('¿Estás seguro de que quieres eliminar este evento?')) {
			return;
		}

		const resultado = await eventosService.eliminarEvento(id);
		
		if (resultado.error) {
			error = resultado.error;
		} else {
			await cargarEventos();
		}
	}

	function formatearFecha(fecha: string): string {
		return new Date(fecha).toLocaleDateString('es-CO', {
			year: 'numeric',
			month: 'long',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function formatearPrecio(precio: number): string {
		if (precio === 0) return 'Gratuito';
		return new Intl.NumberFormat('es-CO', {
			style: 'currency',
			currency: 'COP',
			minimumFractionDigits: 0
		}).format(precio);
	}
</script>

<div class="min-h-screen bg-gray-50 py-6">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- Header -->
		<div class="mb-8">
			<h1 class="text-3xl font-bold text-gray-900">Gestión de Eventos</h1>
			<p class="mt-2 text-gray-600">Administra masterclasses, workshops y otros eventos de la academia</p>
		</div>

		<!-- Error Alert -->
		{#if error}
			<div class="mb-6 bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
				{error}
			</div>
		{/if}

		<!-- Botón para crear evento -->
		{#if !mostrarFormulario}
			<div class="mb-6">
				<button
					on:click={mostrarFormularioCrear}
					class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg font-medium transition-colors inline-flex items-center gap-2"
				>
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/>
					</svg>
					Crear Evento
				</button>
			</div>
		{/if}

		<!-- Formulario de creación -->
		{#if mostrarFormulario}
			<div class="bg-white shadow-sm border border-gray-200 rounded-lg p-6 mb-8">
				<h2 class="text-xl font-semibold text-gray-900 mb-6">Crear Nuevo Evento</h2>
				
				<form on:submit|preventDefault={crearEvento} class="space-y-6">
					<!-- Información básica -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div>
							<label for="titulo" class="block text-sm font-medium text-gray-700 mb-2">
								Título del Evento *
							</label>
							<input
								id="titulo"
								type="text"
								bind:value={nuevoEvento.titulo}
								required
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								placeholder="Ej: Masterclass de Técnicas Avanzadas"
							/>
						</div>

						<div>
							<label for="instructor_nombre" class="block text-sm font-medium text-gray-700 mb-2">
								Nombre del Instructor
							</label>
							<input
								id="instructor_nombre"
								type="text"
								bind:value={nuevoEvento.instructor_nombre}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								placeholder="Nombre completo del instructor"
							/>
						</div>
					</div>

					<!-- Descripción -->
					<div>
						<label for="descripcion_corta" class="block text-sm font-medium text-gray-700 mb-2">
							Descripción Corta
						</label>
						<input
							id="descripcion_corta"
							type="text"
							bind:value={nuevoEvento.descripcion_corta}
							maxlength="500"
							class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							placeholder="Resumen breve del evento"
						/>
					</div>

					<div>
						<label for="descripcion" class="block text-sm font-medium text-gray-700 mb-2">
							Descripción Completa
						</label>
						<textarea
							id="descripcion"
							bind:value={nuevoEvento.descripcion}
							rows="4"
							class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							placeholder="Descripción detallada del evento, objetivos, contenido..."
						></textarea>
					</div>

					<!-- Configuración del evento -->
					<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
						<div>
							<label for="tipo_evento" class="block text-sm font-medium text-gray-700 mb-2">
								Tipo de Evento
							</label>
							<select
								id="tipo_evento"
								bind:value={nuevoEvento.tipo_evento}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							>
								<option value="masterclass">Masterclass</option>
								<option value="workshop">Workshop</option>
								<option value="concierto">Concierto</option>
								<option value="concurso">Concurso</option>
								<option value="webinar">Webinar</option>
								<option value="reunion">Reunión</option>
							</select>
						</div>

						<div>
							<label for="modalidad" class="block text-sm font-medium text-gray-700 mb-2">
								Modalidad
							</label>
							<select
								id="modalidad"
								bind:value={nuevoEvento.modalidad}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							>
								<option value="online">Online</option>
								<option value="presencial">Presencial</option>
								<option value="hibrido">Híbrido</option>
							</select>
						</div>

						<div>
							<label for="categoria" class="block text-sm font-medium text-gray-700 mb-2">
								Categoría
							</label>
							<select
								id="categoria"
								bind:value={nuevoEvento.categoria}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							>
								<option value="tecnica">Técnica</option>
								<option value="teoria">Teoría</option>
								<option value="repertorio">Repertorio</option>
								<option value="historia">Historia</option>
							</select>
						</div>
					</div>

					<!-- Fechas -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div>
							<label for="fecha_inicio" class="block text-sm font-medium text-gray-700 mb-2">
								Fecha y Hora de Inicio *
							</label>
							<input
								id="fecha_inicio"
								type="datetime-local"
								bind:value={nuevoEvento.fecha_inicio}
								required
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							/>
						</div>

						<div>
							<label for="fecha_fin" class="block text-sm font-medium text-gray-700 mb-2">
								Fecha y Hora de Fin
							</label>
							<input
								id="fecha_fin"
								type="datetime-local"
								bind:value={nuevoEvento.fecha_fin}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							/>
						</div>
					</div>

					<!-- Configuración adicional -->
					<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
						<div>
							<label for="nivel_dificultad" class="block text-sm font-medium text-gray-700 mb-2">
								Nivel de Dificultad
							</label>
							<select
								id="nivel_dificultad"
								bind:value={nuevoEvento.nivel_dificultad}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							>
								<option value="principiante">Principiante</option>
								<option value="intermedio">Intermedio</option>
								<option value="avanzado">Avanzado</option>
								<option value="profesional">Profesional</option>
							</select>
						</div>

						<div>
							<label for="capacidad_maxima" class="block text-sm font-medium text-gray-700 mb-2">
								Capacidad Máxima
							</label>
							<input
								id="capacidad_maxima"
								type="number"
								bind:value={nuevoEvento.capacidad_maxima}
								min="1"
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							/>
						</div>

						<div>
							<label for="precio" class="block text-sm font-medium text-gray-700 mb-2">
								Precio (COP)
							</label>
							<input
								id="precio"
								type="number"
								bind:value={nuevoEvento.precio}
								min="0"
								step="1000"
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
							/>
						</div>
					</div>

					<!-- Enlaces -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div>
							<label for="link_transmision" class="block text-sm font-medium text-gray-700 mb-2">
								Link de Transmisión
							</label>
							<input
								id="link_transmision"
								type="url"
								bind:value={nuevoEvento.link_transmision}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								placeholder="https://zoom.us/j/..."
							/>
						</div>

						<div>
							<label for="imagen_portada" class="block text-sm font-medium text-gray-700 mb-2">
								URL de Imagen de Portada
							</label>
							<input
								id="imagen_portada"
								type="url"
								bind:value={nuevoEvento.imagen_portada}
								class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
								placeholder="https://..."
							/>
						</div>
					</div>

					<!-- Opciones -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
						<div class="space-y-3">
							<label class="flex items-center">
								<input
									type="checkbox"
									bind:checked={nuevoEvento.requiere_inscripcion}
									class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
								/>
								<span class="ml-2 text-sm text-gray-700">Requiere Inscripción</span>
							</label>

							<label class="flex items-center">
								<input
									type="checkbox"
									bind:checked={nuevoEvento.es_publico}
									class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
								/>
								<span class="ml-2 text-sm text-gray-700">Evento Público</span>
							</label>
						</div>
					</div>

					<!-- Botones -->
					<div class="flex gap-4 pt-4">
						<button
							type="submit"
							disabled={cargando}
							class="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white px-6 py-2 rounded-lg font-medium transition-colors"
						>
							{cargando ? 'Creando...' : 'Crear Evento'}
						</button>

						<button
							type="button"
							on:click={cancelarCreacion}
							class="bg-gray-300 hover:bg-gray-400 text-gray-700 px-6 py-2 rounded-lg font-medium transition-colors"
						>
							Cancelar
						</button>
					</div>
				</form>
			</div>
		{/if}

		<!-- Lista de eventos -->
		<div class="bg-white shadow-sm border border-gray-200 rounded-lg">
			<div class="px-6 py-4 border-b border-gray-200">
				<h2 class="text-lg font-semibold text-gray-900">Eventos Registrados</h2>
			</div>

			{#if cargando}
				<div class="px-6 py-8 text-center">
					<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
					<p class="mt-2 text-gray-500">Cargando eventos...</p>
				</div>
			{:else if eventos.length === 0}
				<div class="px-6 py-8 text-center text-gray-500">
					<svg class="w-12 h-12 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
					</svg>
					<p>No hay eventos registrados</p>
					<p class="text-sm">Crea tu primer evento usando el botón "Crear Evento"</p>
				</div>
			{:else}
				<div class="overflow-x-auto">
					<table class="w-full">
						<thead class="bg-gray-50">
							<tr>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Evento</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Modalidad</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Precio</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Inscritos</th>
								<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
								<th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
							</tr>
						</thead>
						<tbody class="bg-white divide-y divide-gray-200">
							{#each eventos as evento}
								<tr class="hover:bg-gray-50">
									<td class="px-6 py-4">
										<div>
											<div class="text-sm font-medium text-gray-900">{evento.titulo}</div>
											<div class="text-sm text-gray-500">{evento.tipo_evento} • {evento.categoria}</div>
											{#if evento.instructor_nombre}
												<div class="text-xs text-gray-400">Instructor: {evento.instructor_nombre}</div>
											{/if}
										</div>
									</td>
									<td class="px-6 py-4 text-sm text-gray-900">
										{formatearFecha(evento.fecha_inicio)}
									</td>
									<td class="px-6 py-4">
										<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
											{evento.modalidad === 'online' ? 'bg-blue-100 text-blue-800' : 
											 evento.modalidad === 'presencial' ? 'bg-green-100 text-green-800' : 
											 'bg-purple-100 text-purple-800'}">
											{evento.modalidad}
										</span>
									</td>
									<td class="px-6 py-4 text-sm text-gray-900">
										{formatearPrecio(evento.precio)}
									</td>
									<td class="px-6 py-4 text-sm text-gray-900">
										{evento.participantes_inscritos} / {evento.capacidad_maxima || '∞'}
									</td>
									<td class="px-6 py-4">
										<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
											{evento.estado === 'programado' ? 'bg-yellow-100 text-yellow-800' :
											 evento.estado === 'en_vivo' ? 'bg-red-100 text-red-800' :
											 evento.estado === 'finalizado' ? 'bg-gray-100 text-gray-800' :
											 'bg-gray-100 text-gray-800'}">
											{evento.estado}
										</span>
									</td>
									<td class="px-6 py-4 text-right text-sm font-medium">
										<div class="flex justify-end gap-2">
											<a 
												href="/eventos/{evento.slug}"
												target="_blank"
												class="text-blue-600 hover:text-blue-900 p-1 rounded"
												title="Ver evento"
											>
												<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
													<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
												</svg>
											</a>
											
											<button
												on:click={() => eliminarEvento(evento.id)}
												class="text-red-600 hover:text-red-900 p-1 rounded"
												title="Eliminar evento"
											>
												<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
												</svg>
											</button>
										</div>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</div>
	</div>
</div> 