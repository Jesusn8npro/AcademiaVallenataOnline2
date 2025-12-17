<script lang="ts">
	import { onMount } from 'svelte';
	import { fade, slide } from 'svelte/transition';
	import { 
		crearNotificacion,
		notificarNuevoCurso,
		notificarNuevoTutorial,
		notificarPagoAprobado,
		notificarBienvenidaUsuario,
		notificarActualizacionPlataforma,
		notificarPromocionEspecial,
		limpiarNotificacionesExpiradas,
		obtenerEstadisticasNotificaciones,
		type TipoEvento
	} from '$lib/services/generadorNotificaciones';
	import { notificacionesService } from '$lib/services/notificacionesService';

	// Estado
	let cargando = false;
	let mensaje = '';
	let tipoMensaje: 'exito' | 'error' = 'exito';
	let estadisticas: any = null;

	// Formulario de notificación manual
	let formManual = {
		tipo: 'nuevo_curso' as TipoEvento,
		mensaje: '',
		url_accion: '',
		usuario_id: '',
		prioridad: 'normal'
	};

	// Formularios de prueba
	let formCurso = {
		titulo: '',
		descripcion: ''
	};

	let formTutorial = {
		titulo: '',
		descripcion: ''
	};

	let formPago = {
		usuario_id: '',
		monto: 0,
		curso_titulo: ''
	};

	let formPromocion = {
		titulo: '',
		descripcion: '',
		codigo: '',
		fecha_limite: ''
	};

	onMount(async () => {
		await cargarEstadisticas();
	});

	async function cargarEstadisticas() {
		const { exito, estadisticas: stats } = await obtenerEstadisticasNotificaciones();
		if (exito) {
			estadisticas = stats;
		}
	}

	function mostrarMensaje(texto: string, tipo: 'exito' | 'error') {
		mensaje = texto;
		tipoMensaje = tipo;
		setTimeout(() => mensaje = '', 5000);
	}

	// Notificación manual
	async function enviarNotificacionManual() {
		if (!formManual.mensaje.trim()) {
			mostrarMensaje('El mensaje es requerido', 'error');
			return;
		}

		cargando = true;

		const resultado = await crearNotificacion({
			tipo: formManual.tipo,
			mensaje: formManual.mensaje,
			url_accion: formManual.url_accion || undefined,
			usuario_id: formManual.usuario_id || undefined,
			datos_adicionales: { manual: true }
		});

		if (resultado.exito) {
			mostrarMensaje(`✅ Notificación enviada a ${resultado.notificaciones_creadas} usuarios`, 'exito');
			formManual.mensaje = '';
			formManual.url_accion = '';
			formManual.usuario_id = '';
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}

	// Prueba: Nuevo curso
	async function probarNuevoCurso() {
		if (!formCurso.titulo.trim()) {
			mostrarMensaje('El título del curso es requerido', 'error');
			return;
		}

		cargando = true;

		const resultado = await notificarNuevoCurso({
			curso_id: 'curso-demo-' + Date.now(),
			titulo_curso: formCurso.titulo,
			descripcion_curso: formCurso.descripcion || 'Curso de demostración',
			creador_id: 'admin-demo'
		});

		if (resultado.exito) {
			mostrarMensaje(`✅ Notificación de curso enviada a ${resultado.notificaciones_creadas} usuarios`, 'exito');
			formCurso.titulo = '';
			formCurso.descripcion = '';
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}

	// Prueba: Nuevo tutorial
	async function probarNuevoTutorial() {
		if (!formTutorial.titulo.trim()) {
			mostrarMensaje('El título del tutorial es requerido', 'error');
			return;
		}

		cargando = true;

		const resultado = await notificarNuevoTutorial({
			tutorial_id: 'tutorial-demo-' + Date.now(),
			titulo_tutorial: formTutorial.titulo,
			descripcion_tutorial: formTutorial.descripcion || 'Tutorial de demostración',
			creador_id: 'admin-demo'
		});

		if (resultado.exito) {
			mostrarMensaje(`✅ Notificación de tutorial enviada a ${resultado.notificaciones_creadas} usuarios`, 'exito');
			formTutorial.titulo = '';
			formTutorial.descripcion = '';
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}

	// Prueba: Pago aprobado
	async function probarPagoAprobado() {
		if (!formPago.usuario_id.trim() || formPago.monto <= 0) {
			mostrarMensaje('Usuario ID y monto son requeridos', 'error');
			return;
		}

		cargando = true;

		const resultado = await notificarPagoAprobado({
			usuario_id: formPago.usuario_id,
			transaccion_id: 'txn-demo-' + Date.now(),
			monto: formPago.monto,
			curso_titulo: formPago.curso_titulo || undefined
		});

		if (resultado.exito) {
			mostrarMensaje(`✅ Notificación de pago enviada`, 'exito');
			formPago.usuario_id = '';
			formPago.monto = 0;
			formPago.curso_titulo = '';
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}

	// Prueba: Promoción especial
	async function probarPromocionEspecial() {
		if (!formPromocion.titulo.trim()) {
			mostrarMensaje('El título de la promoción es requerido', 'error');
			return;
		}

		cargando = true;

		const resultado = await notificarPromocionEspecial({
			titulo_promocion: formPromocion.titulo,
			descripcion: formPromocion.descripcion || 'Promoción especial de demostración',
			codigo_descuento: formPromocion.codigo || undefined,
			fecha_limite: formPromocion.fecha_limite || undefined
		});

		if (resultado.exito) {
			mostrarMensaje(`✅ Promoción enviada a ${resultado.notificaciones_creadas} usuarios`, 'exito');
			formPromocion.titulo = '';
			formPromocion.descripcion = '';
			formPromocion.codigo = '';
			formPromocion.fecha_limite = '';
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}

	// Limpiar notificaciones expiradas
	async function limpiarExpiradas() {
		if (!confirm('¿Estás seguro de eliminar todas las notificaciones expiradas?')) {
			return;
		}

		cargando = true;

		const resultado = await limpiarNotificacionesExpiradas();

		if (resultado.exito) {
			mostrarMensaje(`🧹 ${resultado.eliminadas} notificaciones expiradas eliminadas`, 'exito');
			await cargarEstadisticas();
		} else {
			mostrarMensaje(`❌ Error: ${resultado.error}`, 'error');
		}

		cargando = false;
	}
</script>

<svelte:head>
	<title>Panel de Notificaciones - Administrador</title>
</svelte:head>

<div class="panel-notificaciones">
	<div class="header-panel">
		<h1>
			<span class="icono">🔔</span>
			Panel de Gestión de Notificaciones
		</h1>
		<p class="descripcion">Gestiona y prueba el sistema de notificaciones de la plataforma</p>
	</div>

	<!-- Mensaje de estado -->
	{#if mensaje}
		<div class="mensaje {tipoMensaje}" transition:slide>
			{mensaje}
		</div>
	{/if}

	<!-- Estadísticas -->
	{#if estadisticas}
		<div class="seccion-estadisticas" transition:fade>
			<h2>📊 Estadísticas de Notificaciones</h2>
			<div class="stats-grid">
				<div class="stat-card">
					<div class="numero">{estadisticas.total}</div>
					<div class="label">Total</div>
				</div>
				<div class="stat-card">
					<div class="numero">{estadisticas.no_leidas}</div>
					<div class="label">Sin leer</div>
				</div>
				<div class="stat-card">
					<div class="numero">{estadisticas.leidas}</div>
					<div class="label">Leídas</div>
				</div>
				<div class="stat-card">
					<div class="numero">{estadisticas.ultimos_30_dias}</div>
					<div class="label">Últimos 30 días</div>
				</div>
			</div>

			<div class="stats-details">
				<div class="stat-section">
					<h3>Por Categoría</h3>
					{#each Object.entries(estadisticas.por_categoria) as [categoria, cantidad]}
						<div class="stat-item">
							<span>{categoria}</span>
							<span>{cantidad}</span>
						</div>
					{/each}
				</div>

				<div class="stat-section">
					<h3>Por Prioridad</h3>
					{#each Object.entries(estadisticas.por_prioridad) as [prioridad, cantidad]}
						<div class="stat-item">
							<span>{prioridad}</span>
							<span>{cantidad}</span>
						</div>
					{/each}
				</div>
			</div>
		</div>
	{/if}

	<div class="contenido-panel">
		<!-- Notificación Manual -->
		<div class="seccion">
			<h2>✍️ Crear Notificación Manual</h2>
			<div class="formulario">
				<div class="campo">
					<label for="tipo">Tipo de Notificación:</label>
					<select id="tipo" bind:value={formManual.tipo}>
						<option value="nuevo_curso">🎓 Nuevo Curso</option>
						<option value="nuevo_tutorial">📹 Nuevo Tutorial</option>
						<option value="nueva_actualizacion_plataforma">🚀 Actualización</option>
						<option value="promocion_especial">🎁 Promoción</option>
						<option value="bienvenida_usuario">👋 Bienvenida</option>
					</select>
				</div>

				<div class="campo">
					<label for="mensaje">Mensaje:</label>
					<textarea 
						id="mensaje" 
						bind:value={formManual.mensaje} 
						placeholder="Escribe el mensaje de la notificación..."
						rows="3"
					></textarea>
				</div>

				<div class="campo">
					<label for="url">URL de Acción (opcional):</label>
					<input 
						id="url" 
						type="text" 
						bind:value={formManual.url_accion} 
						placeholder="/cursos, /blog/articulo-1, etc."
					/>
				</div>

				<div class="campo">
					<label for="usuario">Usuario ID específico (opcional):</label>
					<input 
						id="usuario" 
						type="text" 
						bind:value={formManual.usuario_id} 
						placeholder="Dejar vacío para enviar a todos"
					/>
				</div>

				<button 
					class="boton-enviar" 
					on:click={enviarNotificacionManual} 
					disabled={cargando}
				>
					{cargando ? '⏳ Enviando...' : '📤 Enviar Notificación'}
				</button>
			</div>
		</div>

		<!-- Pruebas Automáticas -->
		<div class="seccion">
			<h2>🧪 Pruebas de Notificaciones Automáticas</h2>
			
			<div class="pruebas-grid">
				<!-- Nuevo Curso -->
				<div class="prueba-card">
					<h3>🎓 Nuevo Curso</h3>
					<div class="formulario-mini">
						<input 
							type="text" 
							bind:value={formCurso.titulo} 
							placeholder="Título del curso"
						/>
						<input 
							type="text" 
							bind:value={formCurso.descripcion} 
							placeholder="Descripción"
						/>
						<button 
							class="boton-prueba" 
							on:click={probarNuevoCurso} 
							disabled={cargando}
						>
							Probar
						</button>
					</div>
				</div>

				<!-- Nuevo Tutorial -->
				<div class="prueba-card">
					<h3>📹 Nuevo Tutorial</h3>
					<div class="formulario-mini">
						<input 
							type="text" 
							bind:value={formTutorial.titulo} 
							placeholder="Título del tutorial"
						/>
						<input 
							type="text" 
							bind:value={formTutorial.descripcion} 
							placeholder="Descripción"
						/>
						<button 
							class="boton-prueba" 
							on:click={probarNuevoTutorial} 
							disabled={cargando}
						>
							Probar
						</button>
					</div>
				</div>

				<!-- Pago Aprobado -->
				<div class="prueba-card">
					<h3>✅ Pago Aprobado</h3>
					<div class="formulario-mini">
						<input 
							type="text" 
							bind:value={formPago.usuario_id} 
							placeholder="ID del usuario"
						/>
						<input 
							type="number" 
							bind:value={formPago.monto} 
							placeholder="Monto"
						/>
						<input 
							type="text" 
							bind:value={formPago.curso_titulo} 
							placeholder="Título del curso (opcional)"
						/>
						<button 
							class="boton-prueba" 
							on:click={probarPagoAprobado} 
							disabled={cargando}
						>
							Probar
						</button>
					</div>
				</div>

				<!-- Promoción Especial -->
				<div class="prueba-card">
					<h3>🎁 Promoción Especial</h3>
					<div class="formulario-mini">
						<input 
							type="text" 
							bind:value={formPromocion.titulo} 
							placeholder="Título de la promoción"
						/>
						<input 
							type="text" 
							bind:value={formPromocion.descripcion} 
							placeholder="Descripción"
						/>
						<input 
							type="text" 
							bind:value={formPromocion.codigo} 
							placeholder="Código de descuento"
						/>
						<input 
							type="date" 
							bind:value={formPromocion.fecha_limite}
						/>
						<button 
							class="boton-prueba" 
							on:click={probarPromocionEspecial} 
							disabled={cargando}
						>
							Probar
						</button>
					</div>
				</div>
			</div>
		</div>

		<!-- Herramientas de Gestión -->
		<div class="seccion">
			<h2>🛠️ Herramientas de Gestión</h2>
			<div class="herramientas">
				<button 
					class="boton-herramienta limpiar" 
					on:click={limpiarExpiradas} 
					disabled={cargando}
				>
					🧹 Limpiar Notificaciones Expiradas
				</button>

				<button 
					class="boton-herramienta actualizar" 
					on:click={cargarEstadisticas} 
					disabled={cargando}
				>
					🔄 Actualizar Estadísticas
				</button>

				<a href="/notificaciones" class="boton-herramienta ver">
					👀 Ver Mis Notificaciones
				</a>
			</div>
		</div>
	</div>
</div>

<style>
.panel-notificaciones {
	max-width: 1200px;
	margin: 0 auto;
	padding: 2rem;
	font-family: 'Inter', sans-serif;
}

.header-panel {
	text-align: center;
	margin-bottom: 3rem;
}

.header-panel h1 {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 0.5rem;
	font-size: 2.5rem;
	font-weight: 700;
	color: #1e293b;
	margin: 0 0 1rem 0;
}

.icono {
	font-size: 2.5rem;
}

.descripcion {
	color: #64748b;
	font-size: 1.1rem;
	margin: 0;
}

.mensaje {
	padding: 1rem 1.5rem;
	border-radius: 12px;
	margin-bottom: 2rem;
	font-weight: 600;
}

.mensaje.exito {
	background: linear-gradient(135deg, #dcfce7, #bbf7d0);
	color: #166534;
	border-left: 4px solid #22c55e;
}

.mensaje.error {
	background: linear-gradient(135deg, #fef2f2, #fecaca);
	color: #b91c1c;
	border-left: 4px solid #ef4444;
}

.seccion-estadisticas {
	background: white;
	border-radius: 16px;
	padding: 2rem;
	margin-bottom: 2rem;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
}

.seccion-estadisticas h2 {
	margin: 0 0 1.5rem 0;
	color: #1e293b;
}

.stats-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
	gap: 1rem;
	margin-bottom: 2rem;
}

.stat-card {
	background: linear-gradient(135deg, #f8fafc, #e2e8f0);
	border-radius: 12px;
	padding: 1.5rem;
	text-align: center;
}

.stat-card .numero {
	font-size: 2rem;
	font-weight: 700;
	color: #3b82f6;
	line-height: 1;
}

.stat-card .label {
	color: #64748b;
	font-size: 0.875rem;
	margin-top: 0.5rem;
}

.stats-details {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
	gap: 2rem;
}

.stat-section h3 {
	margin: 0 0 1rem 0;
	color: #374151;
	font-size: 1.1rem;
}

.stat-item {
	display: flex;
	justify-content: space-between;
	padding: 0.5rem 0;
	border-bottom: 1px solid #f1f5f9;
}

.contenido-panel {
	display: grid;
	gap: 2rem;
}

.seccion {
	background: white;
	border-radius: 16px;
	padding: 2rem;
	box-shadow: 0 4px 25px rgba(0, 0, 0, 0.08);
}

.seccion h2 {
	margin: 0 0 1.5rem 0;
	color: #1e293b;
	font-size: 1.5rem;
}

.formulario {
	display: grid;
	gap: 1.5rem;
}

.campo {
	display: grid;
	gap: 0.5rem;
}

.campo label {
	font-weight: 600;
	color: #374151;
}

.campo input,
.campo textarea,
.campo select {
	padding: 0.75rem;
	border: 2px solid #e5e7eb;
	border-radius: 8px;
	font-size: 1rem;
	transition: all 0.3s ease;
}

.campo input:focus,
.campo textarea:focus,
.campo select:focus {
	outline: none;
	border-color: #3b82f6;
	box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.boton-enviar {
	background: linear-gradient(135deg, #3b82f6, #1d4ed8);
	color: white;
	border: none;
	padding: 1rem 2rem;
	border-radius: 12px;
	font-size: 1rem;
	font-weight: 600;
	cursor: pointer;
	transition: all 0.3s ease;
}

.boton-enviar:hover:not(:disabled) {
	transform: translateY(-2px);
	box-shadow: 0 8px 25px rgba(59, 130, 246, 0.3);
}

.boton-enviar:disabled {
	opacity: 0.6;
	cursor: not-allowed;
}

.pruebas-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
	gap: 1.5rem;
}

.prueba-card {
	background: #f8fafc;
	border-radius: 12px;
	padding: 1.5rem;
	border: 2px solid #e2e8f0;
}

.prueba-card h3 {
	margin: 0 0 1rem 0;
	color: #1e293b;
	font-size: 1.1rem;
}

.formulario-mini {
	display: grid;
	gap: 0.75rem;
}

.formulario-mini input {
	padding: 0.5rem;
	border: 1px solid #d1d5db;
	border-radius: 6px;
	font-size: 0.875rem;
}

.boton-prueba {
	background: #10b981;
	color: white;
	border: none;
	padding: 0.5rem 1rem;
	border-radius: 6px;
	font-size: 0.875rem;
	font-weight: 600;
	cursor: pointer;
	transition: all 0.3s ease;
}

.boton-prueba:hover:not(:disabled) {
	background: #059669;
}

.herramientas {
	display: flex;
	gap: 1rem;
	flex-wrap: wrap;
}

.boton-herramienta {
	padding: 0.75rem 1.5rem;
	border-radius: 10px;
	font-weight: 600;
	text-decoration: none;
	cursor: pointer;
	transition: all 0.3s ease;
	display: inline-flex;
	align-items: center;
	gap: 0.5rem;
}

.boton-herramienta.limpiar {
	background: #fef2f2;
	color: #dc2626;
	border: 2px solid #fecaca;
}

.boton-herramienta.limpiar:hover {
	background: #dc2626;
	color: white;
}

.boton-herramienta.actualizar {
	background: #eff6ff;
	color: #2563eb;
	border: 2px solid #dbeafe;
}

.boton-herramienta.actualizar:hover {
	background: #2563eb;
	color: white;
}

.boton-herramienta.ver {
	background: #f0fdf4;
	color: #16a34a;
	border: 2px solid #dcfce7;
}

.boton-herramienta.ver:hover {
	background: #16a34a;
	color: white;
}

@media (max-width: 768px) {
	.panel-notificaciones {
		padding: 1rem;
	}

	.header-panel h1 {
		font-size: 2rem;
		flex-direction: column;
		gap: 0.25rem;
	}

	.pruebas-grid {
		grid-template-columns: 1fr;
	}

	.stats-grid {
		grid-template-columns: repeat(2, 1fr);
	}

	.stats-details {
		grid-template-columns: 1fr;
	}

	.herramientas {
		flex-direction: column;
	}
}
</style> 