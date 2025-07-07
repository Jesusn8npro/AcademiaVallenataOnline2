<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { beforeNavigate, afterNavigate } from '$app/navigation';

  export let data: any;
  
  // 📊 Datos reactivos del usuario público
  $: usuarioPublico = data?.usuarioPublico;
  $: rutaActual = $page.url.pathname;
  $: slugUsuario = $page.params.slug;
  
  // Estado para controlar si el modal de imagen está abierto
  let modalImagenAbierto = false;
  
  // Variable para mantener la posición del scroll entre pestañas
  let scrollPositionY = 0;

  // ⚡ Perfil adaptado para el componente EncabezadoPerfil
  $: perfilAdaptado = (() => {
    if (!usuarioPublico || typeof usuarioPublico !== 'object') {
      return null;
    }
    
    return {
      // Datos básicos
      id: usuarioPublico.id,
      nombre_completo: usuarioPublico.nombre_completo || `${usuarioPublico.nombre || ''} ${usuarioPublico.apellido || ''}`.trim() || 'Usuario',
      correo_electronico: usuarioPublico.correo_electronico,
      url_foto_perfil: usuarioPublico.url_foto_perfil,
      portada_url: usuarioPublico.portada_url,
      posicion_img_portada: usuarioPublico.posicion_img_portada || 50,
      
      // Biografía y ubicación
      biografia: usuarioPublico.biografia,
      ciudad: usuarioPublico.ciudad,
      pais: usuarioPublico.pais,
      whatsapp: usuarioPublico.whatsapp,
      fecha_creacion: usuarioPublico.fecha_creacion,
      
      // Rol y suscripción
      rol: usuarioPublico.rol,
      suscripcion: usuarioPublico.suscripcion
    };
  })();

  // 📊 Stats adaptadas para el usuario público
  $: statsAdaptadas = {
    publicaciones: usuarioPublico?.estadisticas?.publicaciones || 0,
    cursos: usuarioPublico?.estadisticas?.cursos_creados || 0,
    tutoriales: 0, // Por ahora no tenemos este dato
    ranking: 0 // Por ahora no tenemos este dato
  };

  // Interceptar navegaciones para mantener scroll entre pestañas
  beforeNavigate(({ from, to }) => {
    const rutasUsuario = [`/usuarios/${slugUsuario}`, `/usuarios/${slugUsuario}/actividad`, `/usuarios/${slugUsuario}/publicaciones`];
    
    if (from && to && 
        rutasUsuario.some(ruta => from.url.pathname === ruta) &&
        rutasUsuario.some(ruta => to.url.pathname === ruta)) {
      scrollPositionY = window.scrollY;
    }
  });

  afterNavigate(({ from, to }) => {
    const rutasUsuario = [`/usuarios/${slugUsuario}`, `/usuarios/${slugUsuario}/actividad`, `/usuarios/${slugUsuario}/publicaciones`];
    
    if (from && to && 
        rutasUsuario.some(ruta => from.url.pathname === ruta) &&
        rutasUsuario.some(ruta => to.url.pathname === ruta)) {
      requestAnimationFrame(() => {
        window.scrollTo(0, scrollPositionY);
      });
    }
  });

  // Función para manejar el cambio de estado del modal
  function manejarModalImagen(event: CustomEvent) {
    modalImagenAbierto = event.detail.abierto;
  }

  onMount(() => {
    // Actualizar el título de la página
    if (perfilAdaptado?.nombre_completo) {
      document.title = `${perfilAdaptado.nombre_completo} - Academia Vallenata`;
    }
  });
</script>

<svelte:head>
  {#if perfilAdaptado}
    <title>{perfilAdaptado.nombre_completo} - Academia Vallenata</title>
    <meta name="description" content="Perfil de {perfilAdaptado.nombre_completo} en Academia Vallenata" />
    <meta property="og:title" content="{perfilAdaptado.nombre_completo} - Academia Vallenata" />
    <meta property="og:description" content="Perfil de {perfilAdaptado.nombre_completo} en Academia Vallenata" />
    {#if perfilAdaptado.url_foto_perfil}
      <meta property="og:image" content="{perfilAdaptado.url_foto_perfil}" />
    {/if}
  {/if}
</svelte:head>

{#if data === undefined}
  <!-- Estado de loading inicial -->
  <div class="loading-container">
    <div class="spinner"></div>
    <p>Cargando perfil...</p>
  </div>
{:else if perfilAdaptado}
  <div class="layout-perfil-publico">
    
    <!-- 🔒 ENCABEZADO FIJO - NO CAMBIA ENTRE PESTAÑAS -->
    <div class="encabezado-fijo">
      <EncabezadoPerfil 
        urlPortada={perfilAdaptado.portada_url || ''}
        urlAvatar={perfilAdaptado.url_foto_perfil || ''}
        nombreCompleto={perfilAdaptado.nombre_completo}
        correoElectronico={perfilAdaptado.correo_electronico || ''}
        posicionPortadaY={perfilAdaptado.posicion_img_portada}
        userId={null}
        stats={statsAdaptadas}
        nivelUsuario={usuarioPublico?.nivel_usuario || 1}
        rolUsuario={(() => {
          const rol = usuarioPublico?.rol?.toLowerCase();
          if (rol === 'admin' || rol === 'administrador' || rol === 'administrator') {
            return 'Administrador';
          } else if (rol === 'instructor' || rol === 'teacher') {
            return 'Instructor';
          } else if (rol === 'moderator' || rol === 'moderador') {
            return 'Moderador';
          } else {
            return 'Estudiante';
          }
        })()}
        suscripcionUsuario={usuarioPublico?.suscripcion || 'Free'}
        esPerfilPublico={true}
        fechaCreacion={usuarioPublico?.fecha_creacion || null}
        slugUsuario={slugUsuario}
        on:modalImagenCambiado={manejarModalImagen}
      />
    </div>
    
    <!-- 🔒 PESTAÑAS FIJAS - NO CAMBIAN ENTRE PESTAÑAS -->
    <div class="pestanas-fijas" class:ocultar-pestanas={modalImagenAbierto}>
      <PestanasPerfil 
        modalAbierto={modalImagenAbierto}
        modoPublico={true}
        slugUsuario={slugUsuario}
      />
    </div>
    
    <!-- 🔄 CONTENIDO DINÁMICO - CAMBIA SEGÚN LA PESTAÑA -->
    <div class="contenido-dinamico">
      <slot />
    </div>
  </div>
{:else}
  <!-- Error: Usuario no encontrado -->
  <div class="error-carga">
    <h1>👤 Usuario no encontrado</h1>
    <p>El perfil "<strong>{slugUsuario}</strong>" no existe o no está disponible públicamente.</p>
    <a href="/comunidad" class="btn-volver">🔙 Volver a la Comunidad</a>
    
    <!-- Debug info solo en desarrollo -->
    {#if process.env.NODE_ENV === 'development'}
      <details class="debug-info">
        <summary>🔧 Debug Info</summary>
        <pre>{JSON.stringify({ data, usuarioPublico, perfilAdaptado }, null, 2)}</pre>
      </details>
    {/if}
  </div>
{/if}

<style>
  .layout-perfil-publico {
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
    margin-bottom: 2.5rem;
  }

  .pestanas-fijas {
    /* 🔒 FIJO - Las pestañas se mantienen siempre visibles */
    position: sticky;
    top: 80px; /* Ajusta según la altura de tu header */
    z-index: 20;
    background: #ffffff;
    border-radius: 16px;
    margin-bottom: 1rem;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
    transition: opacity 0.3s ease, visibility 0.3s ease;
    width: 100%;
  }

  /* Ocultar pestañas cuando el modal de imagen está abierto */
  .pestanas-fijas.ocultar-pestanas {
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
  }

  .contenido-dinamico {
    /* 🔄 DINÁMICO - Solo esta parte cambia entre pestañas */
    background: #ffffff;
    border-radius: 16px;
    min-height: 500px;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.04);
    overflow: hidden;
  }

  /* Estados de carga y error */
  .loading-container {
    min-height: 60vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 3rem 2rem;
    gap: 1rem;
  }

  .error-carga {
    min-height: 60vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    padding: 3rem 2rem;
    gap: 1.5rem;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    border-radius: 16px;
    margin: 2rem auto;
    max-width: 600px;
  }

  .error-carga h1 {
    font-size: 2.5rem;
    color: #1f2937;
    margin: 0;
    font-weight: 700;
  }

  .error-carga p {
    color: #6b7280;
    font-size: 1.1rem;
    line-height: 1.6;
    max-width: 400px;
    margin: 0;
  }

  .btn-volver {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    font-size: 1rem;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  }

  .btn-volver:hover {
    background: linear-gradient(135deg, #2563eb, #1e40af);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
  }

  .spinner {
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

  .loading-container p {
    color: #6b7280;
    font-weight: 500;
    font-size: 1.1rem;
  }

  /* Debug info */
  .debug-info {
    margin-top: 2rem;
    padding: 1rem;
    background: #f3f4f6;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    font-size: 0.875rem;
    max-width: 100%;
  }

  .debug-info summary {
    cursor: pointer;
    font-weight: 600;
    margin-bottom: 0.5rem;
    color: #374151;
  }

  .debug-info pre {
    background: white;
    padding: 1rem;
    border-radius: 6px;
    overflow-x: auto;
    font-size: 0.75rem;
    color: #1f2937;
    border: 1px solid #e5e7eb;
  }

  /* Responsive */
  @media (max-width: 900px) {
    .layout-perfil-publico {
      margin: 0; /* Sin márgenes en móviles - estilo Facebook */
      padding: 0;
      max-width: 100%;
    }
    
    .encabezado-fijo {
      border-radius: 0; /* Sin border-radius en móviles - estilo Facebook */
      margin-bottom: 1rem;
    }
    
    .pestanas-fijas {
      top: 60px; /* Ajuste para móviles */
      border-radius: 0; /* Sin border-radius en móviles */
      margin-bottom: 0;
      margin-left: calc(-50vw + 50%); /* Compensar el centrado del contenedor */
      margin-right: calc(-50vw + 50%); /* Compensar el centrado del contenedor */
      width: 100vw; /* Ancho completo de la pantalla */
    }
    
    .contenido-dinamico {
      border-radius: 0; /* Sin border-radius en móviles */
    }
  }
  
  @media (max-width: 768px) {
    .pestanas-fijas {
      top: 60px; /* Ajuste para móviles */
    }

    .error-carga {
      margin: 1rem auto;
      padding: 2rem 1.5rem;
    }

    .error-carga h1 {
      font-size: 2rem;
    }
  }

  @media (max-width: 480px) {
    .error-carga {
      padding: 1.5rem 1rem;
    }

    .error-carga h1 {
      font-size: 1.75rem;
    }

    .btn-volver {
      padding: 10px 20px;
      font-size: 0.9rem;
    }
  }
</style> 