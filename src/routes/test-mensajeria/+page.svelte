<script lang="ts">
  import { onMount } from 'svelte';
  import { mensajeriaSimple } from '$lib/services/mensajeriaService_simple';

  let chats: any[] = [];
  let mensajes: any[] = [];
  let error = '';
  let cargando = false;
  let chatSeleccionado = '';

  async function probarChats() {
    cargando = true;
    error = '';
    
    const resultado = await mensajeriaSimple.obtenerChats();
    
    if (resultado.error) {
      error = resultado.error;
    } else {
      chats = resultado.chats;
    }
    
    cargando = false;
  }

  async function probarMensajes(chatId: string) {
    cargando = true;
    error = '';
    chatSeleccionado = chatId;
    
    const resultado = await mensajeriaSimple.obtenerMensajes(chatId);
    
    if (resultado.error) {
      error = resultado.error;
    } else {
      mensajes = resultado.mensajes;
    }
    
    cargando = false;
  }

  async function crearChatPrueba() {
    cargando = true;
    error = '';
    
    const resultado = await mensajeriaSimple.crearChat('Chat de Prueba', []);
    
    if (resultado.error) {
      error = resultado.error;
    } else {
      await probarChats(); // Refrescar lista
    }
    
    cargando = false;
  }

  onMount(() => {
    probarChats();
  });
</script>

<div class="p-8 max-w-6xl mx-auto">
  <h1 class="text-3xl font-bold mb-8">🧪 Prueba de Mensajería</h1>

  {#if error}
    <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
      <strong>Error:</strong> {error}
    </div>
  {/if}

  {#if cargando}
    <div class="bg-blue-100 border border-blue-400 text-blue-700 px-4 py-3 rounded mb-4">
      ⏳ Cargando...
    </div>
  {/if}

  <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
    <!-- Lista de Chats -->
    <div class="bg-white rounded-lg shadow p-6">
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-xl font-semibold">📋 Chats</h2>
        <button 
          on:click={crearChatPrueba}
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          disabled={cargando}
        >
          ➕ Crear Chat
        </button>
      </div>

      {#if chats.length === 0}
        <p class="text-gray-500">No hay chats disponibles</p>
      {:else}
        <div class="space-y-2">
          {#each chats as chat}
            <div 
              class="p-3 border rounded cursor-pointer hover:bg-gray-50 {chatSeleccionado === chat.id ? 'bg-blue-50 border-blue-300' : ''}"
              on:click={() => probarMensajes(chat.id)}
            >
              <div class="font-medium">{chat.nombre || 'Chat sin nombre'}</div>
              <div class="text-sm text-gray-500">
                ID: {chat.id} | 
                Tipo: {chat.es_grupal ? 'Grupal' : 'Privado'} |
                Creado: {new Date(chat.creado_en).toLocaleString()}
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>

    <!-- Lista de Mensajes -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-xl font-semibold mb-4">💬 Mensajes</h2>

      {#if !chatSeleccionado}
        <p class="text-gray-500">Selecciona un chat para ver los mensajes</p>
      {:else if mensajes.length === 0}
        <p class="text-gray-500">No hay mensajes en este chat</p>
      {:else}
        <div class="space-y-3 max-h-96 overflow-y-auto">
          {#each mensajes as mensaje}
            <div class="p-3 border rounded">
              <div class="flex justify-between items-start mb-2">
                <span class="font-medium">{mensaje.usuario?.nombre_completo || 'Usuario'}</span>
                <span class="text-xs text-gray-500">
                  {new Date(mensaje.creado_en).toLocaleString()}
                </span>
              </div>
              <div class="text-gray-700">{mensaje.contenido}</div>
              <div class="text-xs text-gray-400 mt-1">
                Tipo: {mensaje.tipo} | ID: {mensaje.id}
              </div>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>

  <!-- Debug Info -->
  <div class="mt-8 bg-gray-100 rounded-lg p-4">
    <h3 class="font-semibold mb-2">🔍 Debug Info</h3>
    <div class="text-sm">
      <p><strong>Total Chats:</strong> {chats.length}</p>
      <p><strong>Total Mensajes:</strong> {mensajes.length}</p>
      <p><strong>Chat Seleccionado:</strong> {chatSeleccionado || 'Ninguno'}</p>
      <p><strong>Estado:</strong> {cargando ? 'Cargando' : 'Listo'}</p>
    </div>
  </div>
</div> 