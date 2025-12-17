<script lang="ts">
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';
	import { goto } from '$app/navigation';
	import { audioManager, TipoEfectoUI } from '$lib/components/SimuladorDefinitivo/audio/AudioManager';
	import { sistemaCanciones } from '$lib/components/SimuladorDefinitivo/SimuladorDeAcordeonJS/SistemaCanciones.js';
	// FondoEspacial ya está en +layout.svelte - no duplicar import
	import BotonInicio from '$lib/components/SimuladorDefinitivo/components/ui/BotonInicio.svelte';
	import Modal from '$lib/components/SimuladorDefinitivo/components/ui/Modal.svelte';
	
	let pestaña_activa = 'canciones';
	let cancionSeleccionada: any = null;
	let mostrarModalSugerencias = false;
	let canciones: any[] = [];
	let cancionesPersonalizadas: any[] = [];
	let cancionesDelSistema: any[] = [];
	
	// Cargar canciones del sistema
	onMount(async () => {
		if (browser) {
			// console.log('🎵 Iniciando carga de canciones...');
			
			// Esperar un poquito para que el DOM esté listo
			await new Promise(resolve => setTimeout(resolve, 100));
			
			// Verificar localStorage directamente
			const cancionesEnStorage = localStorage.getItem('cancionesPersonalizadas');
			// console.log('📱 Contenido directo de localStorage:', cancionesEnStorage);
			
			// Forzar recarga de canciones personalizadas
			// console.log('🔄 Forzando recarga de canciones personalizadas...');
			sistemaCanciones.cargarCancionesPersonalizadas();
			
			// Esperar un momento y recargar
			await new Promise(resolve => setTimeout(resolve, 50));
			
			cargarTodasLasCanciones();
			
			// Auto-actualizar cada 2 segundos las primeras 3 veces por si acaso
			for (let i = 0; i < 3; i++) {
				setTimeout(() => {
					// console.log(`🔄 Auto-actualización ${i + 1}/3`);
					cargarTodasLasCanciones();
				}, (i + 1) * 2000);
			}
		}
	});
	
	function cargarTodasLasCanciones() {
		// console.log('📂 Cargando todas las canciones...');
		
		// Obtener todas las canciones
		const todasLasCanciones = sistemaCanciones.obtenerTodasLasCanciones();
		// console.log(`📊 Total de canciones encontradas: ${todasLasCanciones.length}`);
		
		// Debug: mostrar todas las canciones con sus metadatos
		todasLasCanciones.forEach(cancion => {
			// console.log(`🎵 ${cancion.titulo} - Creador: ${cancion.metadatos?.creador}, EsPersonalizada: ${cancion.metadatos?.esPersonalizada}, ID: ${cancion.id}`);
		});
		
		// Separar canciones personalizadas y del sistema con filtro más amplio
		cancionesPersonalizadas = todasLasCanciones.filter(cancion => {
			return cancion.metadatos?.creador === 'Editor' || 
				   cancion.metadatos?.esPersonalizada === true ||
				   cancion.id.includes('cancion_') ||
				   cancion.metadatos?.guardadoAutomatico === true;
		});
		
		cancionesDelSistema = todasLasCanciones.filter(cancion => {
			return !(cancion.metadatos?.creador === 'Editor' || 
					 cancion.metadatos?.esPersonalizada === true ||
					 cancion.id.includes('cancion_') ||
					 cancion.metadatos?.guardadoAutomatico === true);
		});
		
		// console.log(`👤 Canciones personalizadas encontradas: ${cancionesPersonalizadas.length}`);
		// console.log(`🎼 Canciones del sistema encontradas: ${cancionesDelSistema.length}`);
		
		// Mostrar detalles de las canciones personalizadas
		cancionesPersonalizadas.forEach(cancion => {
			// console.log(`✨ Personalizada: ${cancion.titulo} (${cancion.notas?.length || 0} notas)`);
		});
		
		// Combinar todas las canciones (personalizadas primero)
		canciones = [...cancionesPersonalizadas, ...cancionesDelSistema];
		
		// Agregar imagen por defecto si no tienen una
		canciones = canciones.map(cancion => ({
			...cancion,
			imagen: cancion.imagen || '/Acordeon PRO MAX.png',
			descripcion: cancion.descripcion || `Canción ${cancion.genero} de ${cancion.artista}`
		}));
		
		// console.log(`✅ Carga completa. Total canciones: ${canciones.length}`);
	}
	
	// Pestañas disponibles (exactas de Rhythm Plus)
	const pestañas = [
		{ id: 'canciones', nombre: 'Canciones Interactivas', icono: '🎵' },
		{ id: 'cursos', nombre: 'Cursos Interactivos', icono: '📚' },
		{ id: 'ejercicios', nombre: 'Ejercicios', icono: '🎯' },
		{ id: 'lecciones', nombre: 'Lecciones', icono: '📖' },
		{ id: 'trucos', nombre: 'Trucos', icono: '🎪' },
		{ id: 'armonia', nombre: 'Armonía', icono: '🎹' }
	];
	
	// Función para cambiar pestaña (exacta de Rhythm Plus)
	function cambiarPestaña(nuevaPestaña: string) {
		if (nuevaPestaña === pestaña_activa) return;
		
		// Efecto de sonido de cambio de pestaña
		audioManager.reproducirEfectoUI(TipoEfectoUI.SLIDE_2);
		
		pestaña_activa = nuevaPestaña;
		cancionSeleccionada = null;
	}
	
	// Función para hover en pestañas (exacta de Rhythm Plus)
	function hoverPestaña() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.HOVER_NAVEGACION);
	}
	
	// Función para hover en canciones (exacta de Rhythm Plus)
	function hoverCancion() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.PROFUNDO);
	}
	
	// Función para click en canción (exacta de Rhythm Plus)
	function clickCancion(cancion: any) {
		audioManager.reproducirEfectoUI(TipoEfectoUI.POP);
		cancionSeleccionada = cancion;
	}
	
	// Función para cerrar detalle
	function cerrarDetalle() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.SLIDE_1);
		cancionSeleccionada = null;
	}
	
	// Función para empezar juego
	function empezarJuego() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
		if (cancionSeleccionada) {
			// Redirigir al juego con la canción seleccionada
			setTimeout(() => {
				    goto(`/simulador-gaming/seleccion-canciones`);
			}, 100);
		} else {
			// Si no hay canción seleccionada, ir al simulador
			setTimeout(() => {
				goto('/simulador-gaming/simulador');
			}, 100);
		}
	}
	
	// Función para ir al editor
	function irAlEditor() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
		setTimeout(() => {
			    		// Editor Max removido - redirigir a editor interactivo
		goto('/simulador-gaming/editor-interactivo');
		}, 100);
	}
	
	// Función para actualizar la lista de canciones
	function actualizarCanciones() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
		
		// console.log('🔄 Actualizando lista de canciones manualmente...');
		
		// Verificar localStorage directamente otra vez
		const cancionesEnStorage = localStorage.getItem('cancionesPersonalizadas');
		// console.log('📱 Verificando localStorage:', cancionesEnStorage ? 'Hay datos' : 'No hay datos');
		
		if (cancionesEnStorage) {
			const cancionesParseadas = JSON.parse(cancionesEnStorage);
			// console.log(`📱 Canciones en localStorage: ${cancionesParseadas.length}`);
			cancionesParseadas.forEach((cancion: any) => {
				// console.log(`📱 En storage: ${cancion.titulo} (ID: ${cancion.id})`);
			});
		}
		
		// Forzar recarga completa del sistema
		sistemaCanciones.cargarCancionesPersonalizadas();
		
		// Usar la función unificada
		cargarTodasLasCanciones();
		
		// console.log('✅ Actualización manual completada');
	}
	
	// Función para abrir modal de sugerencias
	function abrirModalSugerencias() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.CLICK_BOTON);
		mostrarModalSugerencias = true;
	}
	
	// Función para cerrar modal de sugerencias
	function cerrarModalSugerencias() {
		audioManager.reproducirEfectoUI(TipoEfectoUI.MODAL_CERRAR);
		mostrarModalSugerencias = false;
	}
	
	// Función de debug completo
	function debugCompleto() {
		// console.log('🔍 INICIANDO DEBUG COMPLETO...');
		
		// 1. Verificar localStorage
		const storage = localStorage.getItem('cancionesPersonalizadas');
		// console.log('📱 localStorage RAW:', storage);
		
		if (storage) {
			try {
				const parsed = JSON.parse(storage);
				// console.log('📱 localStorage PARSEADO:', parsed);
				// console.log(`📱 Cantidad en localStorage: ${parsed.length}`);
			} catch (e) {
				console.error('❌ Error parseando localStorage:', e);
			}
		}
		
		// 2. Verificar sistema de canciones
		const todasEnSistema = sistemaCanciones.obtenerTodasLasCanciones();
		// console.log('🎵 Canciones en sistema:', todasEnSistema.length);
		todasEnSistema.forEach((cancion: any, index: number) => {
			// console.log(`${index + 1}. ${cancion.titulo} - ID: ${cancion.id} - Creador: ${cancion.metadatos?.creador}`);
		});
		
		// 3. Forzar recarga total
		// console.log('🔄 Forzando recarga total...');
		sistemaCanciones.cargarCancionesPersonalizadas();
		cargarTodasLasCanciones();
		
		// console.log('✅ DEBUG COMPLETO TERMINADO');
		alert('🔍 Debug completo ejecutado. Revisa la consola para más detalles.');
	}
</script>

<svelte:head>
	<title>Selección de Canciones - Simulador 2.0</title>
	<meta name="description" content="Selecciona tu canción favorita para practicar en el simulador de acordeón." />
</svelte:head>

<!-- FondoEspacial renderizado desde +layout.svelte -->

<main class="contenedor-principal">
	<!-- Título -->
	<div class="titulo-pagina">Selección de Canciones</div>
	
		<!-- Pestañas (exactas de Rhythm Plus) -->
		<div class="contenedor-pestanas">
			<div class="pestanas">
				{#each pestañas as pestaña}
					<div
						class="pestana {pestaña_activa === pestaña.id ? 'activa' : ''}"
						on:click={() => cambiarPestaña(pestaña.id)}
						on:mouseenter={hoverPestaña}
					>
						<span class="icono-pestana">{pestaña.icono}</span>
						<span class="texto-pestana">{pestaña.nombre}</span>
					</div>
				{/each}
			</div>
		</div>
		
		<!-- Contenido principal -->
		<div class="contenido-principal">
			<!-- Lista de canciones -->
			<div class="contenedor-lista {cancionSeleccionada ? 'lista-colapsada' : ''}">
				<div class="lista-canciones">
					<!-- Mensaje informativo -->
					<div class="mensaje-info">
						<p>💡 ¿Acabas de crear una canción en el editor? Usa el botón "Actualizar Lista" para verla aquí.</p>
						<p>🔄 Si recargas la página y no aparecen tus canciones, presiona "Actualizar Lista".</p>
					</div>
											{#if pestaña_activa === 'canciones'}
						
						<!-- Sección de canciones personalizadas -->
						{#if cancionesPersonalizadas.length > 0}
							<div class="subtitulo">🎵 Tus Canciones Personalizadas ({cancionesPersonalizadas.length})</div>
							
							{#each cancionesPersonalizadas as cancion}
								<div 
									class="tarjeta-cancion cancion-personalizada"
									on:click={() => clickCancion(cancion)}
									on:mouseenter={hoverCancion}
								>
									<div class="imagen-cancion">
										<img src={cancion.imagen} alt={cancion.titulo} loading="lazy" />
									</div>
									<div class="info-cancion">
										<div class="titulo-cancion">{cancion.titulo}</div>
										<div class="artista-cancion">{cancion.artista}</div>
										<div class="detalles-cancion">
											<span class="genero">{cancion.genero}</span>
											<span class="dificultad">{cancion.dificultad}</span>
											<span class="duracion">{cancion.duracion}s</span>
											<span class="notas">{cancion.notas?.length || 0} notas</span>
										</div>
									</div>
									<div class="badge-personalizada">✨ Personalizada</div>
								</div>
							{/each}
						{:else}
							<div class="mensaje-vacio">
								<p>🎵 No tienes canciones personalizadas aún.</p>
								<p>¡Crea tu primera canción usando el editor!</p>
							</div>
						{/if}
						
						<!-- Botón para crear canción -->
						<div class="boton-accion boton-grande" on:click={irAlEditor} on:mouseenter={hoverCancion}>
							<div class="icono-boton">➕</div>
							<div class="texto-boton">Crear Nueva Canción</div>
						</div>
						
						<!-- Botón para actualizar lista -->
						<div class="boton-accion boton-grande" on:click={actualizarCanciones} on:mouseenter={hoverCancion}>
							<div class="icono-boton">🔄</div>
							<div class="texto-boton">Actualizar Lista</div>
						</div>
						
						<!-- Botón de debug -->
						<div class="boton-accion boton-debug" on:click={debugCompleto} on:mouseenter={hoverCancion}>
							<div class="icono-boton">🔍</div>
							<div class="texto-boton">Debug Completo</div>
						</div>
						
						<!-- Sección de canciones del sistema -->
						{#if cancionesDelSistema.length > 0}
							<div class="subtitulo">🎼 Canciones Incluidas ({cancionesDelSistema.length})</div>
							
							{#each cancionesDelSistema as cancion}
								<div 
									class="tarjeta-cancion"
									on:click={() => clickCancion(cancion)}
									on:mouseenter={hoverCancion}
															>
								<div class="imagen-cancion">
									<img src={cancion.imagen} alt={cancion.titulo} loading="lazy" />
								</div>
									<div class="info-cancion">
										<div class="titulo-cancion">{cancion.titulo}</div>
										<div class="artista-cancion">{cancion.artista}</div>
										<div class="detalles-cancion">
											<span class="genero">{cancion.genero}</span>
											<span class="dificultad">{cancion.dificultad}</span>
											<span class="duracion">{cancion.duracion}s</span>
											<span class="notas">{cancion.notas?.length || 0} notas</span>
										</div>
									</div>
								</div>
							{/each}
						{/if}
						
						<!-- Botón tutorial -->
						<div class="boton-accion boton-grande" on:click={() => goto('/simulador-gaming/simulador')} on:mouseenter={hoverCancion}>
							<div class="icono-boton">❓</div>
							<div class="texto-boton">Simulador Libre</div>
						</div>
						
						<!-- Botón para sugerir canción -->
						<div class="boton-accion boton-grande" on:click={abrirModalSugerencias} on:mouseenter={hoverCancion}>
							<div class="icono-boton">💡</div>
							<div class="texto-boton">Sugerir una Canción</div>
						</div>
					{:else}
						<div class="subtitulo">Próximamente</div>
						<div class="mensaje-construccion">
							<div class="icono-construccion">🚧</div>
							<div>Esta sección estará disponible próximamente</div>
						</div>
					{/if}
				</div>
			</div>
			
			<!-- Panel de detalles -->
			<div class="panel-detalle {!cancionSeleccionada ? 'detalle-colapsado' : ''}">
				{#if cancionSeleccionada}
					<div class="detalle-cancion">
						<div class="cabecera-detalle">
							<div class="imagen-detalle">
								<img src={cancionSeleccionada.imagen} alt={cancionSeleccionada.titulo} />
							</div>
							<div class="info-detalle">
								<h2>{cancionSeleccionada.titulo}</h2>
								<p class="artista-detalle">{cancionSeleccionada.artista}</p>
								<div class="etiquetas-detalle">
									<span class="etiqueta genero">{cancionSeleccionada.genero}</span>
									<span class="etiqueta dificultad">{cancionSeleccionada.dificultad}</span>
									<span class="etiqueta duracion">{cancionSeleccionada.duracion}s</span>
									{#if cancionSeleccionada.notas}
										<span class="etiqueta notas">{cancionSeleccionada.notas.length} notas</span>
									{/if}
									{#if cancionSeleccionada.metadatos?.esPersonalizada}
										<span class="etiqueta personalizada">✨ Personalizada</span>
									{/if}
								</div>
							</div>
							<button class="boton-cerrar" on:click={cerrarDetalle}>✕</button>
						</div>
						
						<div class="descripcion-cancion">
							<p>{cancionSeleccionada.descripcion}</p>
						</div>
						
						<div class="opciones-juego">
							<h3>Selecciona Dificultad o Presiona Jugar</h3>
							<div class="dificultades">
								<div class="dificultad-item">
									<span class="nivel">Nivel 1 - {cancionSeleccionada.dificultad}</span>
									<span class="notas">{cancionSeleccionada.duracion}</span>
									<span class="teclas">Acordeón Diatónico</span>
								</div>
							</div>
							
							<div class="botones-accion">
								<button class="boton-jugar" on:click={empezarJuego}>
									¡JUGAR!
								</button>
								<button class="boton-cancelar" on:click={cerrarDetalle}>
									Cancelar
								</button>
							</div>
						</div>
					</div>
				{/if}
			</div>
		</div>
	</main>
	
	<!-- Modal para sugerencias de canciones -->
	{#if mostrarModalSugerencias}
		<Modal 
			titulo="Sugerir una Canción"
			mostrar={mostrarModalSugerencias}
			on:cerrar={cerrarModalSugerencias}
		>
			<div class="contenido-modal">
				<p>¿Tienes una canción favorita que te gustaría ver en el simulador?</p>
				<p>¡Cuéntanos cuál es y la consideraremos para futuras actualizaciones!</p>
				
				<div class="formulario-sugerencia">
					<label>
						<span>Nombre de la canción:</span>
						<input type="text" placeholder="Ej: La Pollera Colorá" />
					</label>
					
					<label>
						<span>Artista:</span>
						<input type="text" placeholder="Ej: José Barros" />
					</label>
					
					<label>
						<span>Género:</span>
						<select>
							<option value="">Selecciona un género</option>
							<option value="vallenato">Vallenato</option>
							<option value="cumbia">Cumbia</option>
							<option value="merengue">Merengue</option>
							<option value="porro">Porro</option>
							<option value="pasillo">Pasillo</option>
							<option value="vals">Vals</option>
						</select>
					</label>
					
					<label>
						<span>Comentarios adicionales:</span>
						<textarea placeholder="Cuéntanos por qué te gusta esta canción o cualquier detalle adicional..."></textarea>
					</label>
					
					<div class="botones-modal">
						<button class="boton-enviar" on:click={cerrarModalSugerencias}>
							Enviar Sugerencia
						</button>
						<button class="boton-cancelar-modal" on:click={cerrarModalSugerencias}>
							Cancelar
						</button>
					</div>
				</div>
			</div>
		</Modal>
	{/if}

<style>
	.contenedor-principal {
		position: fixed;
		width: 100%;
		height: 100%;
		top: 0;
		left: 0;
		overflow-y: auto;
		padding-top: 80px;
	}
	
	.titulo-pagina {
		font-size: 2.5rem;
		font-weight: bold;
		color: white;
		text-align: center;
		margin-bottom: 40px;
		text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
	}
	
	.contenedor-pestanas {
		display: flex;
		justify-content: center;
		margin-bottom: 40px;
		max-width: 1200px;
		margin-left: auto;
		margin-right: auto;
		padding: 0 20px;
	}
	
	.pestanas {
		display: flex;
		flex-wrap: wrap;
		gap: 10px;
		justify-content: center;
	}
	
	.pestana {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 12px 24px;
		background: rgba(255, 255, 255, 0.1);
		border: 2px solid rgba(255, 255, 255, 0.2);
		border-radius: 25px;
		color: white;
		cursor: pointer;
		transition: all 0.3s ease;
		font-weight: 500;
		white-space: nowrap;
	}
	
	.pestana:hover {
		background: rgba(255, 255, 255, 0.2);
		transform: translateY(-2px);
		box-shadow: 0 4px 20px rgba(255, 255, 255, 0.1);
	}
	
	.pestana.activa {
		background: linear-gradient(135deg, #ff6b6b, #4ecdc4);
		border-color: #ff6b6b;
		color: white;
	}
	
	.icono-pestana {
		font-size: 1.2em;
	}
	
	.contenido-principal {
		display: flex;
		gap: 40px;
		max-width: 1200px;
		margin: 0 auto;
		padding: 0 20px;
		height: calc(100vh - 300px);
	}
	
	.contenedor-lista {
		flex: 1;
		transition: all 0.3s ease;
	}
	
	.lista-colapsada {
		flex: 0.4;
	}
	
	.lista-canciones {
		height: 100%;
		overflow-y: auto;
		padding-right: 20px;
	}
	
	.subtitulo {
		font-size: 1.5rem;
		font-weight: bold;
		color: white;
		margin-bottom: 20px;
		text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
	}
	
	.boton-accion {
		display: flex;
		align-items: center;
		gap: 15px;
		padding: 20px;
		background: rgba(255, 255, 255, 0.1);
		border: 2px solid rgba(255, 255, 255, 0.2);
		border-radius: 15px;
		color: white;
		cursor: pointer;
		transition: all 0.3s ease;
		margin-bottom: 20px;
	}
	
	.boton-accion:hover {
		background: rgba(255, 255, 255, 0.2);
		transform: translateY(-2px);
	}
	
	.boton-grande {
		font-size: 1.2rem;
		font-weight: bold;
	}
	
	.icono-boton {
		font-size: 2rem;
	}
	
	.tarjeta-cancion {
		display: flex;
		align-items: center;
		gap: 15px;
		padding: 15px;
		background: rgba(255, 255, 255, 0.1);
		border: 2px solid rgba(255, 255, 255, 0.1);
		border-radius: 15px;
		color: white;
		cursor: pointer;
		transition: all 0.3s ease;
		margin-bottom: 15px;
	}
	
	.tarjeta-cancion:hover {
		background: rgba(255, 255, 255, 0.2);
		border-color: #4ecdc4;
		transform: translateY(-2px);
	}
	
	.imagen-cancion {
		width: 60px;
		height: 60px;
		border-radius: 10px;
		overflow: hidden;
		background: rgba(255, 255, 255, 0.1);
	}
	
	.imagen-cancion img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	
	.info-cancion {
		flex: 1;
	}
	
	.titulo-cancion {
		font-size: 1.1rem;
		font-weight: bold;
		margin-bottom: 5px;
	}
	
	.artista-cancion {
		font-size: 0.9rem;
		opacity: 0.8;
		margin-bottom: 5px;
	}
	
	.detalles-cancion {
		display: flex;
		gap: 10px;
		font-size: 0.8rem;
		flex-wrap: wrap;
	}
	
	.genero, .dificultad, .duracion {
		padding: 2px 8px;
		background: rgba(255, 255, 255, 0.2);
		border-radius: 10px;
	}
	
	.panel-detalle {
		flex: 0.6;
		background: rgba(0, 0, 0, 0.3);
		backdrop-filter: blur(10px);
		border-radius: 15px;
		padding: 20px;
		transition: all 0.3s ease;
		border: 2px solid rgba(255, 255, 255, 0.1);
	}
	
	.detalle-colapsado {
		flex: 0;
		padding: 0;
		overflow: hidden;
	}
	
	.detalle-cancion {
		color: white;
		height: 100%;
		display: flex;
		flex-direction: column;
	}
	
	.cabecera-detalle {
		display: flex;
		align-items: center;
		gap: 20px;
		margin-bottom: 20px;
		position: relative;
	}
	
	.imagen-detalle {
		width: 100px;
		height: 100px;
		border-radius: 15px;
		overflow: hidden;
		background: rgba(255, 255, 255, 0.1);
	}
	
	.imagen-detalle img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	
	.info-detalle h2 {
		font-size: 1.5rem;
		margin-bottom: 10px;
	}
	
	.artista-detalle {
		font-size: 1rem;
		opacity: 0.8;
		margin-bottom: 15px;
	}
	
	.etiquetas-detalle {
		display: flex;
		gap: 10px;
		flex-wrap: wrap;
	}
	
	.etiqueta {
		padding: 5px 12px;
		background: rgba(255, 255, 255, 0.2);
		border-radius: 15px;
		font-size: 0.9rem;
	}
	
	.boton-cerrar {
		position: absolute;
		top: 0;
		right: 0;
		background: rgba(255, 255, 255, 0.2);
		border: none;
		border-radius: 50%;
		width: 30px;
		height: 30px;
		color: white;
		cursor: pointer;
		transition: all 0.3s ease;
	}
	
	.boton-cerrar:hover {
		background: rgba(255, 0, 0, 0.5);
	}
	
	.descripcion-cancion {
		margin-bottom: 20px;
		padding: 15px;
		background: rgba(255, 255, 255, 0.1);
		border-radius: 10px;
	}
	
	.opciones-juego {
		flex: 1;
		display: flex;
		flex-direction: column;
	}
	
	.opciones-juego h3 {
		margin-bottom: 20px;
		text-align: center;
		opacity: 0.8;
	}
	
	.dificultades {
		background: rgba(255, 255, 255, 0.1);
		border-radius: 10px;
		padding: 15px;
		margin-bottom: 30px;
	}
	
	.dificultad-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 10px 0;
		font-size: 0.9rem;
	}
	
	.nivel {
		font-weight: bold;
	}
	
	.botones-accion {
		display: flex;
		gap: 15px;
		justify-content: center;
		margin-top: auto;
	}
	
	.boton-jugar {
		background: linear-gradient(135deg, #ff6b6b, #4ecdc4);
		border: none;
		border-radius: 25px;
		padding: 15px 30px;
		color: white;
		font-size: 1.2rem;
		font-weight: bold;
		cursor: pointer;
		transition: all 0.3s ease;
	}
	
	.boton-jugar:hover {
		transform: translateY(-2px);
		box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
	}
	
	.boton-cancelar {
		background: rgba(255, 255, 255, 0.2);
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-radius: 25px;
		padding: 15px 30px;
		color: white;
		font-size: 1.2rem;
		cursor: pointer;
		transition: all 0.3s ease;
	}
	
	.boton-cancelar:hover {
		background: rgba(255, 255, 255, 0.3);
	}
	
	.mensaje-construccion {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 60px 20px;
		color: white;
		opacity: 0.6;
	}
	
	.icono-construccion {
		font-size: 3rem;
		margin-bottom: 20px;
	}
	
	/* Estilos del modal */
	.contenido-modal {
		color: white;
		padding: 20px;
	}
	
	.contenido-modal p {
		margin-bottom: 15px;
		opacity: 0.9;
		line-height: 1.5;
	}
	
	.formulario-sugerencia {
		display: flex;
		flex-direction: column;
		gap: 20px;
		margin-top: 20px;
	}
	
	.formulario-sugerencia label {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	
	.formulario-sugerencia label span {
		font-weight: bold;
		color: #ff6b6b;
	}
	
	.formulario-sugerencia input,
	.formulario-sugerencia select,
	.formulario-sugerencia textarea {
		padding: 12px;
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-radius: 8px;
		background: rgba(255, 255, 255, 0.1);
		color: white;
		font-size: 1rem;
	}
	
	.formulario-sugerencia input::placeholder,
	.formulario-sugerencia textarea::placeholder {
		color: rgba(255, 255, 255, 0.6);
	}
	
	.formulario-sugerencia textarea {
		min-height: 80px;
		resize: vertical;
	}
	
	.botones-modal {
		display: flex;
		gap: 15px;
		justify-content: center;
		margin-top: 30px;
	}
	
	/* Estilos para canciones personalizadas */
	.tarjeta-cancion.cancion-personalizada {
		background: rgba(155, 89, 182, 0.2) !important;
		border-color: rgba(155, 89, 182, 0.5) !important;
		border-left: 4px solid #9b59b6 !important;
		position: relative;
	}
	
	.tarjeta-cancion.cancion-personalizada:hover {
		background: rgba(155, 89, 182, 0.3) !important;
		box-shadow: 0 8px 32px rgba(155, 89, 182, 0.2) !important;
	}
	
	.badge-personalizada {
		position: absolute;
		top: 10px;
		right: 10px;
		background: #9b59b6;
		color: white;
		padding: 4px 8px;
		border-radius: 12px;
		font-size: 0.7rem;
		font-weight: bold;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
		z-index: 10;
	}
	
	.etiqueta.personalizada {
		background: #9b59b6 !important;
		color: white !important;
		font-weight: bold !important;
	}
	
	.etiqueta.notas {
		background: #3498db !important;
		color: white !important;
	}
	
	.mensaje-info {
		background: rgba(52, 152, 219, 0.2);
		border: 1px solid rgba(52, 152, 219, 0.5);
		border-radius: 8px;
		padding: 15px;
		margin-bottom: 20px;
		color: white;
	}
	
	.mensaje-info p {
		margin: 0;
		font-size: 0.9rem;
		opacity: 0.9;
	}
	
	.mensaje-vacio {
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 8px;
		padding: 20px;
		margin-bottom: 20px;
		text-align: center;
		color: white;
		opacity: 0.8;
	}
	
	.mensaje-vacio p {
		margin: 5px 0;
		font-size: 0.9rem;
	}
	
	.boton-debug {
		background: rgba(231, 76, 60, 0.8) !important;
		border: 2px solid rgba(231, 76, 60, 0.5) !important;
		color: white !important;
	}
	
	.boton-debug:hover {
		background: rgba(231, 76, 60, 1) !important;
		transform: translateY(-2px);
	}
	
	.boton-enviar {
		background: linear-gradient(135deg, #ff6b6b, #4ecdc4);
		border: none;
		border-radius: 25px;
		padding: 12px 25px;
		color: white;
		font-weight: bold;
		cursor: pointer;
		transition: all 0.3s ease;
	}
	
	.boton-enviar:hover {
		transform: translateY(-2px);
		box-shadow: 0 5px 15px rgba(255, 107, 107, 0.4);
	}
	
	.boton-cancelar-modal {
		background: rgba(255, 255, 255, 0.2);
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-radius: 25px;
		padding: 12px 25px;
		color: white;
		cursor: pointer;
		transition: all 0.3s ease;
	}
	
	.boton-cancelar-modal:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	/* Responsive */
	@media (max-width: 768px) {
		.contenido-principal {
			flex-direction: column;
			height: auto;
		}
		
		.pestana .texto-pestana {
			display: none;
		}
		
		.pestanas {
			flex-direction: column;
			align-items: center;
		}
		
		.pestana {
			width: 100%;
			max-width: 300px;
			text-align: center;
		}
		
		.lista-colapsada {
			flex: 1;
		}
		
		.panel-detalle {
			flex: 1;
		}
	}
</style> 
