<svelte:head>
  <style>
    footer {
      display: none !important;
    }
    body, html {
      margin: 0;
      padding: 0;
      background: #f4f6fa;
      height: 100%;
    }
  </style>
</svelte:head>

<script lang="ts">
  import { get } from 'svelte/store';
  import { estadoUsuarioActual } from '$lib/supabase/estadoUsuarioActual';
  import EncabezadoLeccion from '$lib/components/VisualiizadorDeLeccionesDeCursos/EncabezadoLeccion.svelte';
  import BarraLateralCurso from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraLateralCurso.svelte';
  import ReproductorLecciones from '$lib/components/VisualiizadorDeLeccionesDeCursos/ReproductorLecciones.svelte';
  import LeccionTabs from '$lib/components/VisualiizadorDeLeccionesDeCursos/LeccionTabs.svelte';
  import { onMount, onDestroy } from 'svelte';
  import { progresoLecciones } from '$lib/progresoLeccionesStore';
  import { supabase } from '$lib/supabase';
  export let data;
  let curso = data.curso;
  let modulo = data.modulo;
  let leccion = data.leccion;
  let mostrarSidebar = true;
  let windowWidth = 0;
  let usuarioActual: any = null;
  $: usuarioActual = get(estadoUsuarioActual).user;

  // Suscripción al store para usarlo en los props
  let progresoLeccionesValue: any = {};
  const unsubscribeProgreso = progresoLecciones.subscribe(val => {
    progresoLeccionesValue = val;
    console.log('[STORE progresoLecciones] Cambio detectado:', JSON.stringify(val));
  });

  // NUEVA VARIABLE COMPUTADA: Transforma el progreso al formato que espera la sidebar
  let progresoParaSidebar: Record<string, number> = {};

  // Carga el estado de completado de TODAS las lecciones del curso
  async function cargarProgresoLeccionesIndividuales() {
    if (!curso || !curso.modulos || !usuarioActual) return;

    // 1. Obtener todos los IDs de las lecciones del curso
    const todosLosIds = curso.modulos.flatMap((m: any) => m.lecciones?.map((l: any) => l.id) || []).filter(Boolean);

    if (todosLosIds.length === 0) return;

    // 2. Consultar el progreso para esos IDs - CORREGIDO PARA EVITAR ERROR 406
    const { data: progresos, error } = await supabase
      .from('progreso_lecciones')
      .select('leccion_id, estado, porcentaje_completado')
      .eq('usuario_id', usuarioActual.id)
      .in('leccion_id', todosLosIds);

    if (error) {
      console.error("Error cargando progreso de lecciones individuales:", error);
      return;
    }

    // 3. Formatear para la sidebar
    const progresoFormateado: Record<string, number> = {};
    progresos.forEach((p: any) => {
      progresoFormateado[p.leccion_id] = p.estado === 'completada' ? 100 : 0;
    });

    progresoParaSidebar = progresoFormateado;
    console.log('[PROGRESO INDIVIDUAL] Cargado para sidebar:', progresoParaSidebar);
  }

  // --- Estados y funciones para marcar como completada ---
  let completada = false;
  let loadingCompletar = false;
  let errorCompletar = '';

  // Cargar progreso global del curso en el store
  async function cargarProgresoGlobal() {
    if (!curso?.id) {
      return;
    }
    
    try {
      const { data, error } = await import('$lib/services/progresoService').then(m => m.obtenerProgresoCurso(curso.id));
      
      if (error) {
        console.error('[cargarProgresoGlobal] Error:', error);
        // En caso de error, usar valores por defecto
        progresoLecciones.update(prev => ({
          ...prev,
          [curso.id]: {
            partes_completadas: 0,
            total_partes: 0,
            progreso: 0
          }
        }));
        return;
      }
      
      if (data) {
        // Asegurar que todos los campos existen con valores por defecto
        const datosSeguro = {
          partes_completadas: data.partes_completadas ?? 0,
          total_partes: data.total_partes ?? 0,
          progreso: data.progreso ?? 0
        };
        
        progresoLecciones.update(prev => ({
          ...prev,
          [curso.id]: datosSeguro
        }));
      } else {
        progresoLecciones.update(prev => ({
          ...prev,
          [curso.id]: {
            partes_completadas: 0,
            total_partes: 0,
            progreso: 0
          }
        }));
      }
    } catch (error) {
      console.error('[cargarProgresoGlobal] Error inesperado:', error);
      // En caso de cualquier error, usar valores por defecto
      progresoLecciones.update(prev => ({
        ...prev,
        [curso.id]: {
          partes_completadas: 0,
          total_partes: 0,
          progreso: 0
        }
      }));
    }
  }

  async function verificarCompletada() {
    if (!leccion?.id || !usuarioActual) return;
    try {
      const { data } = await import('$lib/services/progresoService').then(m => m.obtenerProgresoLeccion(leccion.id));
      completada = !!(data && (data.estado === 'completada' || data.porcentaje_completado === 100));
    } catch (e) {
      completada = false;
    }
  }

  async function marcarComoCompletada() {
    loadingCompletar = true;
    errorCompletar = '';
    
    if (!usuarioActual?.id || !leccion?.id) {
      errorCompletar = `Debes iniciar sesión para marcar la lección como completada.`;
      loadingCompletar = false;
      return;
    }
    
    try {
      const res = await import('$lib/services/progresoService').then(m => m.actualizarProgresoLeccion(leccion.id, true));
      
      if (res.error) {
        errorCompletar = (res.error as any).message || 'Error al marcar como completada';
        console.error('[marcarComoCompletada] ERROR:', res.error);
      } else {
        completada = true;
        // Cuando se completa una lección, recargamos tanto el progreso individual como el global
        await cargarProgresoLeccionesIndividuales();
        await cargarProgresoGlobal();
      }
    } catch (e: any) {
      errorCompletar = `Error inesperado: ${e?.message || e?.toString()}`;
      console.error('[marcarComoCompletada] Error:', e);
    } finally {
      loadingCompletar = false;
    }
  }

  function actualizarProgreso(event: { detail: { porcentaje: number } }) {
    // Esta función ya no es necesaria ya que el progreso se maneja en cargarProgresoGlobal()
    // Se mantiene solo para compatibilidad con componentes que aún la llaman
  }

  onMount(() => {
    console.log('🚀 [PÁGINA LECCIÓN] Componente montado');
    console.log('🚀 [PÁGINA LECCIÓN] Estado inicial:', {
      mostrarSidebar,
      windowWidth,
      curso: !!curso,
      leccion: !!leccion,
      modulo: !!modulo,
      usuarioActual: !!usuarioActual
    });
    
    // Verificar si la lección ya está completada al cargar
    verificarCompletada();
    cargarProgresoLeccionesIndividuales();
    cargarProgresoGlobal();
    
    // Configuración del responsive
    windowWidth = window.innerWidth;
    console.log('🔍 [PÁGINA LECCIÓN] Ancho inicial:', windowWidth);
    
    if (windowWidth < 768) {
      console.log('📱 [PÁGINA LECCIÓN] Móvil detectado, ocultando sidebar');
      mostrarSidebar = false;
    }
    
    const handleResize = () => {
      const newWidth = window.innerWidth;
      console.log('🔍 [PÁGINA LECCIÓN] Resize detectado:', windowWidth, '→', newWidth);
      
      if (newWidth < 768 && mostrarSidebar) {
        console.log('📱 [PÁGINA LECCIÓN] Cambio a móvil, ocultando sidebar');
        mostrarSidebar = false;
      }
      
      windowWidth = newWidth;
    };
    
    window.addEventListener('resize', handleResize);
    
    // 🚨 VERIFICAR VISIBILIDAD DEL ENCABEZADO CADA 3 SEGUNDOS
    const headerVisibilityCheck = setInterval(() => {
      const headerElement = document.querySelector('.lesson-header') as HTMLElement;
      const encabezadoElement = document.querySelector('header') as HTMLElement;
      
      if (headerElement || encabezadoElement) {
        const element = headerElement || encabezadoElement;
        const isVisible = element.offsetHeight > 0 && 
                         window.getComputedStyle(element).display !== 'none' &&
                         window.getComputedStyle(element).visibility !== 'hidden';
        
        console.log('🔍 [PÁGINA LECCIÓN] Verificación encabezado:', {
          offsetHeight: element.offsetHeight,
          display: window.getComputedStyle(element).display,
          visibility: window.getComputedStyle(element).visibility,
          isVisible,
          mostrarSidebar,
          windowWidth
        });
      } else {
        console.log('❌ [PÁGINA LECCIÓN] NO SE ENCUENTRA EL ENCABEZADO');
      }
    }, 3000);
    
    return () => {
      console.log('❌ [PÁGINA LECCIÓN] Componente desmontando');
      clearInterval(headerVisibilityCheck);
      window.removeEventListener('resize', handleResize);
    };
  });

  function toggleSidebar() {
    console.log('🔧 [CURSO] Cerrando sidebar móvil');
    mostrarSidebar = !mostrarSidebar;
  }

  // Función específica para cerrar (desde el botón X)
  function cerrarSidebar() {
    console.log('❌ [CURSO] Cerrando sidebar desde botón X');
    mostrarSidebar = false;
  }
  function cambiarLeccion(event: { detail: { leccion: any } }) {
  const { leccion } = event.detail;
  if (leccion) {
    // Buscar el módulo al que pertenece la nueva lección
    let nuevoModulo = null;
    if (curso && Array.isArray(curso.modulos)) {
      for (const m of curso.modulos) {
        if (m.lecciones && m.lecciones.find((l: any) => l.id === leccion.id)) {
          nuevoModulo = m;
          break;
        }
      }
    }
    // Redirigir a la nueva URL de la lección
    if (nuevoModulo) {
      window.location.href = `/cursos/${curso.slug}/${nuevoModulo.slug || ''}/${leccion.slug}`;
    } else {
      // fallback: usa el módulo actual
      window.location.href = `/cursos/${curso.slug}/${modulo.slug || ''}/${leccion.slug}`;
    }
  }
}
</script>

<div class="contenido-container" class:sidebar-visible={mostrarSidebar}>
  <div class="contenido-principal">
    <!-- 🚨 ENCABEZADO FORZADO A SER VISIBLE -->
    <div style="position: relative; z-index: 1000;">
      <EncabezadoLeccion 
        cursoTitulo={curso.titulo} 
        leccionTitulo={leccion.titulo} 
        cursoId={curso.id}
        leccionId={leccion.id}
        tipo="leccion"
        curso={curso}
        moduloActivo={modulo ? modulo.id : ''}
        progreso={progresoParaSidebar}
        usuarioActual={usuarioActual}
        leccionAnterior={data.leccionAnterior}
        leccionSiguiente={data.leccionSiguiente}
        mostrarSidebar={mostrarSidebar}
        onToggleSidebar={toggleSidebar}
        on:toggle-sidebar={toggleSidebar}
        on:anterior-leccion={cambiarLeccion}
        on:siguiente-leccion={cambiarLeccion}
      />
    </div>
    <div class="reproductor-y-contenido">
      <ReproductorLecciones
        videoUrl={leccion.video_url}
        thumbnailUrl={leccion.thumbnail || leccion.video_miniatura_url}
        titulo={leccion.titulo}
        leccionAnterior={data.leccionAnterior}
        leccionSiguiente={data.leccionSiguiente}
        tipo={"leccion"}
        completada={completada}
        cargandoCompletar={loadingCompletar}
        marcarComoCompletada={marcarComoCompletada}
        errorCompletar={errorCompletar}
        on:anterior-leccion={cambiarLeccion}
        on:siguiente-leccion={cambiarLeccion}
      />
      <LeccionTabs
        contenido={leccion.contenido}
        recursos={leccion.recursos}
        comentarios={leccion.comentarios}
        cursoId={curso.id}
        usuarioActual={usuarioActual}
        leccionId={leccion.id}
        tipo={"leccion"}
        mostrarSidebar={mostrarSidebar}
        clases={modulo && modulo.lecciones ? modulo.lecciones : []}
        curso={curso}
        progreso={progresoLecciones}
      />
    </div>
  </div>
  <!-- OVERLAY móvil que FUNCIONA (igual que EncabezadoLeccion) -->
  {#if mostrarSidebar}
    <div class="sidebar-mobile-overlay" on:click={() => mostrarSidebar = false}>
      <div class="sidebar-mobile-panel" on:click|stopPropagation>
        <BarraLateralCurso
          curso={curso}
          moduloActivo={modulo ? modulo.id : ''}
          leccionActiva={leccion ? leccion.id : ''}
          progreso={progresoParaSidebar}
          tipo="curso"
          on:cambiar-leccion={cambiarLeccion}
          on:cerrar-sidebar={cerrarSidebar}
          cerrarSidebarFuncion={cerrarSidebar}
          bind:mostrarSidebar
        />
      </div>
    </div>
  {/if}
  
  <!-- SIDEBAR original (mantener para desktop) -->
  <div class="leccion-sidebar" class:visible={mostrarSidebar}>
    <BarraLateralCurso
  curso={curso}
  moduloActivo={modulo ? modulo.id : ''}
  leccionActiva={leccion ? leccion.id : ''}
  progreso={progresoParaSidebar}
  tipo="curso"
  on:cambiar-leccion={cambiarLeccion}
  on:cerrar-sidebar={cerrarSidebar}
  cerrarSidebarFuncion={cerrarSidebar}
  bind:mostrarSidebar
/>
  </div>
</div>

<style>
  body, html {
    margin: 0;
    padding: 0;
  }
  .contenido-container {
    display: flex;
    flex: 1;
    min-height: 0;
    background: #f4f6fa;
  }
  .contenido-principal {
    flex: 1;
    min-width: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
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
  @media (max-width: 1200px) {
    .sidebar-visible .leccion-sidebar {
      width: 320px;
    }
    .leccion-sidebar.visible {
      width: 320px;
    }
  }
  @media (max-width: 768px) {
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
</style>
