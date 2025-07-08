<script lang="ts">
	import { onMount, onDestroy, afterUpdate } from 'svelte';
	import { writable } from 'svelte/store';
	import { mensajeriaService, type Chat, type Mensaje, type MensajeReaccion } from '$lib/services/mensajeriaService';
	import { formatearTiempoRelativo } from '$lib/services/imagenUsuarioService';
	import BurbujaMensaje from './BurbujaMensaje.svelte';
	import EntradaMensaje from './EntradaMensaje.svelte';
	import BarraMiembrosChat from './BarraMiembrosChat.svelte';

	// ============================================
	// PROPS Y ESTADOS
	// ============================================

	export let chat: Chat | null = null;
	export let mostrarBarraMiembros: boolean = false;

	let mensajes = writable<Mensaje[]>([]);
	let cargando = true;
	let cargandoMas = false;
	let error = '';
	let contenedorMensajes: HTMLElement;
	let ultimoMensajeId = '';
	let hayMasMensajes = true;
	let autoScroll = true;
	let usuarioEscribiendo: any[] = [];

	// Estados para funcionalidades avanzadas
	let mensajeEnRespuesta: Mensaje | null = null;
	let editandoMensaje: Mensaje | null = null;
	let mostrarEmojis = false;
	let buscandoMensajes = false;
	let terminoBusqueda = '';

	// ============================================
	// FUNCIONES PRINCIPALES
	// ============================================

	/**
	 * 📥 Cargar mensajes del chat
	 */
	async function cargarMensajes(limpiar = true) {
		if (!chat) return;

		try {
			if (limpiar) {
				cargando = true;
				mensajes.set([]);
			} else {
				cargandoMas = true;
			}

			const antesDeId = limpiar ? undefined : $mensajes[0]?.id;
			const { mensajes: mensajesObtenidos, error: errorObtenido } = await mensajeriaService.obtenerMensajes(
				chat.id,
				50,
				antesDeId
			);

			if (errorObtenido) {
				error = errorObtenido;
				console.error('Error cargando mensajes:', errorObtenido);
			} else {
				if (limpiar) {
					mensajes.set(mensajesObtenidos);
				} else {
					mensajes.update(mensajesActuales => [...mensajesObtenidos, ...mensajesActuales]);
				}

				// Verificar si hay más mensajes
				hayMasMensajes = mensajesObtenidos.length === 50;

				// Scroll al final si es carga inicial
				if (limpiar && mensajesObtenidos.length > 0) {
					setTimeout(scrollAlFinal, 100);
				}
			}
		} catch (err) {
			error = 'Error inesperado cargando mensajes';
			console.error('Error:', err);
		} finally {
			cargando = false;
			cargandoMas = false;
		}
	}

	/**
	 * 📤 Enviar mensaje
	 */
	async function enviarMensaje(datos: {
		contenido: string;
		tipo?: string;
		url_media?: string;
		metadata?: any;
	}) {
		if (!chat) return;

		const datosCompletos = {
			chat_id: chat.id,
			contenido: datos.contenido,
			tipo: datos.tipo || 'texto',
			url_media: datos.url_media,
			metadata: datos.metadata || {},
			mensaje_padre_id: mensajeEnRespuesta?.id
		};

		const { mensaje, error: errorEnvio } = await mensajeriaService.enviarMensaje(datosCompletos);

		if (errorEnvio) {
			console.error('Error enviando mensaje:', errorEnvio);
			// Mostrar notificación de error
		} else if (mensaje) {
			// Limpiar estado de respuesta
			mensajeEnRespuesta = null;
			
			// El mensaje aparecerá automáticamente por tiempo real
			// pero lo agregamos localmente para responsividad inmediata
			mensajes.update(mensajesActuales => [...mensajesActuales, mensaje]);
			
			setTimeout(scrollAlFinal, 100);
		}
	}

	/**
	 * 🔄 Actualizar mensaje (editar)
	 */
	async function actualizarMensaje(mensajeId: string, nuevoContenido: string) {
		// Esta funcionalidad se implementaría en el servicio
		console.log('Actualizando mensaje:', mensajeId, nuevoContenido);
		editandoMensaje = null;
	}

	/**
	 * 🗑️ Eliminar mensaje
	 */
	async function eliminarMensaje(mensajeId: string) {
		// Esta funcionalidad se implementaría en el servicio
		console.log('Eliminando mensaje:', mensajeId);
	}

	/**
	 * 😊 Toggle reacción
	 */
	async function toggleReaccion(mensajeId: string, emoji: string) {
		const { exito, error: errorReaccion } = await mensajeriaService.toggleReaccion(mensajeId, emoji);
		
		if (errorReaccion) {
			console.error('Error con reacción:', errorReaccion);
		}
		// Las reacciones se actualizarán automáticamente por tiempo real
	}

	/**
	 * 📜 Scroll al final
	 */
	function scrollAlFinal() {
		if (contenedorMensajes && autoScroll) {
			contenedorMensajes.scrollTop = contenedorMensajes.scrollHeight;
		}
	}

	/**
	 * 📄 Cargar más mensajes (scroll infinito)
	 */
	function manejarScrollSuperior() {
		if (contenedorMensajes.scrollTop === 0 && hayMasMensajes && !cargandoMas) {
			cargarMensajes(false);
		}
	}

	/**
	 * 🔍 Detectar si el usuario está viendo los mensajes más recientes
	 */
	function manejarScroll() {
		if (!contenedorMensajes) return;
		
		const { scrollTop, scrollHeight, clientHeight } = contenedorMensajes;
		const distanciaDelFinal = scrollHeight - scrollTop - clientHeight;
		
		// Si está cerca del final, activar auto-scroll
		autoScroll = distanciaDelFinal < 100;
		
		// Cargar más mensajes si está en la parte superior
		if (scrollTop === 0 && hayMasMensajes && !cargandoMas) {
			manejarScrollSuperior();
		}
	}

	/**
	 * 💭 Preparar respuesta a mensaje
	 */
	function responderMensaje(mensaje: Mensaje) {
		mensajeEnRespuesta = mensaje;
	}

	/**
	 * ✏️ Preparar edición de mensaje
	 */
	function editarMensaje(mensaje: Mensaje) {
		editandoMensaje = mensaje;
	}

	/**
	 * ❌ Cancelar respuesta
	 */
	function cancelarRespuesta() {
		mensajeEnRespuesta = null;
	}

	/**
	 * 🏷️ Obtener información del chat
	 */
	function obtenerInfoChat() {
		if (!chat) return { nombre: '', avatar: '', descripcion: '' };
		
		if (chat.nombre) {
			return {
				nombre: chat.nombre,
				avatar: chat.imagen_url || 'https://via.placeholder.com/40',
				descripcion: chat.descripcion || ''
			};
		}
		
		// Para chats privados, usar info del otro usuario
		if (!chat.es_grupal && chat.miembros && chat.miembros.length > 0) {
			const otroMiembro = chat.miembros.find(m => m.usuario?.nombre_completo);
			return {
				nombre: otroMiembro?.usuario?.nombre_completo || 'Chat Privado',
				avatar: otroMiembro?.usuario?.url_foto_perfil || 'https://via.placeholder.com/40',
				descripcion: otroMiembro?.usuario?.rol ? `${otroMiembro.usuario.rol}` : ''
			};
		}
		
		return {
			nombre: 'Chat',
			avatar: 'https://via.placeholder.com/40',
			descripcion: ''
		};
	}

	// ============================================
	// TIEMPO REAL
	// ============================================

	/**
	 * 🔴 Configurar suscripción en tiempo real
	 */
	async function configurarTiempoReal() {
		if (!chat) return;

		await mensajeriaService.suscribirseAChat(chat.id, {
			onNuevoMensaje: (mensaje: Mensaje) => {
				// Solo agregar si no existe ya (evitar duplicados)
				mensajes.update(mensajesActuales => {
					const existe = mensajesActuales.some(m => m.id === mensaje.id);
					if (existe) return mensajesActuales;
					
					const nuevaLista = [...mensajesActuales, mensaje];
					
					// Auto-scroll si el usuario está viendo los mensajes recientes
					if (autoScroll) {
						setTimeout(scrollAlFinal, 100);
					}
					
					return nuevaLista;
				});
			},
			
			onMensajeEditado: (mensaje: Mensaje) => {
				mensajes.update(mensajesActuales =>
					mensajesActuales.map(m => m.id === mensaje.id ? mensaje : m)
				);
			},
			
			onMensajeEliminado: (mensajeId: string) => {
				mensajes.update(mensajesActuales =>
					mensajesActuales.filter(m => m.id !== mensajeId)
				);
			},
			
			onReaccionCambiada: (mensajeId: string, reacciones: MensajeReaccion[]) => {
				mensajes.update(mensajesActuales =>
					mensajesActuales.map(m => 
						m.id === mensajeId ? { ...m, reacciones } : m
					)
				);
			},
			
			onUsuarioEscribiendo: (usuario: any) => {
				// Manejar indicador de "escribiendo..."
				usuarioEscribiendo = [usuario];
				setTimeout(() => {
					usuarioEscribiendo = [];
				}, 3000);
			}
		});
	}

	// ============================================
	// CICLO DE VIDA
	// ============================================

	onMount(async () => {
		if (chat) {
			await cargarMensajes();
			await configurarTiempoReal();
		}
	});

	onDestroy(async () => {
		if (chat) {
			await mensajeriaService.desuscribirseDeChat(chat.id);
		}
	});

	// Reactividad: cuando cambia el chat
	$: if (chat) {
		cargarMensajes();
		configurarTiempoReal();
	}

	// Auto-scroll después de actualizaciones del DOM
	afterUpdate(() => {
		if (autoScroll && ultimoMensajeId !== $mensajes[$mensajes.length - 1]?.id) {
			ultimoMensajeId = $mensajes[$mensajes.length - 1]?.id || '';
			scrollAlFinal();
		}
	});

	$: infoChat = obtenerInfoChat();
</script>

<!-- ============================================ -->
<!-- TEMPLATE PRINCIPAL -->
<!-- ============================================ -->

<div class="chat-vista h-full flex flex-col bg-white dark:bg-gray-900">
	{#if !chat}
		<!-- Estado sin chat seleccionado -->
		<div class="flex-1 flex items-center justify-center bg-gray-50 dark:bg-gray-800">
			<div class="text-center text-gray-500 dark:text-gray-400">
				<div class="text-6xl mb-4">💬</div>
				<h3 class="text-xl font-semibold mb-2">Selecciona un chat</h3>
				<p>Elige una conversación de la lista para comenzar a chatear</p>
			</div>
		</div>
	{:else}
		<!-- Header del chat -->
		<div class="chat-header flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900">
			<div class="flex items-center space-x-3">
				<!-- Avatar -->
				<div class="relative">
					<img
						src={infoChat.avatar}
						alt={infoChat.nombre}
						class="w-10 h-10 rounded-full object-cover border-2 border-white dark:border-gray-700 shadow-sm"
					>
					<!-- Indicador online para chats privados -->
					{#if !chat.es_grupal}
						<div class="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-white dark:border-gray-700"></div>
					{/if}
				</div>
				
				<!-- Info del chat -->
				<div class="flex-1 min-w-0">
					<h3 class="text-lg font-semibold text-gray-900 dark:text-white truncate">
						{infoChat.nombre}
					</h3>
					{#if infoChat.descripcion}
						<p class="text-sm text-gray-500 dark:text-gray-400 truncate">
							{infoChat.descripcion}
						</p>
					{:else if usuarioEscribiendo.length > 0}
						<p class="text-sm text-blue-600 dark:text-blue-400 italic">
							💭 Escribiendo...
						</p>
					{:else if chat.es_grupal && chat.miembros}
						<p class="text-sm text-gray-500 dark:text-gray-400">
							{chat.miembros.length} miembro{chat.miembros.length !== 1 ? 's' : ''}
						</p>
					{:else}
						<p class="text-sm text-green-500 dark:text-green-400">
							🟢 En línea
						</p>
					{/if}
				</div>
			</div>
			
			<!-- Acciones del header -->
			<div class="flex items-center space-x-2">
				<!-- Búsqueda -->
				<button
					class="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
					title="Buscar mensajes"
					on:click={() => buscandoMensajes = !buscandoMensajes}
				>
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21 21-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
					</svg>
				</button>
				
				<!-- Info del chat -->
				<button
					class="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
					title="Información del chat"
					on:click={() => mostrarBarraMiembros = !mostrarBarraMiembros}
				>
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
					</svg>
				</button>
				
				<!-- Menú de opciones -->
				<button
					class="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
					title="Más opciones"
				>
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"></path>
					</svg>
				</button>
			</div>
		</div>
		
		<!-- Barra de búsqueda (opcional) -->
		{#if buscandoMensajes}
			<div class="p-3 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
				<div class="relative">
					<input
						type="text"
						bind:value={terminoBusqueda}
						placeholder="Buscar en esta conversación..."
						class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg 
							   bg-white dark:bg-gray-700 text-gray-900 dark:text-white 
							   focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
					>
					<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
						<svg class="h-4 w-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m21 21-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
						</svg>
					</div>
					<button
						class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600"
						on:click={() => { buscandoMensajes = false; terminoBusqueda = ''; }}
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
						</svg>
					</button>
				</div>
			</div>
		{/if}
		
		<!-- Área de mensajes -->
		<div 
			class="flex-1 overflow-y-auto p-4 space-y-1"
			bind:this={contenedorMensajes}
			on:scroll={manejarScroll}
		>
			{#if cargando}
				<!-- Estado de carga inicial -->
				<div class="flex justify-center py-8">
					<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
				</div>
			{:else if error}
				<!-- Estado de error -->
				<div class="text-center py-8 text-red-500 dark:text-red-400">
					❌ {error}
					<button
						on:click={() => cargarMensajes()}
						class="block mx-auto mt-2 text-blue-600 dark:text-blue-400 hover:underline"
					>
						Reintentar
					</button>
				</div>
			{:else if $mensajes.length === 0}
				<!-- Estado sin mensajes -->
				<div class="text-center py-8 text-gray-500 dark:text-gray-400">
					<div class="text-4xl mb-4">💬</div>
					<p>No hay mensajes aún. ¡Sé el primero en escribir!</p>
				</div>
			{:else}
				<!-- Indicador de carga de más mensajes -->
				{#if cargandoMas}
					<div class="flex justify-center py-4">
						<div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
					</div>
				{/if}
				
				<!-- Lista de mensajes -->
				{#each $mensajes as mensaje, index (mensaje.id)}
					<BurbujaMensaje
						{mensaje}
						mensajeAnterior={$mensajes[index - 1]}
						mensajeSiguiente={$mensajes[index + 1]}
						{chat}
						on:responder={() => responderMensaje(mensaje)}
						on:editar={() => editarMensaje(mensaje)}
						on:eliminar={() => eliminarMensaje(mensaje.id)}
						on:reaccionar={(e) => toggleReaccion(mensaje.id, e.detail.emoji)}
					/>
				{/each}
			{/if}
		</div>
		
		<!-- Indicador de mensaje en respuesta -->
		{#if mensajeEnRespuesta}
			<div class="flex items-center justify-between px-4 py-2 bg-blue-50 dark:bg-blue-900/20 border-t border-blue-200 dark:border-blue-800">
				<div class="flex items-center space-x-3">
					<div class="w-1 h-8 bg-blue-500 rounded-full"></div>
					<div>
						<div class="text-sm font-medium text-blue-700 dark:text-blue-300">
							Respondiendo a {mensajeEnRespuesta.usuario?.nombre_completo}
						</div>
						<div class="text-sm text-blue-600 dark:text-blue-400 truncate max-w-xs">
							{mensajeEnRespuesta.contenido}
						</div>
					</div>
				</div>
				<button
					on:click={cancelarRespuesta}
					class="text-blue-500 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
				>
					<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
					</svg>
				</button>
			</div>
		{/if}
		
		<!-- Entrada de mensaje -->
		<EntradaMensaje
			{chat}
			on:enviar={(e) => enviarMensaje(e.detail)}
			mensajeEnRespuesta={mensajeEnRespuesta}
			disabled={cargando}
		/>
	{/if}
</div>

<!-- Barra lateral de miembros (opcional) -->
{#if mostrarBarraMiembros && chat}
	<BarraMiembrosChat
		{chat}
		onCerrar={() => mostrarBarraMiembros = false}
	/>
{/if}

<style>
	/* Estilos personalizados para el chat */
	.chat-vista {
		height: 100%;
		display: flex;
		flex-direction: column;
	}
	
	.chat-header {
		flex-shrink: 0;
		backdrop-filter: blur(10px);
		border-bottom: 1px solid rgba(229, 231, 235, 0.5);
	}
	
	/* Scroll suave */
	.overflow-y-auto {
		scrollbar-width: thin;
		scrollbar-color: rgba(156, 163, 175, 0.5) transparent;
	}
	
	.overflow-y-auto::-webkit-scrollbar {
		width: 6px;
	}
	
	.overflow-y-auto::-webkit-scrollbar-track {
		background: transparent;
	}
	
	.overflow-y-auto::-webkit-scrollbar-thumb {
		background: rgba(156, 163, 175, 0.5);
		border-radius: 3px;
	}
	
	.overflow-y-auto::-webkit-scrollbar-thumb:hover {
		background: rgba(156, 163, 175, 0.7);
	}
	
	/* Transiciones suaves */
	.transition-colors {
		transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out;
	}
	
	/* Animación de escritura */
	@keyframes typing {
		0%, 60%, 100% {
			transform: translateY(0);
		}
		30% {
			transform: translateY(-10px);
		}
	}
	
	.animate-typing {
		animation: typing 1.4s ease-in-out infinite;
	}
</style> 