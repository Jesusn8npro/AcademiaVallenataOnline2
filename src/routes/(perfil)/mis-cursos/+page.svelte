<script lang="ts">
  import GridMisCursos from '$lib/components/MisCursos/GridMisCursos.svelte';
  import PorcentajePerfil from '$lib/components/Banners/PorcentajePerfil.svelte';
  import BannerSlider from '$lib/components/Banners/BannerSlider.svelte';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { onMount } from 'svelte';

  // Usar datos del store en lugar de cargar por separado
  $: perfilData = $perfilStore.perfil;
  $: cargandoPerfil = $perfilStore.cargando;

  // Estados para las inscripciones
  let inscripciones: any[] = [];
  let cargandoCursos = true;
  let errorCursos: string | null = null;

  async function cargarInscripciones() {
    if (!$usuario?.id) {
      cargandoCursos = false;
      return;
    }

    try {
      cargandoCursos = true;
      errorCursos = null;

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
        inscripciones = [];
        return;
      }

      // Separar las inscripciones por tipo
      const inscripcionesCursos = inscripcionesData.filter((i: any) => i.curso_id);
      const inscripcionesTutoriales = inscripcionesData.filter((i: any) => i.tutorial_id);

      // Obtener datos de cursos si hay inscripciones a cursos
      let cursosData = [];
      if (inscripcionesCursos.length > 0) {
        const cursoIds = inscripcionesCursos.map((i: any) => i.curso_id);
        const { data: cursos } = await supabase
          .from('cursos')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, slug')
          .in('id', cursoIds);
        cursosData = cursos || [];
      }

      // Obtener datos de tutoriales si hay inscripciones a tutoriales
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        const { data: tutoriales } = await supabase
          .from('tutoriales')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, artista, acordeonista, tonalidad')
          .in('id', tutorialIds);
        tutorialesData = tutoriales || [];
      }

      // Combinar todo
      inscripciones = [
        // Inscripciones a cursos
        ...inscripcionesCursos.map((inscripcion: any) => ({
          ...inscripcion,
          cursos: cursosData.find((curso: any) => curso.id === inscripcion.curso_id)
        })),
        // Inscripciones a tutoriales
        ...inscripcionesTutoriales.map((inscripcion: any) => ({
          ...inscripcion,
          tutoriales: tutorialesData.find((tutorial: any) => tutorial.id === inscripcion.tutorial_id)
        }))
      ];

      // Reordenar por fecha de inscripción
      inscripciones.sort((a, b) => new Date(b.fecha_inscripcion).getTime() - new Date(a.fecha_inscripcion).getTime());
    } catch (error: any) {
      console.error('Error cargando inscripciones:', error);
      errorCursos = error.message || 'Error desconocido al cargar los cursos';
    } finally {
      cargandoCursos = false;
    }
  }

  onMount(() => {
    cargarInscripciones();
  });

  // Recargar cuando cambie el usuario
  $: if ($usuario?.id) {
    cargarInscripciones();
  }
</script>

<svelte:head>
  <title>Mis Cursos - Academia Vallenata</title>
  <meta name="description" content="Accede a todos tus cursos de acordeón vallenato" />
</svelte:head>

<div class="contenido-mis-cursos">
  <div class="layout-mis-cursos">
    <div class="columna-principal">
      <div class="header-seccion">
        <h1>Mis Cursos</h1>
        <p>Continúa con tu aprendizaje de acordeón vallenato</p>
      </div>
      
      <!-- Pasar las props necesarias a GridMisCursos -->
      <GridMisCursos 
        {inscripciones}
        isLoading={cargandoCursos}
        error={errorCursos}
      />
    </div>
    
    <aside class="columna-lateral">
      <div class="widgets-contenedor">
        {#if perfilData}
          <PorcentajePerfil perfil={perfilData} />
        {/if}
        <BannerSlider />
      </div>
    </aside>
  </div>
</div>

<style>
  .contenido-mis-cursos {
    padding: 2rem;
  }

  .layout-mis-cursos {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 2.5rem;
    align-items: start;
  }

  .columna-principal {
    min-width: 0;
  }

  .header-seccion {
    margin-bottom: 2rem;
  }

  .header-seccion h1 {
    font-size: 2rem;
    font-weight: 700;
    color: #1f2937;
    margin-bottom: 0.5rem;
  }

  .header-seccion p {
    color: #6b7280;
    font-size: 1.1rem;
  }

  .columna-lateral {
    position: sticky;
    top: 2rem;
  }

  .widgets-contenedor {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  @media (max-width: 900px) {
    .contenido-mis-cursos {
      padding: 1.5rem;
    }

    .layout-mis-cursos {
      grid-template-columns: 1fr;
      gap: 2rem;
    }

    .columna-lateral {
      order: 1;
      position: static;
    }

    .columna-principal {
      order: 0;
    }
  }

  @media (max-width: 640px) {
    .contenido-mis-cursos {
      padding: 1rem;
    }
    
    .header-seccion h1 {
      font-size: 1.75rem;
    }
  }
</style> 