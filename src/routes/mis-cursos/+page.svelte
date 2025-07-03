<script lang="ts">
  import EncabezadoPerfil from '$lib/components/PanelPrincipal/EncabezadoPerfil.svelte';
  import PestanasPerfil from '$lib/components/PanelPrincipal/PestanasPerfil.svelte';
  import GridMisCursos from '$lib/components/MisCursos/GridMisCursos.svelte';
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { progresoLecciones } from '$lib/progresoLeccionesStore';
  import { obtenerProgresoCurso } from '$lib/services/progresoService';
  import { obtenerProgresoTutorial } from '$lib/services/progresoTutorialService';

  let inscripciones: any[] = [];
  let isLoading = true;
  let error: string | null = null;
  let perfilData: any = {};
  let statsData = { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };

  onMount(async () => {
    if (!$usuario?.id) {
      error = 'Debes iniciar sesión para ver tus cursos.';
      isLoading = false;
      return;
    }
    
    // Cargar perfil y inscripciones en paralelo
    await Promise.all([
      cargarPerfilYEstadisticas(),
      cargarInscripciones()
    ]);
  });

  async function cargarPerfilYEstadisticas() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const [perfilResult, statsResult] = await Promise.all([
          supabase.from('perfiles').select('*').eq('id', user.id).single(),
          cargarEstadisticasComunidad(user.id)
        ]);
        
        perfilData = perfilResult.data || { nombre_completo: user.email, id: user.id };
        statsData = statsResult;
      }
    } catch (err) {
      console.error('Error cargando perfil:', err);
    }
  }

  async function cargarEstadisticasComunidad(userId: string) {
    try {
      const { count: conteoPublicaciones } = await supabase.from('comunidad_publicaciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId);
      const { count: conteoCursos } = await supabase.from('inscripciones').select('*', { count: 'exact', head: true }).eq('usuario_id', userId);
      const { count: conteoTutoriales } = await supabase.from('progreso_tutorial').select('*', { count: 'exact', head: true }).eq('usuario_id', userId).eq('completado', true);
      const { data: rankingData } = await supabase.from('perfiles').select('id').order('puntos_comunidad', { ascending: false });
      const posicionRanking = rankingData ? rankingData.findIndex((p: any) => p.id === userId) + 1 : 0;
      
      return {
        publicaciones: conteoPublicaciones || 0,
        cursos: conteoCursos || 0,
        tutoriales: conteoTutoriales || 0,
        ranking: posicionRanking || 0
      };
    } catch (error) {
      console.error('Error cargando estadísticas:', error);
      return { publicaciones: 0, cursos: 0, tutoriales: 0, ranking: 0 };
    }
  }

  async function cargarInscripciones() {
    try {
      isLoading = true;
      error = null;

      // Obtener inscripciones del usuario
      const { data: inscripcionesData, error: err1 } = await supabase
        .from('inscripciones')
        .select('id, curso_id, tutorial_id, usuario_id, progreso, completado, fecha_inscripcion')
        .eq('usuario_id', $usuario!.id);

      if (err1) {
        error = 'Error al cargar tus inscripciones.';
        return;
      }

      if (!inscripcionesData || inscripcionesData.length === 0) {
        inscripciones = [];
        return;
      }

      // Separar IDs de cursos y tutoriales
      const cursoIds = inscripcionesData.filter((insc: any) => insc.curso_id).map((insc: any) => insc.curso_id);
      const tutorialIds = inscripcionesData.filter((insc: any) => insc.tutorial_id).map((insc: any) => insc.tutorial_id);

      // Cargar datos de cursos y tutoriales
      const [cursosData, tutorialesData] = await Promise.all([
        cursoIds.length ? supabase.from('cursos').select('id, titulo, imagen_url, slug, descripcion_corta').in('id', cursoIds) : Promise.resolve({ data: [] }),
        tutorialIds.length ? supabase.from('tutoriales').select('id, titulo, imagen_url, descripcion, categoria').in('id', tutorialIds) : Promise.resolve({ data: [] })
      ]);

      // Crear mapas para acceso rápido
      const cursosMap = new Map((cursosData.data || []).map((curso: any) => [curso.id, curso]));
      const tutorialesMap = new Map((tutorialesData.data || []).map((tutorial: any) => [tutorial.id, tutorial]));

      // Combinar datos
      inscripciones = inscripcionesData.map((inscripcion: any) => {
        if (inscripcion.curso_id && cursosMap.has(inscripcion.curso_id)) {
          return {
            ...inscripcion,
            curso: cursosMap.get(inscripcion.curso_id)
          };
        } else if (inscripcion.tutorial_id && tutorialesMap.has(inscripcion.tutorial_id)) {
          return {
            ...inscripcion,
            tutorial: tutorialesMap.get(inscripcion.tutorial_id)
          };
        }
        return inscripcion;
      }).filter((inscripcion: any) => inscripcion.curso || inscripcion.tutorial);

      // Cargar progreso para cada curso/tutorial en el store
      await cargarProgresoEnStore();

    } catch (err) {
      console.error('Error:', err);
      error = 'Ocurrió un error inesperado.';
    } finally {
      isLoading = false;
    }
  }

  async function cargarProgresoEnStore() {
    const progresoMap: any = {};
    
    // Cargar progreso para cada inscripción
    for (const inscripcion of inscripciones) {
      try {
        if (inscripcion.curso_id) {
          // Es un curso
          const { data } = await obtenerProgresoCurso(inscripcion.curso_id);
          if (data) {
            progresoMap[inscripcion.curso_id] = {
              partes_completadas: data.partes_completadas || 0,
              total_partes: data.total_partes || 0,
              progreso: data.progreso || 0
            };
          }
        } else if (inscripcion.tutorial_id) {
          // Es un tutorial
          const { data } = await obtenerProgresoTutorial(inscripcion.tutorial_id);
          if (data) {
            progresoMap[inscripcion.tutorial_id] = {
              partes_completadas: data.partes_completadas || 0,
              total_partes: data.total_partes || 0,
              progreso: data.progreso || 0
            };
          }
        }
      } catch (error) {
        console.error('Error cargando progreso:', error);
        // En caso de error, usar valores por defecto
        const contenidoId = inscripcion.curso_id || inscripcion.tutorial_id;
        if (contenidoId) {
          progresoMap[contenidoId] = {
            partes_completadas: 0,
            total_partes: 0,
            progreso: 0
          };
        }
      }
    }
    
    // Actualizar el store con todos los datos de progreso
    progresoLecciones.set(progresoMap);
    console.log('Progreso cargado en store:', progresoMap);
  }
</script>

<div class="contenedor-mis-cursos">
  <EncabezadoPerfil 
    bind:nombreCompleto={perfilData.nombre_completo} 
    bind:correoElectronico={perfilData.correo_electronico} 
    bind:urlAvatar={perfilData.url_foto_perfil} 
    bind:urlPortada={perfilData.portada_url} 
    bind:posicionPortadaY={perfilData.posicion_img_portada}
    userId={perfilData.id}
    stats={statsData}
  />
  
  <PestanasPerfil />
  
  <div class="contenido-principal">
    <GridMisCursos {inscripciones} {isLoading} {error} />
  </div>
</div>

<style>
  /* Forzar background blanco en toda la página */
  :global(body) {
    background: #fff !important;
    background-color: #fff !important;
  }

  .contenedor-mis-cursos {
    max-width: 1500px;
    margin: 2rem auto;
    padding: 0 1rem;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
    background: #fff !important; /* Asegurar background blanco */
    min-height: 100vh;
  }

  .contenido-principal {
    background: #fff !important; /* Forzar background blanco */
    border-radius: 16px;
    padding: 2rem;
    box-shadow: 0 4px 24px 0 rgba(0,0,0,0.04);
  }

  @media (max-width: 900px) {
    .contenido-principal {
      padding: 1.5rem;
    }
  }

  @media (max-width: 640px) {
    .contenedor-mis-cursos {
      margin: 1rem auto;
      padding: 0;
    }
    
    .contenido-principal {
      padding: 1rem;
      border-radius: 12px;
    }
  }
</style>
