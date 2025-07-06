<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import InfoPestañaPerfil from '$lib/components/PanelPrincipal/InfoPestañaPerfil.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import UltimosArticulosBlog from '$lib/components/Banners/UltimosArticulosBlog.svelte';

  export let data;
  
  // Extraer datos del servidor
  $: perfil = data.perfil;
  $: stats = data.stats;
  $: esUsuarioActual = data.esUsuarioActual;
  $: slug = data.slug;
  
  // Si es el usuario actual, redirigir a su perfil privado
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  
  onMount(() => {
    if (esUsuarioActual) {
      goto('/mi-perfil');
    }
  });
</script>

<svelte:head>
  <title>{perfil.nombre_completo || perfil.nombre_usuario || 'Usuario'} - Academia Vallenata</title>
  <meta name="description" content="Perfil de {perfil.nombre_completo || perfil.nombre_usuario} en Academia Vallenata" />
</svelte:head>

{#if !esUsuarioActual}
  <div class="layout-perfil-fijo">
    <!-- 🔒 ENCABEZADO FIJO - REUTILIZADO 100% -->
    <div class="encabezado-fijo">
      <EncabezadoPerfil 
        bind:nombreCompleto={perfil.nombre_completo} 
        bind:correoElectronico={perfil.correo_electronico} 
        bind:urlAvatar={perfil.url_foto_perfil} 
        bind:urlPortada={perfil.portada_url} 
        bind:posicionPortadaY={perfil.posicion_img_portada}
        userId={perfil.id}
        {stats}
        esEditable={false}
      />
    </div>
    
    <!-- 🔒 PESTAÑAS FIJAS - REUTILIZADAS 100% -->
    <div class="pestañas-fijas">
      <PestanasPerfil esPerfilPublico={true} usuarioSlug={slug} />
    </div>
    
    <!-- 🔄 CONTENIDO DINÁMICO - REUTILIZADO 100% -->
    <div class="contenido-dinamico">
      <div class="contenido-perfil-publico">
        <div class="layout-info-perfil">
          <div class="columna-formulario-principal">
            <InfoPestañaPerfil 
              perfil={perfil} 
              esEditable={false}
            />
          </div>
          <aside class="columna-widget-lateral">
            <div class="widgets-contenedor">
              <PorcentajePerfil {perfil} />
              <UltimosArticulosBlog />
            </div>
          </aside>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  /* Reutilizar estilos del layout original */
  .layout-perfil-fijo {
    max-width: 1500px;
    margin: 1rem auto;
    padding: 0;
    display: flex;
    flex-direction: column;
  }

  .encabezado-fijo {
    position: relative;
    z-index: 100;
    background: #ffffff;
    border-radius: 16px;
    margin-bottom: 1rem;
    overflow: hidden;
  }

  .pestañas-fijas {
    position: sticky;
    top: 80px;
    z-index: 50;
    background: #ffffff;
    border-radius: 16px;
    margin-bottom: 1rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  }

  .contenido-dinamico {
    background: #ffffff;
    border-radius: 16px;
    min-height: 500px;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
  }

  .contenido-perfil-publico {
    padding: 2rem;
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
    .contenido-perfil-publico {
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
    .contenido-perfil-publico {
      padding: 1rem;
    }
  }
</style> 