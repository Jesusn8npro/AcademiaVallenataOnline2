<script lang="ts">
  import EncabezadoLeccion from '$lib/components/VisualiizadorDeLeccionesDeCursos/EncabezadoLeccion.svelte';
  import BarraLateralCurso from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraLateralCurso.svelte';
  import ReproductorLecciones from '$lib/components/VisualiizadorDeLeccionesDeCursos/ReproductorLecciones.svelte';
  import LeccionTabs from '$lib/components/VisualiizadorDeLeccionesDeCursos/LeccionTabs.svelte';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { get } from 'svelte/store';
  import { progresoLecciones } from '$lib/progresoLeccionesStore';
  import { actualizarProgresoTutorial } from '$lib/services/progresoTutorialService';
  import { actualizarProgresoLeccion } from '$lib/services/progresoService';

  // --- Props y datos principales ---
  export let data: any;
  const { tutorial, clase, modulos_preview } = data;
  let usuarioActual: any = null;
  $: usuarioActual = get(estadoUsuarioActual).user;

  // --- Estado de completado y sidebar ---
  let completada = false;
  let loadingCompletar = false;
  let errorCompletar = '';
  let tipo: 'clase' | 'leccion' = 'clase';
  let mostrarSidebar = true;
  let windowWidth = 0;

  // --- Responsive Sidebar ---

// Maneja el cambio de lección/clase desde los botones de navegación y la barra lateral
import { generateSlug } from '$lib/utilidades/utilidadesSlug';

function cambiarLeccion(event: any) {
  const leccion = event.detail?.leccion;
  if (!leccion) return;
  let leccionSlug = leccion.slug || (leccion.titulo ? generateSlug(leccion.titulo) : null) || leccion.id;
  if (!leccionSlug) {
    console.warn('No se pudo determinar el slug de la lección para navegar:', leccion);
    return;
  }
  const tutorialSlug = tutorial.slug || (tutorial.titulo ? generateSlug(tutorial.titulo) : tutorial.id);
  if (!tutorialSlug) {
    console.warn('No se pudo determinar el slug del tutorial para navegar:', tutorial);
    return;
  }
  // Forzar recarga completa
  window.location.href = `/tutoriales/${tutorialSlug}/clase/${leccionSlug}`;
}

  // Esconder BarraLateralCurso en Version responsiva
  onMount(() => {
    windowWidth = window.innerWidth;
    if (windowWidth < 1450) {
      mostrarSidebar = false;
    }
    const handleResize = () => {
      windowWidth = window.innerWidth;
      if (windowWidth < 1450) {
        mostrarSidebar = false;
      }
    };
    window.addEventListener('resize', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  });
  function toggleSidebar() {
    console.log('🔧 [TUTORIAL] Cerrando sidebar móvil');
    mostrarSidebar = !mostrarSidebar;
  }

  // Función específica para cerrar (desde el botón X)
  function cerrarSidebar() {
    console.log('❌ [TUTORIAL] Cerrando sidebar desde botón X');
    mostrarSidebar = false;
  }

  // Store reactivo para el progreso general (por lección)
  // Usar solo el store global importado

  // Verificar si la lección o clase ya está completada y refrescar progreso general
  async function verificarCompletadaYProgreso() {
    if (!clase?.id || !usuarioActual) return;
    try {
      if (tipo === 'leccion') {
        const { data } = await import('$lib/services/progresoService').then(m => m.obtenerProgresoLeccion(clase.id));
        completada = !!(data && data.completada);
      } else {
        const { data } = await import('$lib/services/progresoTutorialService').then(m => m.obtenerProgresoTutorialDeParte(clase.id));
        completada = !!(data && data.completada);
      }
      // Refresca el progreso general
      await refrescarProgresoLecciones();
    } catch (e) {
      completada = false;
    }
  }
  $: verificarCompletadaYProgreso();

  // Refresca el progreso general de todas las lecciones del tutorial
  async function refrescarProgresoLecciones() {
    console.log('Llamando a refrescarProgresoLecciones');
    if (!tutorial?.id || !usuarioActual) return;
    try {
      const { data } = await import('$lib/services/progresoTutorialService').then(m => m.obtenerProgresoTutorial(tutorial.id));
      if (data) {
        console.log('Datos recibidos de progresoTutorialService:', data);
        // Crea un mapeo de parte_id -> completado/progreso y progreso global del tutorial
        const progresoMap: any = {};
        
        // Si hay detalles de progreso, mapearlos correctamente
        if (data.detalle && data.detalle.length > 0) {
          data.detalle.forEach((item: any) => {
            // Usar el campo correcto: parte_tutorial_id y completado
            progresoMap[item.parte_tutorial_id] = item.completado ? 100 : 0;
          });
        }
        
        // Progreso global del tutorial (usa SIEMPRE los valores reales del backend)
        progresoMap[tutorial.id] = {
          partes_completadas: data.partes_completadas || 0,
          total_partes: data.total_partes || 0,
          progreso: data.progreso || 0
        };
        
        progresoLecciones.set(progresoMap);
        console.log('Nuevo valor del store progresoLecciones:', progresoMap);
      } else {
        // Si no hay datos, inicializar con valores por defecto
        const progresoMap: any = {};
        progresoMap[tutorial.id] = {
          partes_completadas: 0,
          total_partes: 0,
          progreso: 0
        };
        progresoLecciones.set(progresoMap);
      }
    } catch (e: any) {
      console.error('Error al refrescar progreso de tutorial:', e);
      // En caso de error, inicializar con valores por defecto
      const progresoMap: any = {};
      progresoMap[tutorial.id] = {
        partes_completadas: 0,
        total_partes: 0,
        progreso: 0
      };
      progresoLecciones.set(progresoMap);
    }
  }

  // Marcar como completada
  async function marcarComoCompletada() {
    loadingCompletar = true;
    errorCompletar = '';
    try {
      let res: { error?: { message: string; payload?: any } } = {};
      // Mostrar los IDs clave para depuración
      console.log('[DEBUG] usuario_id:', usuarioActual?.id, 'tutorial_id:', tutorial?.id, 'parte_tutorial_id:', clase?.id);
      if (!usuarioActual?.id || !tutorial?.id || !clase?.id) {
        errorCompletar = `Faltan datos clave: usuario_id=${usuarioActual?.id}, tutorial_id=${tutorial?.id}, parte_tutorial_id=${clase?.id}`;
        loadingCompletar = false;
        return;
      }
      if (tipo === 'leccion') {
        res = await actualizarProgresoLeccion(clase.id, true);
      } else {
        res = await actualizarProgresoTutorial(clase.id, true, tutorial.id);
      }
      if (res.error) {
        // Si el error tiene payload, muéstralo
        if (res.error.payload) {
          errorCompletar = `${res.error.message}. Payload: ${JSON.stringify(res.error.payload)}`;
        } else {
          errorCompletar = res.error.message || 'Error al marcar como completada';
        }
      } else {
        completada = true;
        if (!res.error) {
          // Refresca el progreso después de marcar como completada
          await refrescarProgresoLecciones();
        }
      }
    } catch (e: any) {
      // Mostrar el error real en pantalla y consola
      errorCompletar = `Error inesperado: ${e?.message || e?.toString()}`;
      console.error('[ERROR marcarComoCompletada]', e);
    } finally {
      loadingCompletar = false;
    }
  }

</script>

<EncabezadoLeccion 
  cursoTitulo={tutorial?.titulo}
  leccionTitulo={clase?.titulo}
  cursoId={tutorial?.id}
  leccionId={clase?.id}
  tipo={tipo}
  usuarioActual={usuarioActual}
  mostrarSidebar={mostrarSidebar}
  leccionAnterior={data.claseAnterior}
  leccionSiguiente={data.claseSiguiente}
  onToggleSidebar={toggleSidebar}
  curso={{ ...tutorial, clases_tutorial: data.clases }}
  moduloActivo={''}
  progreso={$progresoLecciones}
/>

<div class="contenido-container" class:sidebar-visible={mostrarSidebar}>
  <div class="contenido-principal">
    <ReproductorLecciones
      leccionAnterior={data.claseAnterior}
      leccionSiguiente={data.claseSiguiente}
      videoUrl={clase?.video_url}
      titulo={clase?.titulo}
      thumbnailUrl={clase?.thumbnail_url || ''}
      tipo={tipo}
      completada={completada}
      cargandoCompletar={loadingCompletar}
      marcarComoCompletada={marcarComoCompletada}
      errorCompletar={errorCompletar}
      on:anterior-leccion={cambiarLeccion}
      on:siguiente-leccion={cambiarLeccion}
    />

    <LeccionTabs
      contenido={clase?.contenido}
      objetivos={clase?.objetivos}
      recursos={clase?.recursos}
      comentarios={data.comentarios}
      cursoDescripcionCorta={tutorial?.descripcion_corta}
      cursoId={tutorial?.id}
      usuarioActual={usuarioActual}
      leccionId={clase?.id}
      tipo={tipo}
      cursoTitulo={tutorial?.titulo}
      cursoImagenUrl={tutorial?.imagen_url}
      cursoCategoria={tutorial?.categoria}
      cursoNivel={tutorial?.nivel}
      cursoDuracion={tutorial?.duracion_estimada || tutorial?.duracion}
      cursoArtista={tutorial?.artista}
      cursoAcordeonista={tutorial?.acordeonista}
      clases={data.clases}
      leccionActiva={clase?.id}
      progreso={$progresoLecciones}
      mostrarSidebar={mostrarSidebar}
      curso={tutorial}
      on:cambiar-leccion={cambiarLeccion}
    />

  </div>
  <!-- OVERLAY móvil que FUNCIONA (igual que EncabezadoLeccion) -->
  {#if mostrarSidebar}
    <div class="sidebar-mobile-overlay" on:click={() => mostrarSidebar = false}>
      <div class="sidebar-mobile-panel" on:click|stopPropagation>
        <BarraLateralCurso
          curso={{
            ...tutorial,
            clases_tutorial: data.clases
          }}
          moduloActivo={''}
          leccionActiva={clase?.id}
          progreso={$progresoLecciones}
          on:cambiar-leccion={cambiarLeccion}
          on:cerrar-sidebar={cerrarSidebar}
          cerrarSidebarFuncion={cerrarSidebar}
          bind:mostrarSidebar
          tipo="tutorial"
        />
      </div>
    </div>
  {/if}
  
  <!-- SIDEBAR original (mantener para desktop) -->
  <div class="leccion-sidebar" class:visible={mostrarSidebar}>
    <BarraLateralCurso
      curso={{
        ...tutorial,
        clases_tutorial: data.clases
      }}
      moduloActivo={''}
      leccionActiva={clase?.id}
      progreso={$progresoLecciones}
      on:cambiar-leccion={cambiarLeccion}
      on:cerrar-sidebar={cerrarSidebar}
      cerrarSidebarFuncion={cerrarSidebar}
      bind:mostrarSidebar
      tipo="tutorial"
    />
  </div>
</div>

<style>
  .contenido-container {
    display: flex;
    flex: 1;
    background: #f4f6fa;
  }
  
  /* ✅ MÓVILES: Layout fijo estilo Platzi */
  @media (max-width: 900px) {
    .contenido-container {
      height: 100vh; /* FORZAR altura fija de viewport */
      max-height: 100vh; /* NO puede ser más alto */
      overflow: hidden; /* SIN SCROLL en el contenedor principal */
    }
  }
  
  /* ✅ ESCRITORIO: Layout con scroll natural */
  @media (min-width: 901px) {
    .contenido-container {
      min-height: 100vh; /* MÍNIMO una pantalla, pero puede crecer */
      overflow: visible; /* PERMITIR SCROLL NATURAL */
    }
  }
  .contenido-principal {
    flex: 1;
    min-width: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    background-color: #1a1a1a !important;
    color: #fff;
  }
  
  /* ✅ MÓVILES: Contenido principal fijo */
  @media (max-width: 900px) {
    .contenido-principal {
      height: 100vh; /* ALTURA FIJA = tamaño de pantalla */
      max-height: 100vh; /* NO puede crecer más */
      overflow: hidden; /* SIN SCROLL aquí */
    }
  }
  
  /* ✅ ESCRITORIO: Contenido principal con scroll */
  @media (min-width: 901px) {
    .contenido-principal {
      min-height: 100vh; /* MÍNIMO una pantalla */
      overflow: visible; /* PERMITIR SCROLL */
    }
  }

  /* NUEVO: Asegurar que el video player no se encoja */
  .contenido-principal :global(.reproductor-container),
  .contenido-principal :global(.reproductor-lecciones) {
    flex-shrink: 0; /* CLAVE: Video siempre visible, no se encoge */
  }

  .leccion-sidebar {
    display: none;
    width: 0;
    background: #181818;
    color: #fff;
    min-height: 100vh;
    transition: all 1s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: -5px 0 15px rgba(0, 0, 0, 0.1);
    position: relative;
    flex-direction: column;
}
.leccion-sidebar.visible {
    display: block;
    width: 350px;
}

@media (max-width: 1100px) {
    .contenido-container {
        position: relative;
    }
    .leccion-sidebar {
        position: fixed;
        top: 60px;
        right: 0;
        height: calc(100vh - 60px);
        z-index: 100;
        transform: translateX(100%);
        box-shadow: -5px 0 15px rgba(0, 0, 0, 0.2);
        width: 0;
        max-width: 0;
    }
    .leccion-sidebar.visible {
        transform: translateX(0);
        width: 85%;
        max-width: 320px;
    }
}

/* NUEVO: Estilos específicos para el botón X en móvil */
@media (max-width: 768px) {
    .leccion-sidebar.visible {
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        width: 100vw !important;
        z-index: 9999 !important; /* Z-index muy alto para móvil */
        background: #181818 !important;
        overflow-y: auto !important; /* Permitir scroll interno */
    }
    
    /* Asegurar que el contenido del sidebar esté bien posicionado */
    .leccion-sidebar.visible :global(.sidebar-header) {
        position: sticky !important;
        top: 0 !important;
        z-index: 10000 !important; /* Aún más alto para el header */
        background: linear-gradient(135deg, #1e40af, #7c3aed) !important;
    }
    
    /* Botón X específico para móvil */
    .leccion-sidebar.visible :global(.cerrar-sidebar) {
        width: 50px !important;
        height: 50px !important;
        background-color: rgba(255, 255, 255, 0.3) !important;
        border: 2px solid rgba(255, 255, 255, 0.5) !important;
        position: relative !important;
        z-index: 10001 !important; /* El más alto de todos */
        font-size: 20px !important;
    }
    
    .leccion-sidebar.visible :global(.cerrar-sidebar):active {
        background-color: rgba(255, 0, 0, 0.3) !important;
        transform: scale(0.9) !important;
    }
}

/* ESTILOS DEL OVERLAY MÓVIL (copiados del que SÍ FUNCIONA) */
.sidebar-mobile-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(4px);
  z-index: 99999;
  display: flex;
  justify-content: flex-end;
}

.sidebar-mobile-panel {
  width: 90%;
  max-width: 400px;
  height: 100vh;
  background: #1a1a1a;
  overflow-y: auto;
  border-left: 1px solid rgba(255, 255, 255, 0.1);
}

@media (min-width: 769px) {
  .sidebar-mobile-overlay {
    display: none;
  }
}

/* ✅ SCROLL CONTROLADO: Solo bloquear en móviles, permitir en escritorio */
@media (max-width: 900px) {
  :global(body) {
    overflow: hidden !important; /* SIN SCROLL en móviles */
    height: 100vh !important;
    position: fixed !important;
    width: 100% !important;
  }

  :global(html) {
    overflow: hidden !important; /* SIN SCROLL en HTML móviles */
    height: 100vh !important;
  }
}

/* ✅ ESCRITORIO: Scroll normal y funcional */
@media (min-width: 901px) {
  :global(body) {
    overflow: auto !important;
    height: auto !important;
    position: relative !important;
  }

  :global(html) {
    overflow: auto !important;
    height: auto !important;
  }
}

/* El scroll SOLO en las pestañas */
:global(.tab-content) {
  overflow-y: auto !important;
  overflow-x: hidden !important;
  -webkit-overflow-scrolling: touch !important;
}

</style>
