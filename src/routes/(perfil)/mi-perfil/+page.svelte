<script lang="ts">
  import InfoPestañaPerfil from '$lib/components/PanelPrincipal/InfoPestañaPerfil.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import UltimosArticulosBlog from '$lib/components/Banners/UltimosArticulosBlog.svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { perfilStore } from '$lib/stores/perfilStore';

  // Usar datos del store en lugar de cargar por separado
  $: perfilData = $perfilStore.perfil;
  $: statsData = $perfilStore.stats;
  $: cargandoPerfil = $perfilStore.cargando;

  async function handleUpdate(event: any) {
    const perfilActualizado = event.detail;
    
    if (perfilActualizado.nivel_habilidad) {
      perfilActualizado.nivel_habilidad = perfilActualizado.nivel_habilidad.toLowerCase();
    }
    
    const datosActualizados = { ...perfilData, ...perfilActualizado };

    const { id, ...datosParaActualizar } = datosActualizados;

    const { error } = await supabase
      .from('perfiles')
      .update(datosParaActualizar)
      .eq('id', id);
      
    if (error) {
      console.error('Error actualizando perfil:', error.message);
      alert(`Hubo un error al actualizar tu perfil: ${error.message}`);
    } else {
      console.log('¡Perfil actualizado correctamente!');
      // Actualizar el store con los nuevos datos
      perfilStore.actualizarPerfil(perfilActualizado);
    }
  }
</script>

<svelte:head>
  <title>Mi Perfil - Academia Vallenata</title>
  <meta name="description" content="Gestiona tu perfil personal y preferencias en Academia Vallenata" />
</svelte:head>

<div class="contenido-mi-perfil">
  {#if perfilData}
    <div class="layout-info-perfil">
      <div class="columna-formulario-principal">
        <InfoPestañaPerfil bind:perfil={perfilData} on:actualizar={handleUpdate} />
      </div>
      <aside class="columna-widget-lateral">
        <div class="widgets-contenedor">
          <PorcentajePerfil perfil={perfilData} />
          <UltimosArticulosBlog />
        </div>
      </aside>
    </div>
  {:else}
    <div class="estado-carga">
      <div class="spinner-carga"></div>
      <p>Preparando información del perfil...</p>
    </div>
  {/if}
</div>

<style>
  .contenido-mi-perfil {
    padding: 2rem;
  }

  .estado-carga {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    gap: 1.5rem;
  }

  .spinner-carga {
    width: 50px;
    height: 50px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .estado-carga p {
    color: #64748b;
    font-weight: 500;
  }

  .layout-info-perfil {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 2.5rem;
    align-items: start;
  }

  .columna-formulario-principal {
    min-width: 0;
  }

  .columna-widget-lateral {
    position: sticky;
    top: 2rem;
  }

  .widgets-contenedor {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }
  
  @media (max-width: 900px) {
    .contenido-mi-perfil {
      padding: 1.5rem;
    }

    .layout-info-perfil {
      grid-template-columns: 1fr;
      gap: 2rem;
    }

    .columna-widget-lateral {
      order: 1;
      position: static;
    }

    .columna-formulario-principal {
      order: 0;
    }
  }

  @media (max-width: 640px) {
    .contenido-mi-perfil {
      padding: 1rem;
    }
  }
</style> 