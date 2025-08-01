<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import { onMount } from 'svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { page } from '$app/stores';
  import { beforeNavigate, afterNavigate } from '$app/navigation';
  import ProteccionAutenticacion from '$lib/guards/ProteccionAutenticacion.svelte';

  // Reactive statements para obtener datos del store
  $: perfilData = $perfilStore.perfil;
  $: statsData = $perfilStore.stats;
  $: cargandoDatos = $perfilStore.cargando;
  $: datosDisponibles = $perfilStore.inicializado && perfilData;

  // Variable para mantener la posición del scroll
  let scrollPositionY = 0;
  
  // Estado del modal de imágenes (para ocultar pestañas)
  let modalImagenAbierto = false;

  // Emergency fallback después de mucho tiempo cargando
  let mostrarFallback = false;
  
  // Activar fallback después de 20 segundos de carga
  $: if (cargandoDatos) {
    setTimeout(() => {
      if ($perfilStore.cargando) {
        console.warn('⚠️ [LAYOUT PERFIL] Activando emergency fallback después de 20s');
        mostrarFallback = true;
      }
    }, 20000);
  } else {
    mostrarFallback = false;
  }

  onMount(async () => {
    console.log('🚀 [LAYOUT PERFIL] Montando componente, estado del store:', $perfilStore);
    
    // Cargar datos del perfil con timeout
    try {
      const cargarPromise = perfilStore.cargarDatosPerfil(false);
      const timeoutPromise = new Promise((_, reject) => 
        setTimeout(() => reject(new Error('Timeout del layout')), 15000) // 15 segundos
      );
      
      await Promise.race([cargarPromise, timeoutPromise]);
      console.log('✅ [LAYOUT PERFIL] Datos cargados exitosamente');
    } catch (error) {
      console.error('❌ [LAYOUT PERFIL] Error/timeout cargando datos:', error);
      // Si hay timeout, forzar que el store se marque como inicializado para que no se quede cargando
      perfilStore.forzarInicializacion();
    }
  });

  // Interceptar navegaciones para mantener scroll
  beforeNavigate(({ from, to }) => {
    // Solo para navegaciones dentro del perfil
    const rutasPerfil = ['/mi-perfil', '/mis-cursos', '/mis-eventos', '/publicaciones', '/grabaciones', '/configuracion'];
    
    if (from && to && 
        rutasPerfil.some(ruta => from.url.pathname.includes(ruta)) &&
        rutasPerfil.some(ruta => to.url.pathname.includes(ruta))) {
      // Guardar posición actual del scroll
      scrollPositionY = window.scrollY;
    }
  });

  afterNavigate(({ from, to }) => {
    // Solo para navegaciones dentro del perfil
    const rutasPerfil = ['/mi-perfil', '/mis-cursos', '/mis-eventos', '/publicaciones', '/grabaciones', '/configuracion'];
    
    if (from && to && 
        rutasPerfil.some(ruta => from.url.pathname.includes(ruta)) &&
        rutasPerfil.some(ruta => to.url.pathname.includes(ruta))) {
      // Restaurar posición del scroll después de la navegación
      requestAnimationFrame(() => {
        window.scrollTo(0, scrollPositionY);
      });
    }
  });

  // Función para manejar el cambio de estado del modal
  function handleModalStateChange(event: CustomEvent<{ modalAbierto: boolean }>) {
    modalImagenAbierto = event.detail.modalAbierto;
  }
</script>

<ProteccionAutenticacion 
  titulo="🔒 PERFIL RESTRINGIDO"
  mensajePrincipal="Tu perfil personal requiere que inicies sesión">
  
  <div class="layout-perfil-fijo">
    <!-- 🔒 ENCABEZADO FIJO - NO CAMBIA ENTRE PÁGINAS -->
    <div class="encabezado-fijo">
      {#if datosDisponibles}
        <EncabezadoPerfil 
          nombreCompleto={perfilData!.nombre_completo} 
          urlAvatar={perfilData!.url_foto_perfil} 
          urlPortada={perfilData!.portada_url} 
          posicionPortadaY={perfilData!.posicion_img_portada || 50}
          userId={perfilData!.id}
          stats={statsData}
          on:modalStateChange={handleModalStateChange}
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
    <div class="pestañas-fijas" class:ocultar-pestanas={modalImagenAbierto}>
      <PestanasPerfil modalAbierto={modalImagenAbierto} />
    </div>
    
    <!-- 🔄 CONTENIDO DINÁMICO - CAMBIA SEGÚN LA PÁGINA -->
    <div class="contenido-dinamico">
      {#if datosDisponibles}
        <slot />
      {:else if cargandoDatos && !mostrarFallback}
        <div class="contenido-cargando">
          <div class="spinner"></div>
          <p>Cargando información del perfil...</p>
        </div>
      {:else if mostrarFallback || (!cargandoDatos && !datosDisponibles)}
        <div class="contenido-fallback">
          <div class="fallback-mensaje">
            <h2>🎵 Academia Vallenata</h2>
            <p>Continuando con tu aprendizaje...</p>
          </div>
          <slot />
        </div>
      {:else}
        <div class="contenido-error">
          <p>No se pudo cargar el contenido del perfil</p>
          <button on:click={() => perfilStore.cargarDatosPerfil(true)} class="btn-reintentar">
            Reintentar
          </button>
        </div>
      {/if}
    </div>
  </div>
</ProteccionAutenticacion>

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
    transition: opacity 0.3s ease, visibility 0.3s ease;
  }

  /* Ocultar pestañas cuando el modal está abierto */
  .pestañas-fijas.ocultar-pestanas {
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
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

  .contenido-fallback {
    padding: 1rem;
  }

  .fallback-mensaje {
    text-align: center;
    padding: 2rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    color: white;
    margin-bottom: 2rem;
  }

  .fallback-mensaje h2 {
    margin: 0 0 0.5rem 0;
    font-size: 1.5rem;
    font-weight: 700;
  }

  .fallback-mensaje p {
    margin: 0;
    opacity: 0.9;
    font-size: 1.1rem;
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
  @media (max-width: 900px) {
    .layout-perfil-fijo {
      margin: 0; /* Sin márgenes en móviles - estilo Facebook */
      padding: 0;
      max-width: 100%;
    }
    
    .encabezado-fijo {
      border-radius: 0; /* Sin border-radius en móviles - estilo Facebook */
      margin-bottom: 0;
    }
    
    .pestañas-fijas {
      top: 60px; /* Ajuste para móviles */
      border-radius: 0; /* Sin border-radius en móviles */
      margin-bottom: 0;
    }
    
    .contenido-dinamico {
      border-radius: 0; /* Sin border-radius en móviles */
    }
  }
  
  @media (max-width: 768px) {
    .pestañas-fijas {
      top: 60px; /* Ajuste para móviles */
    }
  }
</style> 