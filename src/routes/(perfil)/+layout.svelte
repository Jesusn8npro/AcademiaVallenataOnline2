<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import { onMount } from 'svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { page } from '$app/stores';
  import { beforeNavigate, afterNavigate } from '$app/navigation';

  // Reactive statements para obtener datos del store
  $: perfilData = $perfilStore.perfil;
  $: statsData = $perfilStore.stats;
  $: cargandoDatos = $perfilStore.cargando;
  $: datosDisponibles = $perfilStore.inicializado && perfilData;

  // Variable para mantener la posición del scroll
  let scrollPositionY = 0;

  onMount(async () => {
    // Solo cargar datos si no están inicializados
    if (!$perfilStore.inicializado) {
      await perfilStore.cargarDatosPerfil();
    }
  });

  // Interceptar navegaciones para mantener scroll
  beforeNavigate(({ from, to }) => {
    // Solo para navegaciones dentro del perfil
    const rutasPerfil = ['/mi-perfil', '/mis-cursos', '/publicaciones', '/configuracion'];
    
    if (from && to && 
        rutasPerfil.some(ruta => from.url.pathname.includes(ruta)) &&
        rutasPerfil.some(ruta => to.url.pathname.includes(ruta))) {
      // Guardar posición actual del scroll
      scrollPositionY = window.scrollY;
    }
  });

  afterNavigate(({ from, to }) => {
    // Solo para navegaciones dentro del perfil
    const rutasPerfil = ['/mi-perfil', '/mis-cursos', '/publicaciones', '/configuracion'];
    
    if (from && to && 
        rutasPerfil.some(ruta => from.url.pathname.includes(ruta)) &&
        rutasPerfil.some(ruta => to.url.pathname.includes(ruta))) {
      // Restaurar posición del scroll después de la navegación
      requestAnimationFrame(() => {
        window.scrollTo(0, scrollPositionY);
      });
    }
  });
</script>

<div class="layout-perfil-fijo">
  <!-- 🔒 ENCABEZADO FIJO - NO CAMBIA ENTRE PÁGINAS -->
  <div class="encabezado-fijo">
    {#if datosDisponibles}
      <EncabezadoPerfil 
        bind:nombreCompleto={perfilData!.nombre_completo} 
        bind:correoElectronico={perfilData!.correo_electronico} 
        bind:urlAvatar={perfilData!.url_foto_perfil} 
        bind:urlPortada={perfilData!.portada_url} 
        bind:posicionPortadaY={perfilData!.posicion_img_portada}
        userId={perfilData!.id}
        stats={statsData}
      />
    {:else if cargandoDatos}
      <div class="encabezado-cargando">
        <div class="spinner"></div>
        <p>Cargando perfil...</p>
      </div>
    {:else}
      <div class="encabezado-error">
        <p>Error al cargar el perfil</p>
        <button on:click={() => perfilStore.cargarDatosPerfil(true)} class="btn-reintentar">
          Reintentar
        </button>
      </div>
    {/if}
  </div>
  
  <!-- 🔒 PESTAÑAS FIJAS - NO CAMBIAN ENTRE PÁGINAS -->
  <div class="pestañas-fijas">
    <PestanasPerfil />
  </div>
  
  <!-- 🔄 CONTENIDO DINÁMICO - CAMBIA SEGÚN LA PÁGINA -->
  <div class="contenido-dinamico">
    {#if datosDisponibles}
      <slot />
    {:else if cargandoDatos}
      <div class="contenido-cargando">
        <div class="spinner"></div>
        <p>Cargando información del perfil...</p>
      </div>
    {:else}
      <div class="contenido-error">
        <p>No se pudo cargar el contenido del perfil</p>
      </div>
    {/if}
  </div>
</div>

<style>
  .layout-perfil-fijo {
    max-width: 1500px;
    margin: 2rem auto;
    padding: 0;
    display: flex;
    flex-direction: column;
  }

  .encabezado-fijo {
    /* 🔒 FIJO - No se mueve entre navegaciones */
    position: relative;
    z-index: 10;
    background: #ffffff;
    border-radius: 16px;
    margin-bottom: 1rem;
  }

  .pestañas-fijas {
    /* 🔒 FIJO - Las pestañas se mantienen siempre visibles */
    position: sticky;
    top: 80px; /* Ajusta según la altura de tu header */
    z-index: 20;
    background: #ffffff;
    border-radius: 16px;
    margin-bottom: 1rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  }

  .contenido-dinamico {
    /* 🔄 DINÁMICO - Solo esta parte cambia */
    background: #ffffff;
    border-radius: 16px;
    min-height: 500px;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
    /* Sin transiciones para evitar el efecto fade */
  }

  .encabezado-cargando,
  .contenido-cargando {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem 2rem;
    gap: 1rem;
  }

  .encabezado-error,
  .contenido-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    gap: 1rem;
    color: #dc2626;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .encabezado-cargando p,
  .contenido-cargando p {
    color: #6b7280;
    font-weight: 500;
  }

  .btn-reintentar {
    background: #3b82f6;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 8px;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .btn-reintentar:hover {
    background: #2563eb;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .layout-perfil-fijo {
      margin: 1rem;
      padding: 0;
    }
    
    .pestañas-fijas {
      top: 60px; /* Ajuste para móviles */
    }
  }
</style> 