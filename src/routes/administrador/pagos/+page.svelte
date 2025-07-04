<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase/clienteSupabase';

	let pagos: any[] = [];
	let cargando = true;
	let filtroEstado = 'todos';
	let buscarRef = '';
	// Estados de sincronización
	let sincronizando: Record<string, boolean> = {};
	let mensajesSincronizacion: Record<string, string> = {};
	
	// Estados de confirmación
	let confirmando: Record<string, boolean> = {};
	let mensajesConfirmacion: Record<string, string> = {};
	
	// Estados de diagnóstico
	let diagnosticando: Record<string, boolean> = {};
	let modalDiagnostico = false;
	let datosDiagnostico: any = null;

	// Estados de la UI
	let mostrarFiltros = false;
	let vistaActual = 'tabla'; // 'tabla', 'cards'

	// Estadísticas
	let estadisticas = {
		total: 0,
		aceptada: 0,
		pendiente: 0,
		rechazada: 0,
		fallida: 0,
		valorTotal: 0
	};

	// Variables para procesamiento manual
	let procesandoManual = false;
	let modalProcesamiento = false;
	let resultadoProcesamiento: any = null;

	onMount(() => {
		// Cambiar a vista cards en móviles automáticamente
		if (window.innerWidth < 768) {
			vistaActual = 'cards';
		}
		
		// Listener para cambios de tamaño de ventana
		const handleResize = () => {
			if (window.innerWidth < 768 && vistaActual === 'tabla') {
				vistaActual = 'cards';
			}
		};
		
		window.addEventListener('resize', handleResize);
		
		// Cargar datos de forma asíncrona
		(async () => {
			await verificarRolAdmin();
			await cargarPagos();
		})();
		
		// Cleanup
		return () => {
			window.removeEventListener('resize', handleResize);
		};
	});

	// Función para verificar que el usuario actual es administrador
	async function verificarRolAdmin() {
		try {
			const { data: { user } } = await supabase.auth.getUser();
			console.log('👤 Usuario actual:', user?.email);
			
			if (user) {
				const { data: perfil, error } = await supabase
					.from('perfiles')
					.select('rol, nombre, apellido, correo_electronico')
					.eq('id', user.id)
					.single();

				if (error) {
					console.error('❌ Error obteniendo perfil:', error);
					return;
				}

				console.log('👤 Perfil del usuario:', perfil);
				console.log('🔑 Rol del usuario:', perfil?.rol);

				if (perfil?.rol !== 'admin') {
					console.warn('⚠️ ADVERTENCIA: Usuario no es administrador');
					alert('⚠️ ADVERTENCIA: Tu usuario no tiene permisos de administrador. Es posible que no veas todos los pagos.');
				} else {
					console.log('✅ Usuario confirmado como administrador');
				}
			}
		} catch (error) {
			console.error('❌ Error verificando rol:', error);
		}
	}

	async function cargarPagos() {
		cargando = true;
		try {
			console.log('🔍 Cargando pagos...');
			
			const { data: todosPagos, error: errorTodos } = await supabase
				.from('pagos_epayco')
				.select('*')
				.order('created_at', { ascending: false });

			if (errorTodos) {
				console.error('❌ Error obteniendo pagos:', errorTodos);
				throw errorTodos;
			}

			// Aplicar filtros en JavaScript
			let pagosFiltrados = todosPagos || [];

			if (filtroEstado && filtroEstado !== 'todos' && filtroEstado.trim() !== '') {
				pagosFiltrados = pagosFiltrados.filter((pago: any) => pago.estado === filtroEstado);
			}

			if (buscarRef && buscarRef.trim() !== '') {
				const busqueda = buscarRef.trim().toLowerCase();
				pagosFiltrados = pagosFiltrados.filter((pago: any) => 
					pago.ref_payco && pago.ref_payco.toLowerCase().includes(busqueda)
				);
			}

			// Enriquecer con datos relacionados
			const pagosEnriquecidos = [];
			for (const pago of pagosFiltrados) {
				const pagoEnriquecido = { ...pago };

				if (pago.usuario_id) {
					try {
						const { data: usuario } = await supabase
							.from('perfiles')
							.select('nombre, apellido, correo_electronico')
							.eq('id', pago.usuario_id)
							.single();
						if (usuario) pagoEnriquecido.perfiles = usuario;
					} catch (error) {
						console.log('⚠️ Error obteniendo usuario:', error);
					}
				}

				if (pago.curso_id) {
					try {
						const { data: curso } = await supabase
							.from('cursos')
							.select('titulo')
							.eq('id', pago.curso_id)
							.single();
						if (curso) pagoEnriquecido.cursos = curso;
					} catch (error) {
						console.log('⚠️ Error obteniendo curso:', error);
					}
				}

				if (pago.tutorial_id) {
					try {
						const { data: tutorial } = await supabase
							.from('tutoriales')
							.select('titulo')
							.eq('id', pago.tutorial_id)
							.single();
						if (tutorial) pagoEnriquecido.tutoriales = tutorial;
					} catch (error) {
						console.log('⚠️ Error obteniendo tutorial:', error);
					}
				}

				pagosEnriquecidos.push(pagoEnriquecido);
			}

			pagos = pagosEnriquecidos;
			calcularEstadisticas();

		} catch (error) {
			console.error('💥 Error crítico cargando pagos:', error);
			pagos = [];
		} finally {
			cargando = false;
		}
	}

	function calcularEstadisticas() {
		estadisticas = {
			total: pagos.length,
			aceptada: pagos.filter(p => p.estado === 'aceptada').length,
			pendiente: pagos.filter(p => p.estado === 'pendiente').length,
			rechazada: pagos.filter(p => p.estado === 'rechazada').length,
			fallida: pagos.filter(p => p.estado === 'fallida').length,
			valorTotal: pagos.reduce((sum, p) => sum + (parseFloat(p.valor) || 0), 0)
		};
	}

	async function confirmarPagoManualmente(refPayco: string) {
		confirmando[refPayco] = true;
		mensajesConfirmacion[refPayco] = 'Confirmando...';

		try {
			const response = await fetch('/api/pagos/confirmar', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ 
					ref_payco: refPayco,
					forzar_confirmacion: true 
				})
			});

			const resultado = await response.json();

			if (resultado.success) {
				if (resultado.estado_nuevo === 'aceptada') {
					mensajesConfirmacion[refPayco] = '✅ Pago confirmado e inscripción procesada';
					await cargarPagos();
				} else if (resultado.ya_procesado) {
					mensajesConfirmacion[refPayco] = '✅ El pago ya estaba confirmado';
				} else {
					mensajesConfirmacion[refPayco] = `✅ Estado: ${resultado.estado_nuevo}`;
					await cargarPagos();
				}
			} else {
				mensajesConfirmacion[refPayco] = `❌ Error: ${resultado.error}`;
			}
		} catch (error) {
			console.error('Error confirmando pago:', error);
			mensajesConfirmacion[refPayco] = '❌ Error de conexión';
		} finally {
			confirmando[refPayco] = false;
			setTimeout(() => { mensajesConfirmacion[refPayco] = ''; }, 5000);
		}
	}

	async function cambiarEstadoPago(refPayco: string, nuevoEstado: string) {
		if (!confirm(`¿Estás seguro de cambiar el estado a "${nuevoEstado}"?`)) return;

		try {
			const { error } = await supabase
				.from('pagos_epayco')
				.update({ 
					estado: nuevoEstado,
					updated_at: new Date().toISOString()
				})
				.eq('ref_payco', refPayco);

			if (error) {
				console.error('Error cambiando estado:', error);
				alert('Error al cambiar el estado');
				return;
			}

			if (nuevoEstado === 'aceptada') {
				await inscribirUsuarioManual(refPayco);
			}

			await cargarPagos();
			alert(`Estado cambiado a "${nuevoEstado}" exitosamente`);

		} catch (error) {
			console.error('Error inesperado:', error);
			alert('Error inesperado al cambiar el estado');
		}
	}

	async function revisarPendientes() {
		if (!confirm('¿Quieres revisar todos los pagos pendientes y sincronizarlos con ePayco?')) return;

		try {
			const response = await fetch('/api/pagos/revisar-pendientes');
			const resultado = await response.json();

			if (resultado.success) {
				const stats = resultado.estadisticas;
				let mensaje = `✅ REVISIÓN COMPLETADA\n\n`;
				mensaje += `📊 Estadísticas:\n`;
				mensaje += `• Total revisados: ${stats.total_revisados}\n`;
				mensaje += `• Actualizados: ${stats.actualizados}\n`;
				mensaje += `• Sin cambios: ${stats.sin_cambios}\n`;
				mensaje += `• Errores: ${stats.errores}\n\n`;
				mensaje += `${resultado.mensaje}`;

				alert(mensaje);
				await cargarPagos();
			} else {
				alert(`Error en revisión: ${resultado.error}`);
			}
		} catch (error) {
			console.error('Error revisando pendientes:', error);
			alert('Error ejecutando revisión de pendientes');
		}
	}

	async function inscribirUsuarioManual(refPayco: string) {
		try {
			const { data: pago } = await supabase
				.from('pagos_epayco')
				.select('*')
				.eq('ref_payco', refPayco)
				.single();

			if (!pago) return;

			if (pago.curso_id) {
				await supabase
					.from('inscripciones')
					.upsert({
						usuario_id: pago.usuario_id,
						curso_id: pago.curso_id,
						fecha_inscripcion: new Date().toISOString(),
						completado: false,
						progreso: 0,
						tipo_acceso: 'pagado',
						pago_id: pago.id
					}, { onConflict: 'usuario_id,curso_id' });
			}

			if (pago.tutorial_id) {
				await supabase
					.from('progreso_tutorial')
					.upsert({
						usuario_id: pago.usuario_id,
						tutorial_id: pago.tutorial_id,
						completado: false,
						ultimo_acceso: new Date().toISOString(),
						tiempo_visto: 0,
						fecha_inicio: new Date().toISOString()
					}, { onConflict: 'usuario_id,tutorial_id' });
			}

		} catch (error) {
			console.error('Error inscribiendo usuario:', error);
		}
	}

	function resetearFiltros() {
		filtroEstado = 'todos';
		buscarRef = '';
		cargarPagos();
	}

	function formatearFecha(fecha: string) {
		return new Date(fecha).toLocaleDateString('es-CO', {
			year: 'numeric',
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function formatearValor(valor: number) {
		return new Intl.NumberFormat('es-CO', {
			style: 'currency',
			currency: 'COP',
			minimumFractionDigits: 0
		}).format(valor);
	}

	function obtenerClaseEstado(estado: string) {
		const clases = {
			'aceptada': 'bg-emerald-100 text-emerald-800 border-emerald-200',
			'rechazada': 'bg-red-100 text-red-800 border-red-200',
			'pendiente': 'bg-amber-100 text-amber-800 border-amber-200',
			'fallida': 'bg-red-100 text-red-800 border-red-200',
			'cancelada': 'bg-gray-100 text-gray-800 border-gray-200'
		};
		return clases[estado as keyof typeof clases] || 'bg-gray-100 text-gray-800 border-gray-200';
	}

	function obtenerIconoEstado(estado: string) {
		const iconos = {
			'aceptada': '✅',
			'rechazada': '❌',
			'pendiente': '⏳',
			'fallida': '💥',
			'cancelada': '🚫'
		};
		return iconos[estado as keyof typeof iconos] || '❓';
	}

	function truncarReferencia(ref: string) {
		if (!ref) return '';
		return ref.length > 20 ? `${ref.substring(0, 10)}...${ref.substring(ref.length - 6)}` : ref;
	}

	// Función para procesar pago manualmente
	async function procesarPagoManual(refPayco: string, motivo: string | null = null) {
		procesandoManual = true;
		try {
			const response = await fetch('/api/pagos/procesar-manual', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ 
					ref_payco: refPayco,
					motivo: motivo || 'Pago confirmado manualmente desde diagnóstico - No encontrado en ePayco'
				})
			});
			
			const resultado = await response.json();
			
			if (resultado.success) {
				resultadoProcesamiento = resultado;
				modalProcesamiento = true;
				modalDiagnostico = false; // Cerrar modal de diagnóstico
				
				// Recargar la lista de pagos
				await cargarPagos();
				
				alert(`✅ ¡Éxito! Pago procesado e usuario inscrito correctamente.`);
			} else {
				alert(`❌ Error: ${resultado.error}`);
			}
		} catch (error) {
			console.error('Error:', error);
			alert('❌ Error de conexión al procesar pago');
		} finally {
			procesandoManual = false;
		}
	}
</script>

<div class="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50">
	<!-- Header Principal -->
	<div class="bg-gradient-to-br from-slate-50 to-blue-50 shadow-sm">
		<div class="contenedor-principal">
			<div class="flex flex-col lg:flex-row lg:justify-between lg:items-center py-6 lg:py-8 gap-4">
				<div class="min-w-0 flex-1">
					<h1 class="text-2xl lg:text-4xl font-bold text-gray-900 flex items-center gap-3">
						<div class="w-10 h-10 lg:w-12 lg:h-12 bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
							<span class="text-white text-xl lg:text-2xl">💳</span>
						</div>
						<span class="truncate">Administración de Pagos</span>
					</h1>
					<p class="text-gray-600 mt-2 text-base lg:text-lg">Gestiona y monitorea todas las transacciones de ePayco</p>
				</div>
				
				<!-- Controles de Vista -->
				<div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
					<div class="flex bg-white/80 backdrop-blur-sm rounded-xl p-1 shadow-sm border border-white/20">
						<button
							on:click={() => vistaActual = 'tabla'}
							class="flex-1 sm:flex-none px-3 lg:px-4 py-2 rounded-lg text-sm font-medium transition-all items-center justify-center {vistaActual === 'tabla' ? 'bg-white text-blue-600 shadow-md' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'}"
						>
							📊 Tabla
						</button>
						<button
							on:click={() => vistaActual = 'cards'}
							class="flex-1 sm:flex-none px-3 lg:px-4 py-2 rounded-lg text-sm font-medium transition-all {vistaActual === 'cards' ? 'bg-white text-blue-600 shadow-md' : 'text-gray-600 hover:text-gray-900 hover:bg-white/50'}"
						>
							🃏 Cards
						</button>
					</div>
					
					<button
						on:click={() => mostrarFiltros = !mostrarFiltros}
						class="px-4 py-2 bg-white/80 backdrop-blur-sm text-gray-700 rounded-xl hover:bg-white transition-all flex items-center justify-center gap-2 shadow-sm border border-white/20"
					>
						<span>🔍</span>
						<span class="hidden sm:inline">Filtros</span>
						<span class="transform transition-transform {mostrarFiltros ? 'rotate-180' : ''}">▼</span>
					</button>
				</div>
			</div>
		</div>
	</div>

	<div class="contenedor-principal">
		<!-- Estadísticas -->
		<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 lg:gap-6 mb-8">
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Total Pagos</p>
						<p class="text-2xl font-bold text-gray-900">{estadisticas.total}</p>
					</div>
					<div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
						<span class="text-blue-600 text-xl">📊</span>
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Aceptados</p>
						<p class="text-2xl font-bold text-emerald-600">{estadisticas.aceptada}</p>
					</div>
					<div class="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center">
						<span class="text-emerald-600 text-xl">✅</span>
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Pendientes</p>
						<p class="text-2xl font-bold text-amber-600">{estadisticas.pendiente}</p>
					</div>
					<div class="w-12 h-12 bg-amber-100 rounded-lg flex items-center justify-center">
						<span class="text-amber-600 text-xl">⏳</span>
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Rechazados</p>
						<p class="text-2xl font-bold text-red-600">{estadisticas.rechazada}</p>
					</div>
					<div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
						<span class="text-red-600 text-xl">❌</span>
					</div>
				</div>
			</div>

			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
				<div class="flex items-center justify-between">
					<div>
						<p class="text-sm font-medium text-gray-600">Valor Total</p>
						<p class="text-lg font-bold text-gray-900">{formatearValor(estadisticas.valorTotal)}</p>
					</div>
					<div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
						<span class="text-green-600 text-xl">💰</span>
					</div>
				</div>
			</div>
		</div>

		<!-- Panel de Filtros -->
		{#if mostrarFiltros}
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 lg:p-6 mb-6 lg:mb-8 animate-in slide-in-from-top duration-300">
				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Estado</label>
						<select 
							bind:value={filtroEstado}
							class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
						>
							<option value="todos">Todos los estados</option>
							<option value="aceptada">Aceptada</option>
							<option value="pendiente">Pendiente</option>
							<option value="rechazada">Rechazada</option>
							<option value="fallida">Fallida</option>
							<option value="cancelada">Cancelada</option>
						</select>
					</div>

					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">Buscar Referencia</label>
						<input
							type="text"
							bind:value={buscarRef}
							placeholder="Ingresa referencia..."
							class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
						/>
					</div>

					<div class="flex items-end">
						<button
							on:click={cargarPagos}
							class="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
						>
							🔍 Aplicar Filtros
						</button>
					</div>

					<div class="flex items-end">
						<button
							on:click={resetearFiltros}
							class="w-full px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors"
						>
							🔄 Resetear
						</button>
					</div>
				</div>

				<!-- Botones de Acción -->
				<div class="flex flex-col sm:flex-row flex-wrap gap-3">
					<button
						on:click={cargarPagos}
						class="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 transition-colors flex items-center gap-2"
					>
						<span>📋</span> Ver Todos
					</button>

					<button
						on:click={revisarPendientes}
						class="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors flex items-center gap-2"
					>
						<span>⏰</span> Revisar Pendientes
					</button>
				</div>
			</div>
		{/if}

		<!-- Contenido Principal -->
		{#if cargando}
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
				<div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
				<p class="text-gray-600 text-lg">Cargando pagos...</p>
			</div>
		{:else if pagos.length === 0}
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
				<div class="text-6xl mb-4">😕</div>
				<h3 class="text-xl font-semibold text-gray-900 mb-2">No se encontraron pagos</h3>
				<p class="text-gray-600 mb-6">Esto puede deberse a filtros muy restrictivos o problemas de conexión</p>
				<button
					on:click={cargarPagos}
					class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
				>
					🔄 Intentar Recargar
				</button>
			</div>
		{:else}
			<!-- Vista de Tabla -->
			{#if vistaActual === 'tabla'}
				<!-- Mensaje para móviles -->
				<div class="md:hidden bg-blue-50 border border-blue-200 rounded-xl p-6 text-center mb-6">
					<div class="text-4xl mb-3">📱</div>
					<h3 class="text-lg font-semibold text-blue-900 mb-2">Vista optimizada para móvil</h3>
					<p class="text-blue-700 mb-4">La vista de tabla está optimizada para pantallas más grandes. En móviles recomendamos usar la vista de tarjetas para una mejor experiencia.</p>
					<button
						on:click={() => vistaActual = 'cards'}
						class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
					>
						🃏 Cambiar a Cards
					</button>
				</div>
				
				<!-- Tabla para desktop -->
				<div class="hidden md:block bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
					<div class="overflow-x-auto table-container">
						<table class="min-w-full divide-y divide-gray-200 text-sm">
							<thead class="bg-gray-50">
								<tr>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Referencia
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Usuario
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Producto
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Valor
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Estado
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Fecha
									</th>
									<th class="px-3 lg:px-6 py-3 lg:py-4 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
										Acciones
									</th>
								</tr>
							</thead>
							<tbody class="bg-white divide-y divide-gray-200">
								{#each pagos as pago}
									<tr class="hover:bg-gray-50 transition-colors">
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<div class="text-sm font-mono text-gray-900">{truncarReferencia(pago.ref_payco)}</div>
											{#if pago.metodo_pago}
												<div class="text-xs text-gray-500">{pago.metodo_pago}</div>
											{/if}
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<div class="flex items-center">
												<div class="w-8 h-8 lg:w-10 lg:h-10 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center text-white font-semibold text-xs lg:text-sm mr-2 lg:mr-3">
													{pago.perfiles?.nombre?.charAt(0) || '?'}
												</div>
												<div class="min-w-0 flex-1">
													<div class="text-xs lg:text-sm font-medium text-gray-900 truncate">
														{pago.perfiles?.nombre || 'Sin nombre'} {pago.perfiles?.apellido || ''}
													</div>
													<div class="text-xs text-gray-500 truncate">{pago.perfiles?.correo_electronico || 'Sin email'}</div>
												</div>
											</div>
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<div class="text-xs lg:text-sm text-gray-900">{pago.nombre_producto}</div>
											{#if pago.cursos?.titulo}
												<div class="text-xs text-blue-600">📚 {pago.cursos.titulo}</div>
											{/if}
											{#if pago.tutoriales?.titulo}
												<div class="text-xs text-green-600">🎥 {pago.tutoriales.titulo}</div>
											{/if}
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<div class="text-xs lg:text-sm font-semibold text-gray-900">{formatearValor(pago.valor)}</div>
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<span class="inline-flex items-center px-2 lg:px-2.5 py-0.5 rounded-full text-xs font-medium border {obtenerClaseEstado(pago.estado)}">
												{obtenerIconoEstado(pago.estado)} <span class="hidden sm:inline ml-1">{pago.estado}</span>
											</span>
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap text-xs lg:text-sm text-gray-500">
											{formatearFecha(pago.created_at)}
										</td>
										<td class="px-3 lg:px-6 py-3 lg:py-4 whitespace-nowrap">
											<div class="flex flex-col gap-1 lg:gap-2">
												<div class="flex gap-1">
													<button
														on:click={() => cambiarEstadoPago(pago.ref_payco, 'aceptada')}
														class="px-1.5 lg:px-2 py-1 bg-emerald-600 text-white rounded text-xs hover:bg-emerald-700 transition-colors"
														title="Aceptar pago"
													>
														✅
													</button>
													<button
														on:click={() => cambiarEstadoPago(pago.ref_payco, 'rechazada')}
														class="px-1.5 lg:px-2 py-1 bg-red-600 text-white rounded text-xs hover:bg-red-700 transition-colors"
														title="Rechazar pago"
													>
														❌
													</button>
													<button
														on:click={() => cambiarEstadoPago(pago.ref_payco, 'pendiente')}
														class="px-1.5 lg:px-2 py-1 bg-amber-600 text-white rounded text-xs hover:bg-amber-700 transition-colors"
														title="Marcar pendiente"
													>
														⏳
													</button>
												</div>
												<div class="flex gap-1">
													<button
														class="btn-accion btn-confirmar"
														on:click={() => confirmarPagoManualmente(pago.ref_payco)}
														disabled={confirmando[pago.ref_payco] || pago.estado === 'aceptada'}
													>
														<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M20 6L9 17l-5-5"/></svg>
														{confirmando[pago.ref_payco] ? '...' : (pago.estado === 'aceptada' ? 'Confirmado' : 'Confirmar')}
													</button>
												</div>
											</div>
											{#if mensajesConfirmacion[pago.ref_payco]}
												<div class="text-xs mt-1 {mensajesConfirmacion[pago.ref_payco].includes('✅') ? 'text-emerald-600' : 'text-red-600'}">
													{mensajesConfirmacion[pago.ref_payco]}
												</div>
											{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				</div>
			{/if}

			<!-- Vista de Cards -->
			{#if vistaActual === 'cards'}
				<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 lg:gap-6">
					{#each pagos as pago}
						<div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 lg:p-6 hover:shadow-md transition-all duration-200">
							<!-- Header del Card -->
							<div class="flex justify-between items-start mb-4">
								<div class="flex items-center">
									<div class="w-10 h-10 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center text-white font-semibold text-sm mr-3">
										{pago.perfiles?.nombre?.charAt(0) || '?'}
									</div>
									<div>
										<div class="text-sm font-medium text-gray-900">
											{pago.perfiles?.nombre || 'Sin nombre'} {pago.perfiles?.apellido || ''}
										</div>
										<div class="text-xs text-gray-500">{pago.perfiles?.correo_electronico || 'Sin email'}</div>
									</div>
								</div>
								<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border {obtenerClaseEstado(pago.estado)}">
									{obtenerIconoEstado(pago.estado)} {pago.estado}
								</span>
							</div>

							<!-- Información del Pago -->
							<div class="space-y-3 mb-4">
								<div>
									<p class="text-xs text-gray-500">Referencia</p>
									<p class="text-sm font-mono text-gray-900">{truncarReferencia(pago.ref_payco)}</p>
								</div>
								<div>
									<p class="text-xs text-gray-500">Producto</p>
									<p class="text-sm text-gray-900">{pago.nombre_producto}</p>
									{#if pago.cursos?.titulo}
										<p class="text-xs text-blue-600">📚 {pago.cursos.titulo}</p>
									{/if}
									{#if pago.tutoriales?.titulo}
										<p class="text-xs text-green-600">🎥 {pago.tutoriales.titulo}</p>
									{/if}
								</div>
								<div class="flex justify-between">
									<div>
										<p class="text-xs text-gray-500">Valor</p>
										<p class="text-lg font-semibold text-gray-900">{formatearValor(pago.valor)}</p>
									</div>
									<div class="text-right">
										<p class="text-xs text-gray-500">Fecha</p>
										<p class="text-xs text-gray-900">{formatearFecha(pago.created_at)}</p>
									</div>
								</div>
							</div>

							<!-- Acciones -->
							<div class="border-t border-gray-200 pt-4">
								<div class="flex gap-2 mb-2">
									<button
										on:click={() => cambiarEstadoPago(pago.ref_payco, 'aceptada')}
										class="flex-1 px-3 py-2 bg-emerald-600 text-white rounded-lg text-xs hover:bg-emerald-700 transition-colors"
									>
										✅ Aceptar
									</button>
									<button
										on:click={() => cambiarEstadoPago(pago.ref_payco, 'rechazada')}
										class="flex-1 px-3 py-2 bg-red-600 text-white rounded-lg text-xs hover:bg-red-700 transition-colors"
									>
										❌ Rechazar
									</button>
								</div>
								<div class="flex gap-2 mb-2">
									<button
										class="btn-accion btn-confirmar"
										on:click={() => confirmarPagoManualmente(pago.ref_payco)}
										disabled={confirmando[pago.ref_payco] || pago.estado === 'aceptada'}
									>
										<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M20 6L9 17l-5-5"/></svg>
										{confirmando[pago.ref_payco] ? '...' : (pago.estado === 'aceptada' ? 'Confirmado' : 'Confirmar Manual')}
									</button>
								</div>
								{#if mensajesConfirmacion[pago.ref_payco]}
									<div class="text-xs mt-2 text-center {mensajesConfirmacion[pago.ref_payco].includes('✅') ? 'text-emerald-600' : 'text-red-600'}">
										{mensajesConfirmacion[pago.ref_payco]}
									</div>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{/if}


		{/if}
	</div>
</div>

<!-- Modal de Resultado del Procesamiento Manual -->
{#if modalProcesamiento && resultadoProcesamiento}
<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <!-- Header -->
        <div class="bg-gradient-to-r from-green-600 to-green-700 text-white p-6 rounded-t-lg">
            <div class="flex justify-between items-center">
                <div>
                    <h3 class="text-2xl font-bold">🎉 Procesamiento Completado</h3>
                    <p class="text-green-100 mt-1">Pago aceptado e usuario inscrito exitosamente</p>
                </div>
                <button 
                    on:click={() => modalProcesamiento = false}
                    class="text-white hover:text-green-200 text-2xl font-bold"
                >
                    ✕
                </button>
            </div>
        </div>

        <div class="p-6 space-y-6">
            <!-- RESUMEN DEL PROCESAMIENTO -->
            <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                <h4 class="text-lg font-bold text-green-800 mb-3">✅ Resumen del Procesamiento</h4>
                <div class="space-y-2 text-sm">
                    <p><strong>Mensaje:</strong> {resultadoProcesamiento.mensaje}</p>
                    <p><strong>Fecha:</strong> {new Date(resultadoProcesamiento.detalles.procesamiento.fecha).toLocaleString('es-CO')}</p>
                    <p><strong>Motivo:</strong> {resultadoProcesamiento.detalles.procesamiento.motivo}</p>
                </div>
            </div>

            <!-- INFORMACIÓN DEL PAGO -->
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <h4 class="text-lg font-bold text-blue-800 mb-3">💳 Información del Pago</h4>
                <div class="grid grid-cols-2 gap-4 text-sm">
                    <div><strong>Referencia:</strong> <code class="bg-blue-100 px-1 rounded">{resultadoProcesamiento.detalles.pago.ref_payco}</code></div>
                    <div><strong>Valor:</strong> <span class="font-semibold text-green-600">${resultadoProcesamiento.detalles.pago.valor}</span></div>
                    <div><strong>Estado Anterior:</strong> 
                        <span class="px-2 py-1 rounded text-xs bg-yellow-100 text-yellow-800">
                            {resultadoProcesamiento.detalles.pago.estado_anterior}
                        </span>
                    </div>
                    <div><strong>Estado Nuevo:</strong> 
                        <span class="px-2 py-1 rounded text-xs bg-green-100 text-green-800">
                            {resultadoProcesamiento.detalles.pago.estado_nuevo}
                        </span>
                    </div>
                </div>
            </div>

            <!-- INFORMACIÓN DEL USUARIO -->
            <div class="bg-purple-50 border border-purple-200 rounded-lg p-4">
                <h4 class="text-lg font-bold text-purple-800 mb-3">👤 Usuario Inscrito</h4>
                <div class="space-y-2 text-sm">
                    <p><strong>Nombre:</strong> {resultadoProcesamiento.detalles.usuario.nombre}</p>
                    <p><strong>Email:</strong> {resultadoProcesamiento.detalles.usuario.email}</p>
                </div>
            </div>

            <!-- INFORMACIÓN DE LA INSCRIPCIÓN -->
            {#if resultadoProcesamiento.detalles.inscripcion}
            <div class="bg-orange-50 border border-orange-200 rounded-lg p-4">
                <h4 class="text-lg font-bold text-orange-800 mb-3">📚 Inscripción Realizada</h4>
                <div class="space-y-2 text-sm">
                    <p><strong>Tipo:</strong> {resultadoProcesamiento.detalles.inscripcion.tipo}</p>
                    <p><strong>Título:</strong> {resultadoProcesamiento.detalles.inscripcion.titulo}</p>
                    <p><strong>Acción:</strong> 
                        <span class="px-2 py-1 rounded text-xs bg-green-100 text-green-800">
                            {resultadoProcesamiento.detalles.inscripcion.accion}
                        </span>
                    </p>
                </div>
            </div>
            {:else}
            <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                <h4 class="text-lg font-bold text-yellow-800 mb-3">⚠️ Inscripción</h4>
                <p class="text-yellow-700 text-sm">No se pudo procesar la inscripción automáticamente. Verifique manualmente.</p>
            </div>
            {/if}
        </div>

        <!-- Footer -->
        <div class="bg-gray-50 px-6 py-4 rounded-b-lg flex justify-end">
            <button 
                on:click={() => modalProcesamiento = false}
                class="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg font-semibold"
            >
                Entendido
            </button>
        </div>
    </div>
</div>
{/if}

<style>
	/* Contenedor principal - SIN OVERFLOW HORIZONTAL */
	.contenedor-principal {
		max-width: 1280px;
		margin: 0 auto;
		padding: 1.5rem 1rem;
		width: 100%;
		box-sizing: border-box;
		overflow-x: hidden;
	}

	/* Responsive del contenedor */
	@media (min-width: 640px) {
		.contenedor-principal {
			padding: 1.5rem 1.5rem;
		}
	}

	@media (min-width: 1024px) {
		.contenedor-principal {
			padding: 2rem 2rem;
		}
	}

	/* Tabla responsiva */
	.table-container {
		overflow-x: auto;
		scrollbar-width: thin;
		scrollbar-color: #cbd5e1 #f1f5f9;
	}

	.table-container::-webkit-scrollbar {
		height: 8px;
	}

	.table-container::-webkit-scrollbar-track {
		background: #f1f5f9;
		border-radius: 4px;
	}

	.table-container::-webkit-scrollbar-thumb {
		background: #cbd5e1;
		border-radius: 4px;
	}

	/* Animaciones */
	@keyframes slide-in-from-top {
		from {
			opacity: 0;
			transform: translateY(-10px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}
	
	.animate-in {
		animation: slide-in-from-top 0.3s ease-out;
	}

	.btn-accion {
		/* ... */
	}
	.btn-confirmar {
		background-color: #28a74520;
		color: #28a745;
		border: 1px solid #28a74580;
	}
	.btn-confirmar:hover:not(:disabled) {
		background-color: #28a745;
		color: white;
	}
</style> 