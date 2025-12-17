<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { supabase } from '$lib/supabase';
	import ListaChats from '$lib/components/Mensajeria/ListaChats.svelte';
	import ChatVista from '$lib/components/Mensajeria/ChatVista.svelte';

	import type { Chat } from '$lib/services/mensajeriaService';
	
	// ============================================
	// ESTADOS Y VARIABLES
	// ============================================
	
	let chatSeleccionado: Chat | null = null;
	let mostrarListaChats = true;

	let usuarioActual: any = null;
	let cargandoUsuario = true;
	
	// ============================================
	// CICLO DE VIDA
	// ============================================
	
	onMount(async () => {
		// Verificar autenticación
		const { data: { user } } = await supabase.auth.getUser();
		if (!user) {
			goto('/auth/login');
			return;
		}
		
		// Obtener datos del usuario
		const { data: perfil } = await supabase
			.from('perfiles')
			.select('*')
			.eq('id', user.id)
			.single();
			
		usuarioActual = perfil;
		cargandoUsuario = false;
	});
	
	// ============================================
	// FUNCIONES DE MANEJO
	// ============================================
	
	function manejarSeleccionChat(chat: Chat) {
		chatSeleccionado = chat;
		// En móvil, ocultar lista de chats al seleccionar uno
		if (window.innerWidth < 768) {
			mostrarListaChats = false;
		}
	}
	
	function volverALista() {
		mostrarListaChats = true;
		chatSeleccionado = null;
	}
	

	
	// ============================================
	// FUNCIONES RESPONSIVE
	// ============================================
	
	function manejarResize() {
		// En pantallas grandes, mostrar siempre la lista
		if (window.innerWidth >= 768) {
			mostrarListaChats = true;
		}
	}
</script>

<svelte:window on:resize={manejarResize} />



{#if cargandoUsuario}
	<!-- Estado de carga -->
	<div class="flex items-center justify-center h-96">
		<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
	</div>
{:else}
	<!-- ============================================ -->
	<!-- CONTENIDO PRINCIPAL -->
	<!-- ============================================ -->
	<div class="flex h-screen bg-gray-50 dark:bg-gray-900">
		<!-- ============================================ -->
		<!-- LISTA DE CHATS (Sidebar) -->
		<!-- ============================================ -->
		<div class={`${mostrarListaChats ? 'block' : 'hidden'} lg:block w-full lg:w-80 xl:w-96 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex-shrink-0`}>
			<ListaChats 
				chatSeleccionado={chatSeleccionado?.id || null}
				onSeleccionarChat={manejarSeleccionChat}
				{usuarioActual}
			/>
		</div>

		<!-- ============================================ -->
		<!-- VISTA DE CHAT PRINCIPAL -->
		<!-- ============================================ -->
		<div class={`${mostrarListaChats ? 'hidden' : 'block'} lg:block flex-1 flex`}>
			{#if chatSeleccionado}
				<!-- Chat seleccionado -->
				<div class="flex-1 flex flex-col">
					<ChatVista 
						chat={chatSeleccionado} 
						on:regresar={volverALista}
					/>
				</div>

			{:else}
				<!-- Estado inicial - sin chat seleccionado -->
				<div class="flex-1 flex items-center justify-center bg-gray-50 dark:bg-gray-900">
					<div class="text-center max-w-md px-4">
						<div class="mx-auto mb-4 w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
							<svg class="w-8 h-8 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
							</svg>
						</div>
						<h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
							¡Bienvenido a Mensajes!
						</h2>
						<p class="text-gray-600 dark:text-gray-400 mb-6">
							Selecciona un chat de la lista para comenzar a conversar, o crea uno nuevo para conectarte con otros miembros de la Academia.
						</p>
						<div class="space-y-3 text-sm text-gray-500 dark:text-gray-400">
							<div class="flex items-center justify-center space-x-2">
								<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
									<path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
								</svg>
								<span>Chats privados y grupales</span>
							</div>
							<div class="flex items-center justify-center space-x-2">
								<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
									<path d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"/>
								</svg>
								<span>Compartir imágenes y archivos</span>
							</div>
							<div class="flex items-center justify-center space-x-2">
								<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
									<path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"/>
								</svg>
								<span>Reacciones con emojis</span>
							</div>
						</div>
					</div>
				</div>
			{/if}
		</div>
	</div>
{/if}

<style>
	/* Asegurar que la altura sea correcta en móviles */
	:global(html, body) {
		height: 100%;
		overflow: hidden;
	}
</style> 