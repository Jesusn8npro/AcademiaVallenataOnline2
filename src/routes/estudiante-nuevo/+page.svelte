<script lang="ts">
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { goto } from '$app/navigation';
  import TarjetaEstadistica from '$lib/components/DashboardEstudiante/TarjetaEstadistica.svelte';
  import ProgresCircular from '$lib/components/DashboardEstudiante/ProgresCircular.svelte';
  import TarjetaCursoProgreso from '$lib/components/DashboardEstudiante/TarjetaCursoProgreso.svelte';

  // Estados principales
  let cargando = true;
  let inscripciones: any[] = [];
  let error: string | null = null;

  // Estadísticas calculadas
  let estadisticas = {
    cursosInscritos: 0,
    cursosCompletados: 0,
    horasAprendizaje: 0,
    progresoGeneral: 0
  };

  // LÓGICA EXACTA DE MIS CURSOS (100% FUNCIONAL)
  async function cargarDatos() {
    if (!$usuario?.id) {
      cargando = false;
      return;
    }

    try {
      cargando = true;
      error = null;
      console.log('🔍 [DASHBOARD-NUEVO] Iniciando carga de datos para:', $usuario.id);

      // PASO 1: Obtener inscripciones (IGUAL que Mis Cursos)
      const { data: inscripcionesData, error: inscripcionError } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .order('fecha_inscripcion', { ascending: false });

      if (inscripcionError) {
        console.error('❌ Error obteniendo inscripciones:', inscripcionError);
        throw inscripcionError;
      }

      console.log('📋 [DASHBOARD-NUEVO] Inscripciones encontradas:', inscripcionesData?.length || 0);

      if (!inscripcionesData || inscripcionesData.length === 0) {
        inscripciones = [];
        console.log('⚠️ [DASHBOARD-NUEVO] No hay inscripciones');
        cargando = false;
        return;
      }

      // PASO 2: Separar por tipo (IGUAL que Mis Cursos)
      const inscripcionesCursos = inscripcionesData.filter((i: any) => i.curso_id);
      const inscripcionesTutoriales = inscripcionesData.filter((i: any) => i.tutorial_id);

      console.log('📊 [DASHBOARD-NUEVO] Distribución:', {
        cursos: inscripcionesCursos.length,
        tutoriales: inscripcionesTutoriales.length
      });

      // PASO 3: Obtener datos de cursos (IGUAL que Mis Cursos)
      let cursosData = [];
      if (inscripcionesCursos.length > 0) {
        const cursoIds = inscripcionesCursos.map((i: any) => i.curso_id);
        console.log('🔍 [DASHBOARD-NUEVO] Buscando cursos con IDs:', cursoIds);
        
        const { data: cursos, error: cursosError } = await supabase
          .from('cursos')
          .select('id, titulo, descripcion, imagen_url, slug, instructor, categoria')
          .in('id', cursoIds);

        if (cursosError) {
          console.error('❌ Error cargando cursos:', cursosError);
        }
        
        cursosData = cursos || [];
        console.log('📚 [DASHBOARD-NUEVO] Cursos cargados:', cursosData.length, cursosData);
      }

      // PASO 4: Obtener datos de tutoriales (IGUAL que Mis Cursos)
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        console.log('🔍 [DASHBOARD-NUEVO] Buscando tutoriales con IDs:', tutorialIds);
        
        const { data: tutoriales, error: tutorialesError } = await supabase
          .from('tutoriales')
          .select('id, titulo, descripcion, imagen_url, slug, instructor, categoria')
          .in('id', tutorialIds);

        if (tutorialesError) {
          console.error('❌ Error cargando tutoriales:', tutorialesError);
        }
        
        tutorialesData = tutoriales || [];
        console.log('🎵 [DASHBOARD-NUEVO] Tutoriales cargados:', tutorialesData.length, tutorialesData);
      }

      // PASO 5: Combinar todo (IGUAL que Mis Cursos)
      const inscripcionesCombinadas = [
        // Inscripciones a cursos
        ...inscripcionesCursos.map((inscripcion: any) => {
          const cursoEncontrado = cursosData.find((curso: any) => curso.id === inscripcion.curso_id);
          console.log(`🔗 [DASHBOARD-NUEVO] Curso ${inscripcion.curso_id}:`, cursoEncontrado ? '✅ ENCONTRADO' : '❌ NO ENCONTRADO');
          return {
            ...inscripcion,
            cursos: cursoEncontrado
          };
        }),
        // Inscripciones a tutoriales
        ...inscripcionesTutoriales.map((inscripcion: any) => {
          const tutorialEncontrado = tutorialesData.find((tutorial: any) => tutorial.id === inscripcion.tutorial_id);
          console.log(`🔗 [DASHBOARD-NUEVO] Tutorial ${inscripcion.tutorial_id}:`, tutorialEncontrado ? '✅ ENCONTRADO' : '❌ NO ENCONTRADO');
          return {
            ...inscripcion,
            tutoriales: tutorialEncontrado
          };
        })
      ];

      inscripciones = inscripcionesCombinadas;
      console.log('🎯 [DASHBOARD-NUEVO] Inscripciones finales:', inscripciones.length);

      // Calcular estadísticas
      estadisticas = {
        cursosInscritos: inscripciones.length,
        cursosCompletados: inscripciones.filter((i: any) => i.porcentaje_completado >= 100).length,
        horasAprendizaje: 0, // TODO: Calcular
        progresoGeneral: inscripciones.length > 0 
          ? Math.round(inscripciones.reduce((sum: number, i: any) => sum + (i.porcentaje_completado || 0), 0) / inscripciones.length) 
          : 0
      };

      console.log('📊 [DASHBOARD-NUEVO] Estadísticas calculadas:', estadisticas);

    } catch (err) {
      console.error('💥 [DASHBOARD-NUEVO] Error general:', err);
      error = err instanceof Error ? err.message : 'Error desconocido';
    } finally {
      cargando = false;
    }
  }

  // Función auxiliar para calcular tiempo estimado
  function calcularTiempoEstimado(leccionesPendientes: number): string {
    if (leccionesPendientes <= 0) return 'Completado';
    const minutosPromedio = leccionesPendientes * 15;
    if (minutosPromedio < 60) return `${minutosPromedio} min restantes`;
    const horas = Math.round(minutosPromedio / 60 * 10) / 10;
    return `${horas}h restantes`;
  }

  // Saludo dinámico
  function obtenerSaludo(): string {
    const hora = new Date().getHours();
    const nombre = $usuario?.nombre || 'Estudiante';
    if (hora < 12) return `¡Buenos días, ${nombre}! ☀️`;
    if (hora < 18) return `¡Buenas tardes, ${nombre}! 🌅`;
    return `¡Buenas noches, ${nombre}! 🌙`;
  }

  // Cargar datos al montar
  onMount(() => {
    cargarDatos();
  });

  // Recargar cuando cambie el usuario
  $: if ($usuario?.id) {
    cargarDatos();
  }
</script>

<svelte:head>
  <title>Dashboard Estudiante - Academia Vallenata</title>
  <meta name="description" content="Tu panel de estudiante con progreso y cursos" />
</svelte:head>

<div class="dashboard-estudiante">
  <div class="contenedor-principal">
    
    <!-- Encabezado -->
    <header class="encabezado-dashboard">
      <h1 class="titulo-principal">Dashboard de Estudiante</h1>
      <p class="saludo">{obtenerSaludo()}</p>
    </header>

    {#if cargando}
      <!-- Estado de carga -->
      <div class="estado-carga">
        <div class="spinner"></div>
        <p>Cargando tu dashboard...</p>
      </div>
    
    {:else if error}
      <!-- Estado de error -->
      <div class="estado-error">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="8" x2="12" y2="12"/>
          <line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
        <h3>Error al cargar datos</h3>
        <p>{error}</p>
        <button class="boton-reintentar" on:click={cargarDatos}>
          Reintentar
        </button>
      </div>
    
    {:else if inscripciones.length === 0}
      <!-- Estado vacío -->
      <div class="estado-vacio">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <rect x="4" y="4" width="16" height="16" rx="2"/>
          <path d="M8 9h8M8 14h5"/>
        </svg>
        <h3>¡Comienza tu aventura musical!</h3>
        <p>Aún no tienes cursos inscritos. Explora nuestro catálogo y encuentra el curso perfecto para ti.</p>
        <a href="/cursos" class="boton-explorar">
          Explorar Cursos
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M5 12h14M12 5l7 7-7 7"/>
          </svg>
        </a>
      </div>
    
    {:else}
      <!-- Contenido principal -->
      <div class="contenido-dashboard">
        
        <!-- Estadísticas generales -->
        <section class="seccion-estadisticas">
          <h2>📊 Tus Estadísticas</h2>
          <div class="grid-estadisticas">
            <TarjetaEstadistica
              icono="📚"
              valor={estadisticas.cursosInscritos}
              titulo="Cursos Inscritos"
              descripcion="Total de cursos en los que estás inscrito"
              color="azul"
            />
            <TarjetaEstadistica
              icono="🏆"
              valor={estadisticas.cursosCompletados}
              titulo="Cursos Completados"
              descripcion="Cursos que has terminado exitosamente"
              color="verde"
            />
            <TarjetaEstadistica
              icono="⏰"
              valor={estadisticas.horasAprendizaje}
              titulo="Horas de Aprendizaje"
              descripcion="Tiempo total dedicado al estudio"
              color="naranja"
            />
            <TarjetaEstadistica
              icono="📈"
              valor={estadisticas.progresoGeneral}%
              titulo="Progreso General"
              descripcion="Tu avance promedio en todos los cursos"
              color="purpura"
            />
          </div>
        </section>

        <!-- Cursos en progreso -->
        <section class="seccion-cursos">
          <h2>🎯 Continúa Aprendiendo</h2>
          
          {#if inscripciones.length > 0}
            <div class="grid-cursos">
              {#each inscripciones.slice(0, 6) as inscripcion (inscripcion.id)}
                {@const contenido = inscripcion.cursos || inscripcion.tutoriales}
                {@const tipo = inscripcion.cursos ? 'curso' : 'tutorial'}
                {#if contenido}
                  <TarjetaCursoProgreso
                    curso={{
                      id: contenido.id,
                      titulo: contenido.titulo,
                      descripcion: contenido.descripcion || '',
                      imagen_url: contenido.imagen_url,
                      slug: contenido.slug,
                      porcentaje_completado: inscripcion.porcentaje_completado || 0,
                      ultima_leccion_titulo: 'Continuar donde te quedaste',
                      instructor: contenido.instructor,
                      categoria: contenido.categoria,
                      tipo: tipo,
                      tiempo_estimado: calcularTiempoEstimado(5)
                    }}
                  />
                {/if}
              {/each}
            </div>
          {:else}
            <p class="mensaje-vacio">No tienes cursos en progreso.</p>
          {/if}
        </section>

        <!-- Enlaces rápidos -->
        <section class="seccion-enlaces">
          <h2>⚡ Acceso Rápido</h2>
          <div class="grid-enlaces">
            <a href="/mis-cursos" class="enlace-rapido">
              <div class="icono-enlace">📚</div>
              <div class="texto-enlace">
                <h3>Mis Cursos</h3>
                <p>Ver todos tus cursos inscritos</p>
              </div>
            </a>
            <a href="/ranking" class="enlace-rapido">
              <div class="icono-enlace">🏆</div>
              <div class="texto-enlace">
                <h3>Ranking</h3>
                <p>Ve tu posición en la comunidad</p>
              </div>
            </a>
          </div>
        </section>

      </div>
    {/if}

  </div>
</div>

<style>
  .dashboard-estudiante {
    min-height: 100vh;
    background: linear-gradient(135deg, #f0f4f8 0%, #e2e8f0 100%);
    padding: 2rem;
  }

  .contenedor-principal {
    max-width: 1200px;
    margin: 0 auto;
  }

  .encabezado-dashboard {
    margin-bottom: 2rem;
    text-align: center;
  }

  .titulo-principal {
    font-size: 2.5rem;
    font-weight: 700;
    color: #1a202c;
    margin-bottom: 0.5rem;
  }

  .saludo {
    font-size: 1.2rem;
    color: #4a5568;
    font-weight: 500;
  }

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
    background: white;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  }

  .spinner {
    width: 48px;
    height: 48px;
    border: 4px solid #e2e8f0;
    border-top-color: #3182ce;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .estado-error svg {
    color: #e53e3e;
  }

  .boton-reintentar,
  .boton-explorar {
    background: #3182ce;
    color: white;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    text-decoration: none;
    font-weight: 600;
    transition: all 0.2s;
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .boton-reintentar:hover,
  .boton-explorar:hover {
    background: #2c5aa0;
    transform: translateY(-1px);
  }

  .contenido-dashboard {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .seccion-estadisticas h2,
  .seccion-cursos h2,
  .seccion-enlaces h2 {
    font-size: 1.5rem;
    font-weight: 700;
    color: #2d3748;
    margin-bottom: 1rem;
  }

  .grid-estadisticas {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .grid-cursos {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.5rem;
  }

  .grid-enlaces {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }

  .enlace-rapido {
    background: white;
    padding: 1.5rem;
    border-radius: 12px;
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 1rem;
    transition: all 0.2s;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  }

  .enlace-rapido:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }

  .icono-enlace {
    font-size: 2rem;
    width: 3rem;
    height: 3rem;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #ebf8ff;
    border-radius: 8px;
  }

  .texto-enlace h3 {
    font-size: 1.1rem;
    font-weight: 600;
    color: #2d3748;
    margin: 0 0 0.25rem 0;
  }

  .texto-enlace p {
    font-size: 0.9rem;
    color: #718096;
    margin: 0;
  }

  .mensaje-vacio {
    text-align: center;
    color: #718096;
    font-style: italic;
    padding: 2rem;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .dashboard-estudiante {
      padding: 1rem;
    }

    .titulo-principal {
      font-size: 2rem;
    }

    .grid-estadisticas {
      grid-template-columns: 1fr;
    }

    .grid-cursos {
      grid-template-columns: 1fr;
    }
  }
</style> 