<script lang="ts">
  import TarjetaCurso from './TarjetaCurso.svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { onMount } from 'svelte';
  
  // Props opcionales para permitir modo externo (legacy)
  export let inscripciones: any[] = [];
  export let isLoading: boolean = false;
  export let error: string | null = null;
  export let modoExterno: boolean = false; // Para retrocompatibilidad
  export let modoSlider: boolean = false; // Para el slider horizontal moderno
  
  // Estados internos para modo autosuficiente
  let inscripcionesInternas: any[] = [];
  let cargandoInterno = true;
  let errorInterno: string | null = null;

  // Variables reactivas que deciden qué datos usar
  $: datosFinales = modoExterno ? inscripciones : inscripcionesInternas;
  $: cargandoFinal = modoExterno ? isLoading : cargandoInterno;
  $: errorFinal = modoExterno ? error : errorInterno;

  // 🎯 FUNCIÓN PRINCIPAL QUE FUNCIONA PERFECTAMENTE (copiada de la página)
  async function cargarInscripciones() {
    if (!$usuario?.id) {
      cargandoInterno = false;
      return;
    }

    try {
      cargandoInterno = true;
      errorInterno = null;

      console.log('🚀 [GridMisCursos] Cargando inscripciones para usuario:', $usuario.id);

      // Primero obtener todas las inscripciones del usuario
      const { data: inscripcionesData, error } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .order('fecha_inscripcion', { ascending: false });

      if (error) {
        throw error;
      }

      if (!inscripcionesData || inscripcionesData.length === 0) {
        console.log('📭 [GridMisCursos] No hay inscripciones');
        inscripcionesInternas = [];
        return;
      }

      console.log('📋 [GridMisCursos] Inscripciones encontradas:', inscripcionesData.length);

      // Separar las inscripciones por tipo
      const inscripcionesCursos = inscripcionesData.filter((i: any) => i.curso_id);
      const inscripcionesTutoriales = inscripcionesData.filter((i: any) => i.tutorial_id);

      console.log('🎯 [GridMisCursos] Cursos:', inscripcionesCursos.length, 'Tutoriales:', inscripcionesTutoriales.length);

      // Obtener datos de cursos si hay inscripciones a cursos
      let cursosData = [];
      if (inscripcionesCursos.length > 0) {
        const cursoIds = inscripcionesCursos.map((i: any) => i.curso_id);
        const { data: cursos, error: errorCursos } = await supabase
          .from('cursos')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, slug')
          .in('id', cursoIds);
        
        if (errorCursos) {
          console.error('❌ [GridMisCursos] Error cargando cursos:', errorCursos);
        } else {
          cursosData = cursos || [];
          console.log('✅ [GridMisCursos] Cursos cargados:', cursosData.length);
        }
      }

      // Obtener datos de tutoriales si hay inscripciones a tutoriales
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        console.log('🔍 [GridMisCursos] Tutorial IDs a consultar:', tutorialIds);
        
        const { data: tutoriales, error: errorTutoriales } = await supabase
          .from('tutoriales')
          .select('id, titulo, imagen_url, descripcion, categoria')
          .in('id', tutorialIds);
        
        if (errorTutoriales) {
          console.error('❌ [GridMisCursos] Error cargando tutoriales:', errorTutoriales);
        } else {
          tutorialesData = tutoriales || [];
          console.log('✅ [GridMisCursos] Tutoriales cargados:', tutorialesData.length);
          console.log('🔍 [GridMisCursos] Datos completos de tutoriales:', tutorialesData);
          
          // Verificar títulos específicamente
          tutorialesData.forEach((tut: any, index: number) => {
            console.log(`📖 [GridMisCursos] Tutorial ${index + 1}:`, {
              id: tut.id,
              titulo: tut.titulo,
              descripcion: tut.descripcion?.substring(0, 50) + '...',
              imagen_url: tut.imagen_url,
              categoria: tut.categoria
            });
          });
        }
      }

      // Combinar todo - USANDO ESTRUCTURA ORIGINAL (SINGULAR)
      inscripcionesInternas = [
        // Inscripciones a cursos
        ...inscripcionesCursos.map((inscripcion: any) => ({
          ...inscripcion,
          curso: cursosData.find((curso: any) => curso.id === inscripcion.curso_id)  // SINGULAR
        })),
        // Inscripciones a tutoriales
        ...inscripcionesTutoriales.map((inscripcion: any) => {
          const tutorialEncontrado = tutorialesData.find((tutorial: any) => tutorial.id === inscripcion.tutorial_id);
          console.log(`🔗 [GridMisCursos] Mapeo tutorial ID ${inscripcion.tutorial_id}:`, {
            inscripcion: inscripcion,
            tutorialEncontrado: tutorialEncontrado,
            titulo: tutorialEncontrado?.titulo || 'NO ENCONTRADO'
          });
          return {
            ...inscripcion,
            tutorial: tutorialEncontrado  // SINGULAR
          };
        })
      ];

      // Reordenar por fecha de inscripción
      inscripcionesInternas.sort((a, b) => new Date(b.fecha_inscripcion).getTime() - new Date(a.fecha_inscripcion).getTime());

      console.log('🎉 [GridMisCursos] Resultado final:', {
        total: inscripcionesInternas.length,
        cursos: inscripcionesInternas.filter(i => i.curso).length,
        tutoriales: inscripcionesInternas.filter(i => i.tutorial).length,
        items: inscripcionesInternas.map(i => ({
          tipo: i.curso ? 'CURSO' : 'TUTORIAL',
          titulo: i.curso?.titulo || i.tutorial?.titulo
        }))
      });

    } catch (error: any) {
      console.error('💥 [GridMisCursos] Error cargando inscripciones:', error);
      errorInterno = error.message || 'Error desconocido al cargar los cursos';
    } finally {
      cargandoInterno = false;
    }
  }

  onMount(() => {
    if (!modoExterno) {
      cargarInscripciones();
    }
  });

  // Recargar cuando cambie el usuario (solo en modo interno)
  $: if (!modoExterno && $usuario?.id) {
    cargarInscripciones();
  }

  // Función para recargar manualmente
  export function recargar() {
    if (!modoExterno) {
      cargarInscripciones();
    }
  }
</script>

<div class="contenedor-grid">
  {#if cargandoFinal}
    <div class="estado-carga">
      <div class="spinner"></div>
      <p>Cargando tus cursos...</p>
    </div>
  {:else if errorFinal}
    <div class="estado-error">
      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"/>
        <line x1="12" y1="8" x2="12" y2="12"/>
        <line x1="12" y1="16" x2="12.01" y2="16"/>
      </svg>
      <h3>Oops! Algo salió mal</h3>
      <p>{errorFinal}</p>
      <button class="boton-reintentar" on:click={() => modoExterno ? window.location.reload() : cargarInscripciones()}>
        Reintentar
      </button>
    </div>
  {:else if datosFinales.length === 0}
    <div class="estado-vacio">
      <div class="icono-vacio">📚</div>
      <h3>¡Empieza tu aventura!</h3>
      <p>Aún no tienes cursos ni tutoriales inscritos.</p>
      <p>Explora nuestro catálogo y comienza a aprender.</p>
    </div>
  {:else}
    <div class="grid-cursos">
      {#each datosFinales as inscripcion (inscripcion.id)}
        <TarjetaCurso {inscripcion} />
      {/each}
    </div>
  {/if}

  <!-- Debug info solo si NO está en modo slider -->
  {#if !modoSlider && datosFinales.length > 0}
    <div class="debug-info">
      📊 {datosFinales.length} elementos cargados 
      ({datosFinales.filter(i => i.curso).length} cursos, 
      {datosFinales.filter(i => i.tutorial).length} tutoriales)
    </div>
  {/if}
</div>

<style>
  .contenedor-grid {
    width: 100%;
  }

  .grid-cursos {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 24px;
    width: 100%;
  }

  /* Estados de carga, error y vacío */
  .estado-carga,
  .estado-error,
  .estado-vacio {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem 2rem;
    text-align: center;
    gap: 1.5rem;
  }

  .spinner {
    width: 48px;
    height: 48px;
    border: 4px solid #e5e7eb;
    border-top-color: #2563eb;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .estado-carga p {
    color: #6b7280;
    font-size: 1.1rem;
    font-weight: 500;
  }

  .estado-error svg {
    color: #ef4444;
  }

  .estado-error h3 {
    color: #1f2937;
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0;
  }

  .estado-error p {
    color: #6b7280;
    font-size: 1rem;
    margin: 0;
  }

  .boton-reintentar {
    background: #ef4444;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .boton-reintentar:hover {
    background: #dc2626;
    transform: translateY(-1px);
  }

  .estado-vacio svg {
    color: #9ca3af;
  }

  .estado-vacio h3 {
    color: #1f2937;
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0;
  }

  .estado-vacio p {
    color: #6b7280;
    font-size: 1rem;
    margin: 0;
    max-width: 400px;
  }

  .boton-explorar {
    display: flex;
    align-items: center;
    gap: 8px;
    background: #2563eb;
    color: white;
    text-decoration: none;
    padding: 12px 24px;
    border-radius: 12px;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .boton-explorar:hover {
    background: #1d4ed8;
    transform: translateY(-1px);
  }

  /* Responsivo */
  @media (max-width: 768px) {
    .grid-cursos {
      grid-template-columns: 1fr;
      gap: 20px;
    }

    .estado-carga,
    .estado-error,
    .estado-vacio {
      padding: 3rem 1rem;
    }

    .estado-vacio h3,
    .estado-error h3 {
      font-size: 1.25rem;
    }
  }

  @media (max-width: 480px) {
    .grid-cursos {
      gap: 16px;
    }
  }

  /* Ajuste para tablets */
  @media (min-width: 769px) and (max-width: 1024px) {
    .grid-cursos {
      grid-template-columns: repeat(2, 1fr);
    }
  }

  /* Ajuste para pantallas grandes */
  @media (min-width: 1200px) {
    .grid-cursos {
      grid-template-columns: repeat(3, 1fr);
    }
  }

  /* Debug info */
  .debug-info {
    text-align: center;
    background: #f8fafc;
    color: #64748b;
    padding: 12px;
    border-radius: 8px;
    margin-top: 20px;
    font-size: 0.9rem;
    font-weight: 500;
    border: 1px solid #e2e8f0;
  }
</style> 