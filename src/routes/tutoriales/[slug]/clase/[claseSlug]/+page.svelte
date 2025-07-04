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
    mostrarSidebar = !mostrarSidebar;
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
      on:cerrar-sidebar={toggleSidebar}
      tipo="tutorial"
    />
  </div>
</div>

<style>
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
    background-color: #1a1a1a !important;
    color: #fff;
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

</style>
