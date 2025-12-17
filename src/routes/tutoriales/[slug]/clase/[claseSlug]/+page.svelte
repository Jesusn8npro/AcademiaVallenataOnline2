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

  // ✅ NUEVO: FUNCIÓN PARA HABILITAR SCROLL TÁCTIL NATIVO
  function habilitarScrollTactil() {
    if (typeof window === 'undefined') return;
    
    // Buscar todos los contenedores de lecciones
    const contenedoresLecciones = document.querySelectorAll(
      '[class*="lista-lecciones"], [class*="cards-lecciones"], [class*="grid-lecciones"], .contenido-tab, .tab-content'
    );
    
    contenedoresLecciones.forEach(contenedor => {
      if (!contenedor) return;
      
      // Habilitar scroll nativo
      (contenedor as HTMLElement).style.overflowY = 'auto';
      (contenedor as HTMLElement).style.overflowX = 'hidden';
      (contenedor as HTMLElement).style.setProperty('-webkit-overflow-scrolling', 'touch');
      (contenedor as HTMLElement).style.scrollBehavior = 'smooth';
      
      // Variables para scroll táctil
      let startY = 0;
      let startScrollTop = 0;
      let isScrolling = false;
      
      // Touch start
      contenedor.addEventListener('touchstart', (e: any) => {
        startY = e.touches[0].clientY;
        startScrollTop = (contenedor as HTMLElement).scrollTop;
        isScrolling = false;
      }, { passive: true });
      
      // Touch move
      contenedor.addEventListener('touchmove', (e: any) => {
        if (!startY) return;
        
        const currentY = e.touches[0].clientY;
        const deltaY = startY - currentY;
        
        // Si el movimiento es vertical, es scroll
        if (Math.abs(deltaY) > 10) {
          isScrolling = true;
          e.preventDefault();
          
          // Aplicar scroll
          (contenedor as HTMLElement).scrollTop = startScrollTop + deltaY;
        }
      }, { passive: false });
      
      // Touch end
      contenedor.addEventListener('touchend', (e: any) => {
        if (isScrolling) {
          // Si fue scroll, no hacer nada más
          e.preventDefault();
        }
        
        startY = 0;
        startScrollTop = 0;
        isScrolling = false;
      }, { passive: true });
      
      // Prevenir scroll no deseado
      contenedor.addEventListener('scroll', (e: Event) => {
        if (isScrolling) {
          e.stopPropagation();
        }
      }, { passive: true });
    });
  }

  // ✅ NUEVO: FUNCIÓN PARA HABILITAR CLICK EN LECCIONES
  function habilitarClickLecciones() {
    if (typeof window === 'undefined') return;
    
    // Buscar todas las lecciones individuales
    const lecciones = document.querySelectorAll(
      '[class*="leccion-item"], [class*="card-leccion"], [class*="item-leccion"]'
    );
    
    lecciones.forEach(leccion => {
      if (!leccion) return;
      
      // Agregar cursor pointer
      (leccion as HTMLElement).style.cursor = 'pointer';
      (leccion as HTMLElement).style.transition = 'all 0.2s ease';
      
      // Click event
      leccion.addEventListener('click', (e: any) => {
        // Solo si no fue scroll
        if (!e.target?.closest('[class*="lista-lecciones"]') || 
            !e.target?.closest('[class*="cards-lecciones"]') || 
            !e.target?.closest('[class*="grid-lecciones"]')) {
          return;
        }
        
        // Aquí puedes agregar la lógica de redirección
        console.log('Lección clickeada:', leccion);
        // goto(`/tutoriales/${$page.params.slug}/clase/${leccion.dataset.slug}`);
      });
      
      // Hover effect
      leccion.addEventListener('mouseenter', () => {
        (leccion as HTMLElement).style.transform = 'translateY(-2px)';
        (leccion as HTMLElement).style.boxShadow = '0 4px 20px rgba(0,0,0,0.2)';
      });
      
      leccion.addEventListener('mouseleave', () => {
        (leccion as HTMLElement).style.transform = 'translateY(0)';
        (leccion as HTMLElement).style.boxShadow = '0 2px 10px rgba(0,0,0,0.1)';
      });
    });
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
    
    // ✅ NUEVO: HABILITAR SCROLL TÁCTIL DESPUÉS DE QUE SE MONTE EL COMPONENTE
    setTimeout(() => {
      habilitarScrollTactil();
      habilitarClickLecciones();
    }, 1000);
    
    // ✅ NUEVO: RE-HABILITAR SCROLL TÁCTIL CUANDO CAMBIEN LOS TABS
    const observer = new MutationObserver(() => {
      setTimeout(() => {
        habilitarScrollTactil();
        habilitarClickLecciones();
      }, 500);
    });
    
    const tabsContainer = document.querySelector('.leccion-tabs');
    if (tabsContainer) {
      observer.observe(tabsContainer, { childList: true, subtree: true });
    }
    
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
        try {
        const { data } = await import('$lib/services/progresoTutorialService').then(m => m.obtenerProgresoTutorialDeParte(clase.id));
        completada = !!(data && data.completada);
        } catch (error) {
          console.warn('[TUTORIAL] Error al obtener progreso de parte, usando valor por defecto:', error);
          completada = false; // Valor por defecto si falla
        }
      }
      // Refresca el progreso general
      await refrescarProgresoLecciones();
    } catch (e) {
      console.warn('[TUTORIAL] Error general en verificarCompletadaYProgreso:', e);
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
      console.warn('[TUTORIAL] Error al refrescar progreso de tutorial, usando valores por defecto:', e);
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
      recursos={clase?.recursos}
      comentarios={data.comentarios}
      cursoId={tutorial?.id}
      usuarioActual={usuarioActual}
      leccionId={clase?.id}
      tipo={tipo}
      clases={data.clases}
      progreso={$progresoLecciones}
      mostrarSidebar={mostrarSidebar}
      curso={tutorial}
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
    background: #f8fafc; /* ✅ NUEVO: Fondo claro para mejor visibilidad */
  }
  
  /* ✅ MÓVILES: Layout fijo estilo Platzi */
  @media (max-width: 900px) {
    .contenido-container {
      height: 100vh; /* FORZAR altura fija de viewport */
      max-height: 100vh; /* NO puede ser más alto */
      overflow: hidden !important; /* 🚫 SIN SCROLL EN CONTENEDOR PRINCIPAL */
      overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
      max-width: 100vw !important; /* ✅ PREVENIR SCROLL HORIZONTAL */
      width: 100% !important;
      padding-bottom: 90px !important; /* ✅ PADDING REDUCIDO: de 120px a 90px para ser más sutil */
      margin-bottom: 0 !important; /* ✅ SIN MARGIN ADICIONAL */
    }
    
    .contenido-principal {
      height: calc(100vh - 90px) !important; /* ✅ ALTURA AJUSTADA PARA EL MENÚ */
      max-height: calc(100vh - 90px) !important; /* NO puede crecer más */
      overflow: hidden; /* 🚫 SIN SCROLL en contenido principal */
      padding-bottom: 0 !important; /* SIN PADDING ADICIONAL */
      margin-bottom: 0 !important; /* ✅ SIN MARGIN ADICIONAL */
    }
    
    /* ✅ NUEVO: PERMITIR SCROLL SOLO EN TABS Y CONTENIDO INFERIOR */
    .contenido-principal :global(.leccion-tabs),
    .contenido-principal :global(.tabs-container),
    .contenido-principal :global(.contenido-tab) {
      overflow-y: auto !important; /* ✅ PERMITIR SCROLL VERTICAL */
      overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
      max-height: calc(100vh - 400px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL */
    }
    
    /* ✅ NUEVO: BLOQUEAR SCROLL EN "CLASES DEL TUTORIAL" */
    .contenido-principal :global(.tab-content),
    .contenido-principal :global([class*="clases-tutorial"]),
    .contenido-principal :global([class*="lista-clases"]),
    .contenido-principal :global(.contenido-tab .tab-content),
    .contenido-principal :global([class*="titulo-clases"]),
    .contenido-principal :global([class*="header-clases"]),
    .contenido-principal :global([class*="navegacion-clases"]) {
      overflow: hidden !important; /* 🚫 SIN SCROLL */
      overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
      overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
      max-height: none !important; /* ✅ SIN ALTURA MÁXIMA */
    }
    
    /* ✅ NUEVO: SCROLL TÁCTIL NATIVO 100% FUNCIONAL EN LISTA DE LECCIONES */
    .contenido-principal :global([class*="lista-lecciones"]),
    .contenido-principal :global([class*="cards-lecciones"]),
    .contenido-principal :global([class*="grid-lecciones"]),
    .contenido-principal :global(.contenido-tab [class*="lecciones"]),
    .contenido-principal :global(.tab-content [class*="lecciones"]),
    .contenido-principal :global(.contenido-tab),
    .contenido-principal :global(.tab-content),
    .contenido-principal :global(.leccion-tabs),
    .contenido-principal :global(.tabs-container) {
      overflow-y: auto !important; /* ✅ SCROLL NATIVO AUTO */
      overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
      max-height: calc(100vh - 500px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL */
      -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
      scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
      touch-action: manipulation !important; /* ✅ TOUCH ACTION COMPLETO */
      -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
      user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
      position: relative !important; /* ✅ POSICIÓN RELATIVA */
      z-index: 10 !important; /* ✅ Z-INDEX ALTO */
    }
  }
  
  /* ✅ ESCRITORIO: Layout con scroll natural */
  @media (min-width: 901px) {
    .contenido-container {
      min-height: 100vh; /* MÍNIMO una pantalla, pero puede crecer */
      overflow: visible; /* PERMITIR SCROLL NATURAL */
      overflow-x: hidden !important; /* ✅ NUEVO: PREVENIR SCROLL HORIZONTAL EN ESCRITORIO */
      padding-bottom: 0 !important; /* SIN PADDING EN ESCRITORIO */
      max-width: 100vw !important; /* ✅ NUEVO: PREVENIR SCROLL HORIZONTAL */
      background: #f8fafc; /* ✅ NUEVO: Fondo claro en escritorio también */
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
  
  /* ✅ ESCRITORIO: Contenido principal con scroll */
  @media (min-width: 901px) {
    .contenido-principal {
      min-height: 100vh; /* MÍNIMO una pantalla */
      overflow: visible; /* PERMITIR SCROLL */
      padding-bottom: 0 !important; /* SIN PADDING */
    }
  }

  /* ✅ NUEVO: Asegurar que el video player (IMAGEN 3) esté SIEMPRE visible */
  .contenido-principal :global(.reproductor-container),
  .contenido-principal :global(.reproductor-lecciones) {
    flex-shrink: 0 !important; /* ✅ CLAVE: Video siempre visible, no se encoge */
    min-height: 300px !important; /* ✅ ALTURA MÍNIMA para asegurar visibilidad */
    position: sticky !important; /* ✅ POSICIÓN STICKY para mantener en pantalla */
    top: 0 !important; /* ✅ SIEMPRE EN LA PARTE SUPERIOR */
    z-index: 100 !important; /* ✅ Z-INDEX ALTO para estar por encima */
    background: #000 !important; /* ✅ FONDO NEGRO para el video */
  }
  
  /* ✅ NUEVO: Asegurar que los tabs estén debajo del video */
  .contenido-principal :global(.leccion-tabs) {
    margin-top: 20px !important; /* ✅ ESPACIO entre video y tabs */
    background: #fff !important; /* ✅ FONDO BLANCO para los tabs */
    border-radius: 8px !important; /* ✅ BORDES REDONDEADOS */
    box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important; /* ✅ SOMBRA SUTIL */
    padding: 16px !important; /* ✅ PADDING REDUCIDO */
    margin-bottom: 0 !important; /* ✅ SIN MARGIN INFERIOR */
  }
  
  /* ✅ NUEVO: ELIMINAR PADDING EXCESIVO EN CONTENIDO DE TABS */
  .contenido-principal :global(.contenido-tab),
  .contenido-principal :global(.tab-content) {
    padding: 0 !important; /* ✅ SIN PADDING EXCESIVO */
    margin: 0 !important; /* ✅ SIN MARGIN EXCESIVO */
  }
  
  /* ✅ NUEVO: ELIMINAR PADDING EN LISTA DE CLASES */
  .contenido-principal :global([class*="clases-tutorial"]),
  .contenido-principal :global([class*="lista-clases"]) {
    padding: 0 !important; /* ✅ SIN PADDING EXCESIVO */
    margin: 0 !important; /* ✅ SIN MARGIN EXCESIVO */
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

/* ✅ SCROLL COMPLETAMENTE BLOQUEADO EN MÓVILES: Sin scroll horizontal ni vertical */
@media (max-width: 900px) {
  :global(body) {
    overflow: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    height: 100vh !important;
    position: fixed !important;
    width: 100% !important;
    max-width: 100vw !important; /* ✅ PREVENIR SCROLL HORIZONTAL */
    padding-bottom: 90px !important;
    margin-bottom: 0 !important;
  }

  :global(html) {
    overflow: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    height: 100vh !important;
    width: 100% !important;
    max-width: 100vw !important; /* ✅ PREVENIR SCROLL HORIZONTAL */
    padding-bottom: 0 !important;
    margin-bottom: 0 !important;
  }
  
  /* ✅ PREVENIR SCROLL EN TODOS LOS ELEMENTOS */
  :global(*) {
    max-width: 100vw !important;
    overflow-x: hidden !important;
  }
  
  /* ✅ PREVENIR SCROLL EN EL CONTENEDOR PRINCIPAL */
  :global(.contenido-container) {
    overflow: hidden !important;
    overflow-x: hidden !important;
    max-width: 100vw !important;
    width: 100% !important;
  }
  
  /* ✅ IMPORTANTE: Asegurar que el menú esté visible */
  :global(.menu-inferior-responsivo) {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    z-index: 999999 !important;
    position: fixed !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    transform: translateY(0) !important;
    background: rgba(255, 255, 255, 0.95) !important;
    backdrop-filter: blur(20px) !important;
    border-top: 1px solid #e2e8f0 !important;
    box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.08) !important;
  }
}

/* ✅ ESCRITORIO: Scroll normal y funcional */
@media (min-width: 901px) {
  :global(body) {
    overflow: auto !important;
    height: auto !important;
    position: relative !important;
    padding-bottom: 0 !important; /* SIN PADDING EN ESCRITORIO */
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

/* ✅ PADDING ESPECÍFICO PARA ELEMENTOS QUE NO DEBEN SER TAPADOS */
@media (max-width: 900px) {
  /* ✅ BOTONES Y CAMPOS DE TEXTO */
  :global(.boton-agregar-nota),
  :global(.campo-nota),
  :global(.area-texto),
  :global(.boton-marcar-completada),
  :global(.boton-anterior),
  :global(.boton-siguiente) {
    margin-bottom: 15px !important; /* ✅ MARGIN SUTIL: de 20px a 15px */
  }
  
  /* ✅ SECCIÓN DE NOTAS */
  :global(.seccion-notas),
  :global(.mis-notas-personales) {
    margin-bottom: 20px !important; /* ✅ MARGIN SUTIL: solo margin, sin padding */
  }
  
  /* ✅ TABS Y CONTENIDO */
  :global(.tabs-container),
  :global(.contenido-tab) {
    margin-bottom: 18px !important; /* ✅ MARGIN SUTIL: de 25px a 18px */
  }
  
  /* ✅ SECCIÓN DE REQUISITOS - MARGIN SUTIL */
  :global(.requisitos),
  :global(.seccion-requisitos),
  :global([class*="requisito"]),
  :global([class*="Requisito"]) {
    margin-bottom: 25px !important; /* ✅ MARGIN SUTIL: de 30px a 25px */
  }
  
  /* ✅ BOTONES "+1 más..." Y SIMILARES */
  :global(.boton-mas),
  :global([class*="mas"]),
  :global([class*="Mas"]),
  :global(.boton-expandir) {
    margin-bottom: 20px !important; /* ✅ MARGIN SUTIL: de 35px a 20px */
  }
  
  /* ✅ TODAS LAS SECCIONES DE CONTENIDO */
  :global(.contenido-seccion),
  :global(.seccion-contenido),
  :global([class*="contenido"]),
  :global([class*="Contenido"]) {
    margin-bottom: 15px !important; /* ✅ MARGIN SUTIL: de 20px a 15px */
  }
  
  /* ✅ PESTAÑA DE CONTENIDO - MARGIN SUTIL */
  :global(.tab-contenido),
  :global(.contenido-tutorial),
  :global([class*="clases-tutorial"]),
  :global([class*="lista-clases"]) {
    margin-bottom: 20px !important; /* ✅ MARGIN SUTIL PARA LA PESTAÑA DE CONTENIDO */
  }
}

  /* ✅ NUEVO: CSS GLOBAL PARA PREVENIR SCROLL HORIZONTAL EN TODAS LAS PÁGINAS DE LECCIONES */
  :global(html) {
    overflow-x: hidden !important;
    max-width: 100vw !important;
  }

  :global(body) {
    overflow-x: hidden !important;
    max-width: 100vw !important;
  }

  :global(#svelte) {
    overflow-x: hidden !important;
    max-width: 100vw !important;
  }
  
  /* ✅ NUEVO: CSS GLOBAL AGRESIVO PARA SCROLL TÁCTIL NATIVO EN MÓVILES */
  :global(.contenido-tab),
  :global(.tab-content),
  :global([class*="lecciones"]),
  :global([class*="lista"]),
  :global([class*="cards"]),
  :global(.leccion-tabs),
  :global(.tabs-container),
  :global(.tab-content),
  :global([class*="contenido"]) {
    touch-action: manipulation !important; /* ✅ TOUCH ACTION COMPLETO */
    -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
    scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
    -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
    user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
    overflow-y: auto !important; /* ✅ SCROLL VERTICAL AUTO */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    position: relative !important; /* ✅ POSICIÓN RELATIVA */
    z-index: 5 !important; /* ✅ Z-INDEX MEDIO */
  }
  
      /* ✅ NUEVO: CSS ESPECÍFICO PARA MÓVILES - ELIMINAR SCROLL NO DESEADO */
    @media (max-width: 900px) {
      :global(.tab-content),
      :global([class*="clases-tutorial"]),
      :global([class*="lista-clases"]),
      :global(.contenido-tab .tab-content),
      :global(.leccion-tabs .tab-content) {
        overflow: hidden !important; /* 🚫 SIN SCROLL */
        overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        max-height: none !important; /* ✅ SIN ALTURA MÁXIMA */
        height: auto !important; /* ✅ ALTURA AUTOMÁTICA */
      }
      
      /* ✅ NUEVO: ELIMINAR PADDING EXCESIVO EN MÓVILES */
      :global(.contenido-tab),
      :global(.tab-content),
      :global([class*="clases-tutorial"]),
      :global([class*="lista-clases"]) {
        padding: 0 !important; /* ✅ SIN PADDING EXCESIVO */
        margin: 0 !important; /* ✅ SIN MARGIN EXCESIVO */
      }
      
      /* ✅ NUEVO: BLOQUEAR SCROLL ESPECÍFICAMENTE EN HEADER DE CLASES EN MÓVILES */
      :global([class*="titulo-clases"]),
      :global([class*="header-clases"]),
      :global([class*="navegacion-clases"]),
      :global(.contenido-tab [class*="clases"]),
      :global(.tab-content [class*="clases"]) {
        overflow: hidden !important; /* 🚫 SIN SCROLL */
        overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        max-height: none !important; /* ✅ SIN ALTURA MÁXIMA */
        height: auto !important; /* ✅ ALTURA AUTOMÁTICA */
        position: relative !important; /* ✅ POSICIÓN RELATIVA */
        z-index: 1 !important; /* ✅ Z-INDEX BAJO */
        padding: 40px 44px !important; /* ✅ PADDING MÁS GRANDE EN MÓVILES para ver todo el título */
        font-size: 1.5rem !important; /* ✅ TEXTO MÁS GRANDE EN MÓVILES */
        min-height: 110px !important; /* ✅ ALTURA MÍNIMA MÁS GRANDE EN MÓVILES */
        line-height: 1.6 !important; /* ✅ LINE-HEIGHT MÁS GRANDE EN MÓVILES */
      }
      
      /* ✅ NUEVO: SCROLL TÁCTIL NATIVO 100% FUNCIONAL EN MÓVILES */
      :global([class*="lista-lecciones"]),
      :global([class*="cards-lecciones"]),
      :global([class*="grid-lecciones"]),
      :global(.contenido-tab [class*="lecciones"]),
      :global(.tab-content [class*="lecciones"]),
      :global(.contenido-tab),
      :global(.tab-content),
      :global(.leccion-tabs),
      :global(.tabs-container) {
        overflow-y: scroll !important; /* ✅ SCROLL NATIVO PARA MÓVILES */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        max-height: calc(100vh - 550px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL EN MÓVILES */
        -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
        scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
        touch-action: pan-y !important; /* ✅ PERMITIR DESLIZAR VERTICALMENTE */
        -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        position: relative !important; /* ✅ POSICIÓN RELATIVA */
        z-index: 10 !important; /* ✅ Z-INDEX ALTO */
        padding: 16px !important; /* ✅ PADDING PARA MEJOR TOQUE */
        scrollbar-width: none !important; /* ✅ OCULTAR SCROLLBAR EN FIREFOX */
        -ms-overflow-style: none !important; /* ✅ OCULTAR SCROLLBAR EN IE/EDGE */
      }
      
      /* ✅ NUEVO: SCROLL TÁCTIL ESPECÍFICO PARA LISTA DE LECCIONES */
      :global(.contenido-tab [class*="lista-lecciones"]),
      :global(.tab-content [class*="lista-lecciones"]),
      :global(.contenido-tab [class*="cards-lecciones"]),
      :global(.tab-content [class*="cards-lecciones"]),
      :global(.contenido-tab [class*="grid-lecciones"]),
      :global(.tab-content [class*="grid-lecciones"]) {
        overflow-y: scroll !important; /* ✅ SCROLL NATIVO PARA MÓVILES */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        max-height: calc(100vh - 600px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL */
        -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
        scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
        touch-action: pan-y !important; /* ✅ PERMITIR DESLIZAR VERTICALMENTE */
        -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        position: relative !important; /* ✅ POSICIÓN RELATIVA */
        z-index: 15 !important; /* ✅ Z-INDEX ALTO */
        padding: 20px !important; /* ✅ PADDING PARA MEJOR TOQUE */
        background: #fff !important; /* ✅ FONDO BLANCO PARA VISIBILIDAD */
        border-radius: 8px !important; /* ✅ BORDES REDONDEADOS */
        box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important; /* ✅ SOMBRA SUAVE */
        scrollbar-width: none !important; /* ✅ OCULTAR SCROLLBAR EN FIREFOX */
        -ms-overflow-style: none !important; /* ✅ OCULTAR SCROLLBAR EN IE/EDGE */
      }
      
      /* ✅ NUEVO: BLOQUEAR SCROLL Y HACER MÁS GRANDE LA BARRA BLANCA EN MÓVILES */
      :global([class*="lecciones-modulo"]),
      :global([class*="total-lecciones"]),
      :global([class*="resumen-modulo"]),
      :global([class*="contador-lecciones"]) {
        overflow: hidden !important; /* 🚫 SIN SCROLL */
        overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        padding: 28px 32px !important; /* ✅ PADDING MÁS GRANDE EN MÓVILES */
        font-size: 1.3rem !important; /* ✅ TEXTO MÁS GRANDE EN MÓVILES */
        min-height: 80px !important; /* ✅ ALTURA MÍNIMA MÁS GRANDE EN MÓVILES */
        margin: 28px 0 !important; /* ✅ MARGIN MÁS GRANDE EN MÓVILES */
      }
      
      /* ✅ NUEVO: SCROLL TÁCTIL ESPECÍFICO PARA MÓVILES EN LISTA DE LECCIONES */
      :global(.contenido-tab [class*="lista-lecciones"]),
      :global(.tab-content [class*="lista-lecciones"]),
      :global(.contenido-tab [class*="cards-lecciones"]),
      :global(.tab-content [class*="cards-lecciones"]),
      :global(.contenido-tab [class*="grid-lecciones"]),
      :global(.tab-content [class*="grid-lecciones"]) {
        overflow-y: scroll !important; /* ✅ SCROLL NATIVO PARA MÓVILES */
        overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
        max-height: calc(100vh - 650px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL EN MÓVILES */
        -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
        scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
        touch-action: pan-y !important; /* ✅ PERMITIR DESLIZAR VERTICALMENTE */
        -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
        position: relative !important; /* ✅ POSICIÓN RELATIVA */
        z-index: 25 !important; /* ✅ Z-INDEX MÁS ALTO EN MÓVILES */
        padding: 24px !important; /* ✅ PADDING MÁS GRANDE PARA MEJOR TOQUE */
        background: #fff !important; /* ✅ FONDO BLANCO PARA VISIBILIDAD */
        border-radius: 12px !important; /* ✅ BORDES MÁS REDONDEADOS EN MÓVILES */
        box-shadow: 0 4px 20px rgba(0,0,0,0.15) !important; /* ✅ SOMBRA MÁS PRONUNCIADA EN MÓVILES */
        scrollbar-width: none !important; /* ✅ OCULTAR SCROLLBAR EN FIREFOX */
        -ms-overflow-style: none !important; /* ✅ OCULTAR SCROLLBAR EN IE/EDGE */
      }
      
      /* ✅ NUEVO: OCULTAR SCROLLBAR EN WEBKIT PARA MÓVILES */
      :global(.contenido-tab [class*="lista-lecciones"])::-webkit-scrollbar,
      :global(.tab-content [class*="lista-lecciones"])::-webkit-scrollbar,
      :global(.contenido-tab [class*="cards-lecciones"])::-webkit-scrollbar,
      :global(.tab-content [class*="cards-lecciones"])::-webkit-scrollbar,
      :global(.contenido-tab [class*="grid-lecciones"])::-webkit-scrollbar,
      :global(.tab-content [class*="grid-lecciones"])::-webkit-scrollbar {
        display: none !important; /* ✅ OCULTAR SCROLLBAR EN MÓVILES */
      }
    }

/* ✅ NUEVO: PREVENIR SCROLL HORIZONTAL EN COMPONENTES ESPECÍFICOS */
:global(.reproductor-container),
:global(.reproductor-lecciones) {
  overflow-x: hidden !important;
  max-width: 100vw !important;
}

/* ✅ NUEVO: PERMITIR SCROLL VERTICAL EN TABS Y CONTENIDO */
:global(.leccion-tabs),
:global(.contenido-tab),
:global(.tabs-container) {
  overflow-x: hidden !important;
  max-width: 100vw !important;
  overflow-y: auto !important; /* ✅ PERMITIR SCROLL VERTICAL */
  -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL SUAVE EN MÓVILES */
}

/* ✅ NUEVO: CSS GLOBAL FINAL PARA SCROLL TÁCTIL NATIVO */
:global([class*="lista-lecciones"]),
:global([class*="cards-lecciones"]),
:global([class*="grid-lecciones"]),
:global(.contenido-tab [class*="lecciones"]),
:global(.tab-content [class*="lecciones"]),
:global(.contenido-tab),
:global(.tab-content) {
  overflow-y: scroll !important; /* ✅ SCROLL NATIVO PARA MÓVILES */
  overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
  max-height: calc(100vh - 500px) !important; /* ✅ ALTURA MÁXIMA PARA SCROLL */
  -webkit-overflow-scrolling: touch !important; /* ✅ SCROLL TÁCTIL SUAVE */
  scroll-behavior: smooth !important; /* ✅ SCROLL SUAVE */
  touch-action: pan-y !important; /* ✅ PERMITIR DESLIZAR VERTICALMENTE */
  -webkit-user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
  user-select: none !important; /* ✅ EVITAR SELECCIÓN DE TEXTO */
  position: relative !important; /* ✅ POSICIÓN RELATIVA */
  z-index: 20 !important; /* ✅ Z-INDEX MÁS ALTO */
  background: #fff !important; /* ✅ FONDO BLANCO PARA VISIBILIDAD */
  border-radius: 8px !important; /* ✅ BORDES REDONDEADOS */
  box-shadow: 0 2px 10px rgba(0,0,0,0.1) !important; /* ✅ SOMBRA SUAVE */
  padding: 16px !important; /* ✅ PADDING PARA MEJOR TOQUE */
  scrollbar-width: none !important; /* ✅ OCULTAR SCROLLBAR EN FIREFOX */
  -ms-overflow-style: none !important; /* ✅ OCULTAR SCROLLBAR EN IE/EDGE */
}

/* ✅ NUEVO: CSS ESPECÍFICO PARA SCROLL TÁCTIL EN LECCIONES INDIVIDUALES */
:global([class*="leccion-item"]),
:global([class*="card-leccion"]),
:global([class*="item-leccion"]),
:global(.contenido-tab [class*="leccion"]),
:global(.tab-content [class*="leccion"]) {
  touch-action: manipulation !important; /* ✅ TOUCH ACTION PARA LECCIONES INDIVIDUALES */
  cursor: pointer !important; /* ✅ CURSOR POINTER PARA INDICAR CLICK */
  transition: all 0.2s ease !important; /* ✅ TRANSICIÓN SUAVE */
  -webkit-tap-highlight-color: rgba(0,0,0,0.1) !important; /* ✅ HIGHLIGHT AL TOCAR */
  tap-highlight-color: rgba(0,0,0,0.1) !important; /* ✅ HIGHLIGHT AL TOCAR */
}

/* ✅ NUEVO: OCULTAR SCROLLBAR EN WEBKIT (CHROME/SAFARI) */
:global([class*="lista-lecciones"])::-webkit-scrollbar,
:global([class*="cards-lecciones"])::-webkit-scrollbar,
:global([class*="grid-lecciones"])::-webkit-scrollbar,
:global(.contenido-tab [class*="lecciones"])::-webkit-scrollbar,
:global(.tab-content [class*="lecciones"])::-webkit-scrollbar {
  display: none !important; /* ✅ OCULTAR SCROLLBAR */
}

/* ✅ NUEVO: MEJORAR ESTILO DEL TEXTO "4 LECCIONES EN ESTE MÓDULO" */
:global(.tab-content),
:global([class*="clases-tutorial"]),
:global([class*="lista-clases"]),
:global(.contenido-tab .tab-content) {
  overflow: hidden !important; /* 🚫 SIN SCROLL */
  overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
  overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
}

  /* ✅ NUEVO: ESTILO MEJORADO PARA EL CONTADOR DE LECCIONES */
  :global([class*="lecciones-modulo"]),
  :global([class*="total-lecciones"]),
  :global([class*="resumen-modulo"]) {
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%) !important;
    border: 2px solid #e2e8f0 !important;
    border-radius: 12px !important;
    padding: 16px 20px !important;
    margin: 20px 0 !important;
    text-align: center !important;
    font-weight: 600 !important;
    color: #475569 !important;
    font-size: 1rem !important;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05) !important;
  }
  
  /* ✅ NUEVO: BLOQUEAR SCROLL EN HEADER DE CLASES */
  :global([class*="clases-tutorial"]),
  :global([class*="titulo-clases"]),
  :global([class*="header-clases"]),
  :global([class*="navegacion-clases"]),
  :global(.contenido-tab [class*="clases"]),
  :global(.tab-content [class*="clases"]) {
    overflow: hidden !important; /* 🚫 SIN SCROLL */
    overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    max-height: none !important; /* ✅ SIN ALTURA MÁXIMA */
    height: auto !important; /* ✅ ALTURA AUTOMÁTICA */
  }
  
  /* ✅ NUEVO: CSS GLOBAL PARA BLOQUEAR SCROLL EN TODOS LOS HEADERS */
  :global([class*="header"]),
  :global([class*="titulo"]),
  :global([class*="navegacion"]),
  :global([class*="clases"]),
  :global([class*="tutorial"]) {
    overflow: hidden !important; /* 🚫 SIN SCROLL */
    overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
  }
  
  /* ✅ NUEVO: HACER MÁS GRANDES LAS FLECHAS DE NAVEGACIÓN */
  :global([class*="navegacion"] svg),
  :global([class*="navegacion"] .icono-flecha),
  :global([class*="navegacion"] .flecha),
  :global([class*="clases"] svg),
  :global([class*="clases"] .icono-flecha),
  :global([class*="clases"] .flecha) {
    width: 24px !important; /* ✅ FLECHAS MÁS GRANDES */
    height: 24px !important; /* ✅ FLECHAS MÁS GRANDES */
    font-size: 1.2rem !important; /* ✅ TEXTO MÁS GRANDE */
  }
  
  /* ✅ NUEVO: ASEGURAR QUE EL TÍTULO COMPLETO SEA VISIBLE */
  :global([class*="clases-tutorial"]),
  :global([class*="titulo-clases"]),
  :global([class*="header-clases"]) {
    white-space: nowrap !important; /* ✅ EVITAR QUE EL TÍTULO SE ROMPA */
    text-overflow: clip !important; /* ✅ MOSTRAR TODO EL TEXTO */
    overflow: visible !important; /* ✅ PERMITIR QUE EL TEXTO SEA VISIBLE */
    width: 100% !important; /* ✅ ANCHO COMPLETO */
    box-sizing: border-box !important; /* ✅ BOX-SIZING CORRECTO */
  }
  
  /* ✅ NUEVO: BLOQUEAR SCROLL EN ELEMENTOS ESPECÍFICOS DEL HEADER */
  :global(.contenido-tab header),
  :global(.tab-content header),
  :global(.leccion-tabs header),
  :global([class*="clases"] header) {
    overflow: hidden !important; /* 🚫 SIN SCROLL */
    overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    position: relative !important; /* ✅ POSICIÓN RELATIVA */
    z-index: 1 !important; /* ✅ Z-INDEX BAJO */
  }
  
  /* ✅ NUEVO: BLOQUEAR SCROLL Y HACER MÁS GRANDE LA BARRA NARANJA "CLASES DEL TUTORIAL" */
  :global([class*="clases-tutorial"]),
  :global([class*="titulo-clases"]),
  :global([class*="header-clases"]),
  :global([class*="navegacion-clases"]),
  :global(.contenido-tab [class*="clases"]),
  :global(.tab-content [class*="clases"]) {
    overflow: hidden !important; /* 🚫 SIN SCROLL */
    overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    max-height: none !important; /* ✅ SIN ALTURA MÁXIMA */
    height: auto !important; /* ✅ ALTURA AUTOMÁTICA */
    padding: 36px 40px !important; /* ✅ PADDING MÁS GRANDE para ver todo el título */
    font-size: 1.4rem !important; /* ✅ TEXTO MÁS GRANDE */
    min-height: 100px !important; /* ✅ ALTURA MÍNIMA MÁS GRANDE */
    line-height: 1.5 !important; /* ✅ LINE-HEIGHT para mejor legibilidad */
  }
  
  /* ✅ NUEVO: BLOQUEAR SCROLL Y HACER MÁS GRANDE LA BARRA BLANCA "4 LECCIONES" */
  :global([class*="lecciones-modulo"]),
  :global([class*="total-lecciones"]),
  :global([class*="resumen-modulo"]),
  :global([class*="contador-lecciones"]) {
    overflow: hidden !important; /* 🚫 SIN SCROLL */
    overflow-y: hidden !important; /* 🚫 SIN SCROLL VERTICAL */
    overflow-x: hidden !important; /* 🚫 SIN SCROLL HORIZONTAL */
    padding: 24px 28px !important; /* ✅ PADDING MÁS GRANDE */
    font-size: 1.2rem !important; /* ✅ TEXTO MÁS GRANDE */
    min-height: 70px !important; /* ✅ ALTURA MÍNIMA MÁS GRANDE */
    margin: 24px 0 !important; /* ✅ MARGIN MÁS GRANDE */
}

</style>


