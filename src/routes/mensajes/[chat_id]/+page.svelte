<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { supabase } from '$lib/supabase';
	import { mensajeriaService, type Chat } from '$lib/services/mensajeriaService';
	import ChatVista from '$lib/components/Mensajeria/ChatVista.svelte';
	
	// ============================================
	// PARÁMETROS Y ESTADOS
	// ============================================
	
	$: chatId = $page.params.chat_id;
	
	let chat: Chat | null = null;
	let cargando = true;
	let error = '';
	let usuarioActual: any = null;
	
	// ============================================
	// CICLO DE VIDA
	// ============================================
	
	onMount(async () => {
		// Verificar autenticación
		const { data: { user } } = await supabase.auth.getUser();
		if (!user) {
			goto('/');
			return;
		}
		
		// Obtener datos del usuario
		const { data: perfil } = await supabase
			.from('perfiles')
			.select('*')
			.eq('id', user.id)
			.single();
			
		usuarioActual = perfil;
		
		// Cargar el chat
		await cargarChat();
	});
	
	onDestroy(() => {
		// Limpiar suscripciones cuando se destruye el componente
		if (chatId) {
			mensajeriaService.desuscribirseDeChat(chatId);
		}
	});
	
	// ============================================
	// FUNCIONES PRINCIPALES
	// ============================================
	
	async function cargarChat() {
		if (!chatId) return;
		
		try {
			cargando = true;
			
			// Obtener el chat específico
			const { data, error: errorChat } = await supabase
				.from('chats')
				.select(`
					*,
					miembros_chat(
						*,
						usuario:perfiles!miembros_chat_usuario_id_fkey(
							nombre_completo,
							url_foto_perfil,
							nombre_usuario,
							rol
						)
					)
				`)
				.eq('id', chatId)
				.eq('activo', true)
				.single();
			
			if (errorChat) {
				console.error('Error cargando chat:', errorChat);
				error = 'No se pudo cargar el chat';
				return;
			}
			
			if (!data) {
				error = 'Chat no encontrado';
				return;
			}
			
			// Verificar que el usuario actual es miembro del chat
			const { data: { user } } = await supabase.auth.getUser();
			const esMiembro = data.miembros_chat.some((m: any) => 
				m.usuario_id === user?.id && m.estado_miembro === 'activo'
			);
			
			if (!esMiembro) {
				error = 'No tienes acceso a este chat';
				return;
			}
			
			chat = {
				...data,
				miembros: data.miembros_chat
			};
			
		} catch (err) {
			console.error('Error inesperado cargando chat:', err);
			error = 'Error inesperado cargando el chat';
		} finally {
			cargando = false;
		}
	}
	

	
	function volverAMensajes() {
		goto('/mensajes');
	}
	
	// ============================================
	// REACTIVE STATEMENTS
	// ============================================
	
	// Recargar chat cuando cambia el ID
	$: if (chatId) {
		cargarChat();
	}
</script>


<!-- ============================================ -->
<!-- CONTENIDO PRINCIPAL -->
<!-- ============================================ -->
{#if cargando}
	<!-- Estado de carga -->
	<div class="flex items-center justify-center h-96 bg-gray-50 dark:bg-gray-900">
		<div class="text-center">
			<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
			<p class="text-gray-600 dark:text-gray-400">Cargando chat...</p>
		</div>
	</div>
{:else if error}
	<!-- Estado de error -->
	<div class="flex items-center justify-center h-96 bg-gray-50 dark:bg-gray-900">
		<div class="text-center max-w-md px-4">
			<div class="mx-auto mb-4 w-16 h-16 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center">
				<svg class="w-8 h-8 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
				</svg>
			</div>
			<h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
				{error}
			</h2>
			<p class="text-gray-600 dark:text-gray-400 mb-6">
				Lo sentimos, ocurrió un problema al cargar este chat.
			</p>
			<button
				on:click={volverAMensajes}
				class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
			>
				Volver a Mensajes
			</button>
		</div>
	</div>
{:else if chat}
	<!-- Chat cargado correctamente -->
	<div class="flex h-screen bg-gray-50 dark:bg-gray-900">
		<!-- Vista principal del chat -->
		<div class="flex-1 flex flex-col">
			<ChatVista 
				{chat} 
				on:regresar={volverAMensajes}
			/>
		</div>
	</div>
{/if}

<style>
	/* Asegurar que la altura sea correcta */
	:global(html, body) {
		height: 100%;
		overflow: hidden;
	}
</style> 