<script lang="ts">
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  let configuraciones = {
    notificaciones_email: true,
    notificaciones_push: true,
    modo_oscuro: false,
    idioma: 'español',
    publico_perfil: true
  };

  let guardando = false;
  let mensaje = '';

  // Usar datos del store
  $: perfilData = $perfilStore.perfil;

  async function guardarConfiguracion() {
    if (!$usuario?.id) return;
    
    guardando = true;
    
    const { error } = await supabase
      .from('perfiles')
      .update(configuraciones)
      .eq('id', $usuario.id);

    if (error) {
      mensaje = 'Error al guardar configuración: ' + error.message;
    } else {
      mensaje = '¡Configuración guardada exitosamente!';
      // Actualizar el store con las nuevas configuraciones
      perfilStore.actualizarPerfil(configuraciones);
    }
    
    guardando = false;
    
    // Limpiar mensaje después de 3 segundos
    setTimeout(() => {
      mensaje = '';
    }, 3000);
  }

  async function cerrarSesion() {
    const { error } = await supabase.auth.signOut();
    if (!error) {
      perfilStore.resetear(); // Limpiar datos del store al cerrar sesión
      goto('/sesion_cerrada');
    }
  }

  onMount(() => {
    // Solo cargar configuraciones si los datos del perfil están disponibles
    if (perfilData) {
      configuraciones = {
        notificaciones_email: perfilData.notificaciones_email ?? true,
        notificaciones_push: perfilData.notificaciones_push ?? true,
        modo_oscuro: perfilData.modo_oscuro ?? false,
        idioma: perfilData.idioma ?? 'español',
        publico_perfil: perfilData.publico_perfil ?? true
      };
    }
  });

  // Reactivo: actualizar configuraciones cuando cambien los datos del perfil
  $: if (perfilData) {
    configuraciones = {
      notificaciones_email: perfilData.notificaciones_email ?? true,
      notificaciones_push: perfilData.notificaciones_push ?? true,
      modo_oscuro: perfilData.modo_oscuro ?? false,
      idioma: perfilData.idioma ?? 'español',
      publico_perfil: perfilData.publico_perfil ?? true
    };
  }
</script>

<svelte:head>
  <title>Configuración - Academia Vallenata</title>
  <meta name="description" content="Configura tus preferencias y ajustes de cuenta" />
</svelte:head>

<div class="contenido-configuracion">
  <div class="header-seccion">
    <h1>Configuración</h1>
    <p>Personaliza tu experiencia en Academia Vallenata</p>
  </div>

  <div class="configuracion-grid">
    <div class="seccion-config">
      <h2>🔔 Notificaciones</h2>
      <div class="opciones">
        <label class="opcion-toggle">
          <input 
            type="checkbox" 
            bind:checked={configuraciones.notificaciones_email}
          />
          <span class="toggle"></span>
          Notificaciones por email
        </label>
        
        <label class="opcion-toggle">
          <input 
            type="checkbox" 
            bind:checked={configuraciones.notificaciones_push}
          />
          <span class="toggle"></span>
          Notificaciones push
        </label>
      </div>
    </div>

    <div class="seccion-config">
      <h2>🎨 Apariencia</h2>
      <div class="opciones">
        <label class="opcion-toggle">
          <input 
            type="checkbox" 
            bind:checked={configuraciones.modo_oscuro}
            disabled
          />
          <span class="toggle"></span>
          Modo oscuro (próximamente)
        </label>
        
        <div class="opcion-select">
          <label>Idioma:</label>
          <select bind:value={configuraciones.idioma}>
            <option value="español">Español</option>
            <option value="english" disabled>English (próximamente)</option>
          </select>
        </div>
      </div>
    </div>

    <div class="seccion-config">
      <h2>🔒 Privacidad</h2>
      <div class="opciones">
        <label class="opcion-toggle">
          <input 
            type="checkbox" 
            bind:checked={configuraciones.publico_perfil}
          />
          <span class="toggle"></span>
          Perfil público
        </label>
      </div>
    </div>

    <div class="seccion-config">
      <h2>⚙️ Cuenta</h2>
      <div class="opciones">
        <button class="boton-accion-secundario" on:click={cerrarSesion}>
          🚪 Cerrar Sesión
        </button>
      </div>
    </div>
  </div>

  <div class="acciones-configuracion">
    <button 
      class="boton-guardar" 
      on:click={guardarConfiguracion}
      disabled={guardando}
    >
      {guardando ? 'Guardando...' : 'Guardar Configuración'}
    </button>
  </div>

  {#if mensaje}
    <div class="mensaje" class:exito={mensaje.includes('exitosamente')} class:error={mensaje.includes('Error')}>
      {mensaje}
    </div>
  {/if}
</div>

<style>
  .contenido-configuracion {
    padding: 2rem;
    max-width: 800px;
  }

  .header-seccion {
    margin-bottom: 3rem;
  }

  .header-seccion h1 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .header-seccion p {
    color: #6b7280;
    font-size: 1.1rem;
  }

  .configuracion-grid {
    display: grid;
    gap: 2rem;
    margin-bottom: 3rem;
  }

  .seccion-config {
    background: #f9fafb;
    border-radius: 12px;
    padding: 1.5rem;
    border: 1px solid #e5e7eb;
  }

  .seccion-config h2 {
    font-size: 1.25rem;
    font-weight: 600;
    color: #1f2937;
    margin-bottom: 1rem;
  }

  .opciones {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .opcion-toggle {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    cursor: pointer;
    font-weight: 500;
    color: #374151;
  }

  .opcion-toggle input {
    display: none;
  }

  .toggle {
    width: 44px;
    height: 24px;
    background: #d1d5db;
    border-radius: 12px;
    position: relative;
    transition: background-color 0.2s;
  }

  .toggle::before {
    content: '';
    position: absolute;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: white;
    top: 2px;
    left: 2px;
    transition: transform 0.2s;
  }

  .opcion-toggle input:checked + .toggle {
    background: #3b82f6;
  }

  .opcion-toggle input:checked + .toggle::before {
    transform: translateX(20px);
  }

  .opcion-toggle input:disabled + .toggle {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .opcion-select {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .opcion-select label {
    font-weight: 500;
    color: #374151;
    min-width: 60px;
  }

  .opcion-select select {
    padding: 0.5rem 0.75rem;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    background: white;
    font-size: 0.875rem;
  }

  .boton-accion-secundario {
    background: #ef4444;
    color: white;
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .boton-accion-secundario:hover {
    background: #dc2626;
  }

  .acciones-configuracion {
    text-align: center;
  }

  .boton-guardar {
    background: #3b82f6;
    color: white;
    padding: 1rem 2rem;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 1rem;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .boton-guardar:hover:not(:disabled) {
    background: #2563eb;
  }

  .boton-guardar:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .mensaje {
    margin-top: 1rem;
    padding: 1rem;
    border-radius: 8px;
    text-align: center;
    font-weight: 500;
  }

  .mensaje.exito {
    background: #d1fae5;
    color: #065f46;
    border: 1px solid #a7f3d0;
  }

  .mensaje.error {
    background: #fee2e2;
    color: #991b1b;
    border: 1px solid #fca5a5;
  }

  @media (max-width: 640px) {
    .contenido-configuracion {
      padding: 1rem;
    }
    
    .opcion-select {
      flex-direction: column;
      align-items: flex-start;
      gap: 0.5rem;
    }
  }
</style> 