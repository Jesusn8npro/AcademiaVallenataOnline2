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

  // ✅ Suscripción al store para usarlo en los props - CON MAPEO SEGURO
  let progresoLeccionesValue: any = {};
  const unsubscribeProgreso = progresoLecciones.subscribe(val => {
    // ✅ MAPEO SEGURO: Verificar que el valor sea válido
    if (val && typeof val === 'object') {
      progresoLeccionesValue = val;
      console.log('[STORE progresoLecciones] Cambio detectado:', JSON.stringify(val));
    } else {
      console.warn('[STORE progresoLecciones] Valor inválido recibido:', val);
      progresoLeccionesValue = {};
    }
  });

  // ✅ FUNCIÓN DE INICIALIZACIÓN SEGURA
  function inicializarProgresoSeguro() {
    if (!curso?.id) return;
    
    // Inicializar con valores por defecto si no existe
    const progresoActual = progresoLeccionesValue[curso.id];
    if (!progresoActual) {
      console.log('[INICIALIZACIÓN] Creando progreso por defecto para curso:', curso.id);
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

  // NUEVA VARIABLE COMPUTADA: Transforma el progreso al formato que espera la sidebar
  let progresoParaSidebar: Record<string, number> = {};

  // ✅ Carga el estado de completado de TODAS las lecciones del curso - VERSIÓN CORREGIDA
  async function cargarProgresoLeccionesIndividuales() {
    if (!curso || !curso.modulos || !usuarioActual) {
      console.log('[PROGRESO] Datos insuficientes para cargar progreso');
      return;
    }

    try {
      // 1. Obtener todos los IDs de las lecciones del curso
      const todosLosIds = curso.modulos.flatMap((m: any) => m.lecciones?.map((l: any) => l.id) || []).filter(Boolean);

      if (todosLosIds.length === 0) {
        console.log('[PROGRESO] No hay lecciones para cargar progreso');
        return;
      }

      console.log('[PROGRESO] Intentando cargar progreso para', todosLosIds.length, 'lecciones');

      // 2. Consultar el progreso para esos IDs - CON MANEJO DE ERRORES ROBUSTO
      console.log('[PROGRESO] Usuario ID:', usuarioActual.id);
      console.log('[PROGRESO] Lecciones a consultar:', todosLosIds);
      
      // 🚨 CONSULTA CORREGIDA: Verificar que usuario_id no sea null
      const { data: progresos, error } = await supabase
        .from('progreso_lecciones')
        .select('leccion_id, estado')
        .not('usuario_id', 'is', null)  // Asegurar que usuario_id no sea null
        .eq('usuario_id', usuarioActual.id)
        .in('leccion_id', todosLosIds);

      if (error) {
        console.error("❌ [PROGRESO] Error cargando progreso:", error);
        
        // 🚨 SOLUCIÓN TEMPORAL: Usar valores por defecto
        progresoParaSidebar = {};
        console.log('[PROGRESO] Usando progreso por defecto debido al error');
        return;
      }

      // 3. Formatear para la sidebar - CON MAPEO SEGURO
      const progresoFormateado: Record<string, number> = {};
      if (progresos && Array.isArray(progresos) && progresos.length > 0) {
        progresos.forEach((p: any) => {
          // ✅ MAPEO SEGURO: Verificar que las propiedades existen
          if (p && p.leccion_id && typeof p.estado === 'string') {
            progresoFormateado[p.leccion_id] = p.estado === 'completada' ? 100 : 0;
          } else {
            console.warn('[PROGRESO] Registro inválido:', p);
          }
        });
      } else {
        console.log('[PROGRESO] No hay registros de progreso para formatear');
      }

      progresoParaSidebar = progresoFormateado;
      console.log('✅ [PROGRESO INDIVIDUAL] Cargado para sidebar:', progresoParaSidebar);
      
    } catch (err) {
      console.error('❌ [PROGRESO] Error inesperado:', err);
      // 🚨 SOLUCIÓN TEMPORAL: Usar valores por defecto
      progresoParaSidebar = {};
    }
  }

  // --- Estados y funciones para marcar como completada ---
  let completada = false;
  let loadingCompletar = false;
  let errorCompletar = '';

  // ✅ Cargar progreso global del curso en el store - VERSIÓN CORREGIDA
  async function cargarProgresoGlobal() {
    if (!curso?.id) {
      console.log('[PROGRESO GLOBAL] No hay ID de curso');
      return;
    }
    
    try {
      console.log('[PROGRESO GLOBAL] Cargando progreso para curso:', curso.id);
      
      const { data, error } = await import('$lib/services/progresoService').then(m => m.obtenerProgresoCurso(curso.id));
      
      if (error) {
        console.error('❌ [PROGRESO GLOBAL] Error:', error);
        // 🚨 SOLUCIÓN TEMPORAL: Usar valores por defecto
        progresoLecciones.update(prev => ({
          ...prev,
          [curso.id]: {
            partes_completadas: 0,
            total_partes: 0,
            progreso: 0
          }
        }));
        console.log('[PROGRESO GLOBAL] Usando valores por defecto debido al error');
        return;
      }
      
      if (data) {
        // ✅ MAPEO SEGURO: Asegurar que todos los campos existen con valores por defecto
        const datosSeguro = {
          partes_completadas: typeof data.partes_completadas === 'number' ? data.partes_completadas : 0,
          total_partes: typeof data.total_partes === 'number' ? data.total_partes : 0,
          progreso: typeof data.progreso === 'number' ? data.progreso : 0
        };
        
        console.log('[PROGRESO GLOBAL] Datos originales:', data);
        console.log('[PROGRESO GLOBAL] Datos seguros:', datosSeguro);
        
        progresoLecciones.update(prev => ({
          ...prev,
          [curso.id]: datosSeguro
        }));
        
        console.log('✅ [PROGRESO GLOBAL] Progreso cargado:', datosSeguro);
      } else {
        console.log('[PROGRESO GLOBAL] No hay datos, usando valores por defecto');
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
      console.error('❌ [PROGRESO GLOBAL] Error inesperado:', error);
      // 🚨 SOLUCIÓN TEMPORAL: Usar valores por defecto
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

  // ✅ Verificar si la lección está completada - VERSIÓN CORREGIDA CON MAPEO SEGURO
  async function verificarCompletada() {
    if (!leccion?.id || !usuarioActual) {
      console.log('[VERIFICAR COMPLETADA] Datos insuficientes');
      completada = false; // ✅ VALOR POR DEFECTO
      return;
    }
    
    try {
      console.log('[VERIFICAR COMPLETADA] Verificando lección:', leccion.id);
      
      const { data, error } = await import('$lib/services/progresoService').then(m => m.obtenerProgresoLeccion(leccion.id));
      
      if (error) {
        console.error('❌ [VERIFICAR COMPLETADA] Error:', error);
        completada = false; // ✅ VALOR POR DEFECTO
        return;
      }
      
      // ✅ MAPEO SEGURO: Verificar que data existe y tiene las propiedades necesarias
      if (!data) {
        console.log('[VERIFICAR COMPLETADA] No hay datos de progreso, usando valor por defecto');
        completada = false;
        return;
      }
      
      // ✅ MAPEO SEGURO: Verificar propiedades antes de acceder
      const estado = data.estado || 'pendiente';
      const porcentaje = data.porcentaje_completado || 0;
      
      completada = estado === 'completada' || porcentaje === 100;
      console.log('✅ [VERIFICAR COMPLETADA] Estado:', completada, 'Estado DB:', estado, 'Porcentaje:', porcentaje);
      
    } catch (e) {
      console.error('❌ [VERIFICAR COMPLETADA] Error inesperado:', e);
      completada = false; // ✅ VALOR POR DEFECTO
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
    console.log('[ONMOUNT] Iniciando página de lección...');
    console.log('[ONMOUNT] Curso:', curso);
    console.log('[ONMOUNT] Módulo:', modulo);
    console.log('[ONMOUNT] Lección:', leccion);
    console.log('[ONMOUNT] Usuario:', usuarioActual);
    
    // ✅ INICIALIZACIÓN SEGURA DEL PROGRESO
    inicializarProgresoSeguro();
    
    // ✅ EJECUTAR FUNCIONES DE PROGRESO DE FORMA ASÍNCRONA
    const inicializarProgreso = async () => {
      if (usuarioActual) {
        await cargarProgresoGlobal();
        await cargarProgresoLeccionesIndividuales();
        await verificarCompletada();
      } else {
        console.log('[ONMOUNT] Usuario no autenticado, usando progreso por defecto');
        // ✅ ESTABLECER VALORES POR DEFECTO SI NO HAY USUARIO
        completada = false;
        progresoParaSidebar = {};
      }
    };
    
    // Ejecutar inicialización de progreso
    inicializarProgreso();
    
    // Configuración del responsive
    windowWidth = window.innerWidth;
    if (windowWidth < 768) {
      mostrarSidebar = false;
    }
    
    const handleResize = () => {
      windowWidth = window.innerWidth;
      if (windowWidth < 768) {
        mostrarSidebar = false;
      }
    };
    
    window.addEventListener('resize', handleResize);
    return () => {
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
