<script lang="ts">
  import TarjetaCurso from '$lib/components/MisCursos/TarjetaCurso.svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { onMount } from 'svelte';

  // Referencias del slider
  let sliderContainer: HTMLElement;
  let canScrollLeft = false;
  let canScrollRight = true;

  // Estados de datos
  let inscripciones: any[] = [];
  let cargando = true;
  let error: string | null = null;

  // Funciones de navegación
  function scrollLeft() {
    if (sliderContainer && inscripciones.length > 0) {
      const containerWidth = sliderContainer.offsetWidth;
      sliderContainer.scrollBy({ 
        left: -containerWidth, // Scroll exacto del ancho del contenedor
        behavior: 'smooth' 
      });
      setTimeout(actualizarBotones, 300);
    }
  }

  function scrollRight() {
    if (sliderContainer && inscripciones.length > 0) {
      const containerWidth = sliderContainer.offsetWidth;
      sliderContainer.scrollBy({ 
        left: containerWidth, // Scroll exacto del ancho del contenedor
        behavior: 'smooth' 
      });
      setTimeout(actualizarBotones, 300);
    }
  }

  function actualizarBotones() {
    if (!sliderContainer) return;
    
    const { scrollLeft, scrollWidth, clientWidth } = sliderContainer;
    canScrollLeft = scrollLeft > 0;
    canScrollRight = scrollLeft < scrollWidth - clientWidth - 10; // Margen de error
  }

  // Cargar inscripciones usando la MISMA LÓGICA que GridMisCursos
  async function cargarInscripciones() {
    if (!$usuario?.id) {
      cargando = false;
      return;
    }

    try {
      cargando = true;
      error = null;

      console.log('🚀 [SliderCursos] Cargando inscripciones para usuario:', $usuario.id);

      // Primero obtener todas las inscripciones del usuario
      const { data: inscripcionesData, error: err } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .order('fecha_inscripcion', { ascending: false });

      if (err) {
        throw err;
      }

      if (!inscripcionesData || inscripcionesData.length === 0) {
        console.log('📭 [SliderCursos] No hay inscripciones');
        inscripciones = [];
        return;
      }

      console.log('📋 [SliderCursos] Inscripciones encontradas:', inscripcionesData.length);

      // Separar las inscripciones por tipo
      const inscripcionesCursos = inscripcionesData.filter((i: any) => i.curso_id);
      const inscripcionesTutoriales = inscripcionesData.filter((i: any) => i.tutorial_id);

      console.log('🎯 [SliderCursos] Cursos:', inscripcionesCursos.length, 'Tutoriales:', inscripcionesTutoriales.length);

      // Obtener datos de cursos si hay inscripciones a cursos
      let cursosData = [];
      if (inscripcionesCursos.length > 0) {
        const cursoIds = inscripcionesCursos.map((i: any) => i.curso_id);
        const { data: cursos, error: errorCursos } = await supabase
          .from('cursos')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, slug')
          .in('id', cursoIds);
        
        if (errorCursos) {
          console.error('❌ [SliderCursos] Error cargando cursos:', errorCursos);
        } else {
          cursosData = cursos || [];
          console.log('✅ [SliderCursos] Cursos cargados:', cursosData.length);
        }
      }

      // Obtener datos de tutoriales si hay inscripciones a tutoriales
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        console.log('🔍 [SliderCursos] Tutorial IDs a consultar:', tutorialIds);
        
        const { data: tutoriales, error: errorTutoriales } = await supabase
          .from('tutoriales')
          .select('id, titulo, imagen_url, descripcion, categoria')
          .in('id', tutorialIds);
        
        if (errorTutoriales) {
          console.error('❌ [SliderCursos] Error cargando tutoriales:', errorTutoriales);
        } else {
          tutorialesData = tutoriales || [];
          console.log('✅ [SliderCursos] Tutoriales cargados:', tutorialesData.length);
        }
      }

      // Combinar todo - USANDO ESTRUCTURA ORIGINAL (SINGULAR)
      inscripciones = [
        // Inscripciones a cursos
        ...inscripcionesCursos.map((inscripcion: any) => ({
          ...inscripcion,
          curso: cursosData.find((curso: any) => curso.id === inscripcion.curso_id)  // SINGULAR
        })),
        // Inscripciones a tutoriales
        ...inscripcionesTutoriales.map((inscripcion: any) => {
          const tutorialEncontrado = tutorialesData.find((tutorial: any) => tutorial.id === inscripcion.tutorial_id);
          return {
            ...inscripcion,
            tutorial: tutorialEncontrado  // SINGULAR
          };
        })
      ];

      // Reordenar por fecha de inscripción
      inscripciones.sort((a, b) => new Date(b.fecha_inscripcion).getTime() - new Date(a.fecha_inscripcion).getTime());

      console.log('🎉 [SliderCursos] Resultado final:', {
        total: inscripciones.length,
        cursos: inscripciones.filter(i => i.curso).length,
        tutoriales: inscripciones.filter(i => i.tutorial).length,
        items: inscripciones.map(i => ({
          tipo: i.curso ? 'CURSO' : 'TUTORIAL',
          titulo: i.curso?.titulo || i.tutorial?.titulo
        }))
      });

    } catch (err: any) {
      console.error('💥 [SliderCursos] Error cargando inscripciones:', err);
      error = err.message || 'Error desconocido al cargar los cursos';
    } finally {
      cargando = false;
    }
  }

  // Reintentar carga
  function reintentar() {
    cargarInscripciones();
  }

  // Navegación
  function irACursos() {
    window.location.href = '/cursos';
  }

  function irATutoriales() {
    window.location.href = '/tutoriales';
  }

  // Reactividad: Actualizar botones cuando cambien las inscripciones
  $: if (inscripciones.length > 0) {
    setTimeout(actualizarBotones, 100);
  }

  // Cargar datos al montar el componente
  onMount(async () => {
    if ($usuario?.id) {
      await cargarInscripciones();
    }
  });
</script>

<div class="slider-contenedor">
  <!-- Header con botones encima -->
  <div class="header-section">
    <div class="titulo-section">
      <h2 class="titulo">Mis Cursos</h2>
      {#if inscripciones.length > 0}
        <span class="badge-progreso">
          {inscripciones.length} contenido{inscripciones.length !== 1 ? 's' : ''}
        </span>
      {/if}
    </div>
    
    <!-- Botones de navegación -->
    <div class="botones-navegacion">
      <button 
        class="btn-nav" 
        class:disabled={!canScrollLeft}
        disabled={!canScrollLeft}
        on:click={scrollLeft}
        aria-label="Anterior"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M15 18l-6-6 6-6"/>
        </svg>
      </button>
      
      <button 
        class="btn-nav" 
        class:disabled={!canScrollRight}
        disabled={!canScrollRight}
        on:click={scrollRight}
        aria-label="Siguiente"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9 18l6-6-6-6"/>
        </svg>
      </button>
    </div>
  </div>

  <!-- Contenido del slider -->
  <div class="slider-wrapper">
    {#if cargando}
      <div class="estado-carga">
        <div class="spinner"></div>
        <p>Cargando tus cursos...</p>
      </div>
    {:else if error}
      <div class="estado-error">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"/>
        </svg>
        <p class="error-mensaje">{error}</p>
        <button class="btn-reintentar" on:click={reintentar}>
          Reintentar
        </button>
      </div>
    {:else if inscripciones.length === 0}
      <div class="estado-vacio">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
          <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
        </svg>
        <h3>¡Comienza tu aprendizaje!</h3>
        <p>No tienes cursos inscritos aún. Explora nuestro catálogo y comienza a aprender acordeón.</p>
        <div class="botones-accion">
          <button class="btn-principal" on:click={irACursos}>
            Ver Cursos
          </button>
          <button class="btn-secundario" on:click={irATutoriales}>
            Ver Tutoriales
          </button>
        </div>
      </div>
    {:else}
      <div 
        class="slider-grid"
        bind:this={sliderContainer}
        on:scroll={actualizarBotones}
      >
        {#each inscripciones as inscripcion}
          <div class="tarjeta-wrapper">
            <TarjetaCurso 
              inscripcion={inscripcion}
            />
          </div>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .slider-contenedor {
    width: 100%;
    max-width: 100%;
    margin: 0 auto;
    padding: 0;
  }

  .header-section {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    padding: 0 4px;
  }

  .titulo-section {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;
  }

  .titulo {
    font-size: 1.75rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0;
  }

  .badge-progreso {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 0.875rem;
    font-weight: 600;
    white-space: nowrap;
  }

  .botones-navegacion {
    display: flex;
    gap: 8px;
    flex-shrink: 0;
  }

  .btn-nav {
    width: 40px;
    height: 40px;
    border: 1px solid #e5e7eb;
    background: white;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s ease;
    color: #4b5563;
  }

  .btn-nav:hover:not(.disabled) {
    background: #f3f4f6;
    border-color: #d1d5db;
    transform: translateY(-1px);
  }

  .btn-nav.disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }

  .slider-wrapper {
    width: 100%;
    position: relative;
    overflow: hidden;
  }

  .slider-grid {
    display: flex;
    gap: 0;
    overflow-x: auto;
    scroll-behavior: smooth;
    scrollbar-width: none;
    -ms-overflow-style: none;
    scroll-snap-type: x mandatory;
    padding: 0;
  }

  .slider-grid::-webkit-scrollbar {
    display: none;
  }

  .tarjeta-wrapper {
    flex: 0 0 100%;
    min-width: 100%;
    width: 100%;
    scroll-snap-align: start;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 0 10px;
    box-sizing: border-box;
  }

  .tarjeta-wrapper :global(.tarjeta-curso) {
    width: 100%;
    max-width: 100%;
    margin: 0;
  }

  /* Estados */
  .estado-carga,
  .estado-error,
  .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 60px 20px;
    text-align: center;
  }

  .estado-carga {
    color: #6b7280;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid #f3f4f6;
    border-top: 3px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 16px;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .estado-error {
    color: #ef4444;
  }

  .error-mensaje {
    margin: 16px 0;
    font-size: 1.1rem;
  }

  .btn-reintentar {
    background: #ef4444;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.2s ease;
  }

  .btn-reintentar:hover {
    background: #dc2626;
  }

  .estado-vacio {
    color: #6b7280;
  }

  .estado-vacio h3 {
    color: #1f2937;
    font-size: 1.5rem;
    margin: 20px 0 12px;
  }

  .estado-vacio p {
    font-size: 1.1rem;
    margin-bottom: 32px;
    max-width: 500px;
  }

  .botones-accion {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
    justify-content: center;
  }

  .btn-principal {
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
    border: none;
    padding: 14px 28px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
  }

  .btn-principal:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(59, 130, 246, 0.4);
  }

  .btn-secundario {
    background: white;
    color: #3b82f6;
    border: 2px solid #3b82f6;
    padding: 12px 28px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .btn-secundario:hover {
    background: #3b82f6;
    color: white;
    transform: translateY(-1px);
  }

  /* Adaptativo para SIDEBAR PEQUEÑO (como en publicaciones) */
  @container (max-width: 400px) {
    .titulo {
      font-size: 1.4rem;
    }

    .badge-progreso {
      font-size: 0.8rem;
      padding: 4px 8px;
    }

    .btn-nav {
      width: 32px;
      height: 32px;
    }

    .tarjeta-wrapper {
      padding: 0 8px; /* Menos padding en pantallas pequeñas */
    }

    .estado-carga,
    .estado-error,
    .estado-vacio {
      padding: 40px 16px;
    }

    .estado-vacio h3 {
      font-size: 1.2rem;
    }

    .estado-vacio p {
      font-size: 0.95rem;
    }
  }

  /* ESTILOS GLOBALES para CONTENEDORES ESPECÍFICOS */
  
  /* Para columna derecha de COMUNIDAD (320px) */
  :global(.columna-derecha) .slider-contenedor {
    max-width: 300px;
    margin: 0 auto;
  }

  :global(.columna-derecha) .titulo {
    font-size: 1.4rem !important;
  }

  :global(.columna-derecha) .badge-progreso {
    font-size: 0.8rem !important;
    padding: 4px 8px !important;
  }

  :global(.columna-derecha) .btn-nav {
    width: 32px !important;
    height: 32px !important;
  }

  :global(.columna-derecha) .tarjeta-wrapper {
    padding: 0 8px !important; /* Centrar con padding mínimo */
  }

  /* Para bloque-cursos de PUBLICACIONES (350px) */
  :global(.bloque-cursos) .slider-contenedor {
    max-width: 320px;
    margin: 0 auto;
  }

  :global(.bloque-cursos) .titulo {
    font-size: 1.4rem !important;
  }

  :global(.bloque-cursos) .badge-progreso {
    font-size: 0.8rem !important;
    padding: 4px 8px !important;
  }

  :global(.bloque-cursos) .btn-nav {
    width: 32px !important;
    height: 32px !important;
  }

  :global(.bloque-cursos) .tarjeta-wrapper {
    padding: 0 8px !important; /* Centrar con padding mínimo */
  }

  :global(.bloque-cursos) .estado-carga,
  :global(.bloque-cursos) .estado-error,
  :global(.bloque-cursos) .estado-vacio {
    padding: 40px 16px !important;
  }

  :global(.bloque-cursos) .estado-vacio h3 {
    font-size: 1.2rem !important;
  }

  :global(.bloque-cursos) .estado-vacio p {
    font-size: 0.95rem !important;
  }

  /* Responsive general */
  @media (max-width: 768px) {
    .header-section {
      flex-direction: column;
      gap: 16px;
      align-items: flex-start;
    }

    .titulo-section {
      width: 100%;
      justify-content: space-between;
    }

    .titulo {
      font-size: 1.5rem;
    }

    .botones-navegacion {
      align-self: flex-end;
    }

    .tarjeta-wrapper {
      padding: 0 5px; /* Padding mínimo en móviles */
    }

    .botones-accion {
      flex-direction: column;
      width: 100%;
      max-width: 300px;
    }

    .btn-principal,
    .btn-secundario {
      width: 100%;
    }
  }
</style> 