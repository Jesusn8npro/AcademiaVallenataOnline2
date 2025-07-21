<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';
  import { obtenerTutorialCompletoPorSlug } from '$lib/services/tutorialService';
  import ModulosCurso from '$lib/components/MisCursos/ModulosCurso.svelte';
  import TutorialClases from '$lib/components/MisCursos/TutorialClases.svelte';
  import BarraProgresoAvanzada from '$lib/components/MisCursos/BarraProgresoAvanzada.svelte';
  import BotonContinuar from '$lib/components/MisCursos/BotonContinuar.svelte';

  // Variables principales
  let slug: string = '';
  let contenido: any = null;
  let inscripcion: any = null;
  let progreso: any = {};
  let estadisticasProgreso = { completadas: 0, total: 0, porcentaje: 0 };
  let tipoContenido: 'curso' | 'tutorial' = 'curso';
  let proximaLeccion: any = null;
  
  // Estados
  let cargando = true;
  let error: string | null = null;

  // Obtener slug de la URL
  $: slug = $page.params.slug;

  // Función para cargar inscripción
  async function cargarInscripcion() {
    if (!$usuario?.id || !contenido?.id) return;
    
    try {
      const { data: inscripcionData, error: inscripcionError } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario!.id)
        .eq(tipoContenido === 'curso' ? 'curso_id' : 'tutorial_id', contenido.id)
        .single();

      if (inscripcionError) {
        console.error('Error cargando inscripción:', inscripcionError);
        return;
      }

      inscripcion = inscripcionData;
    } catch (error) {
      console.error('Error cargando inscripción:', error);
    }
  }

  // Función para cargar progreso
  async function cargarProgreso() {
    if (!$usuario?.id || !contenido?.id) return;

    try {
      if (tipoContenido === 'curso') {
        await cargarProgresoCurso();
      } else {
        await cargarProgresoTutorial();
      }
    } catch (error) {
      console.error('Error cargando progreso:', error);
    }
  }

  // Función para cargar progreso de curso
  async function cargarProgresoCurso() {
    if (!contenido?.modulos) return;

    const todasLasLecciones = contenido.modulos.flatMap((m: any) => m.lecciones || []);
    
    if (todasLasLecciones.length === 0) return;

    const leccionIds = todasLasLecciones.map((l: any) => l.id);
    
    const { data: progresoData, error: progresoError } = await supabase
      .from('progreso_lecciones')
      .select('leccion_id, estado, porcentaje_completado')
      .eq('usuario_id', $usuario!.id)
      .in('leccion_id', leccionIds);

    if (progresoError) {
      console.error('Error cargando progreso curso:', progresoError);
      return;
    }

    // Construir mapa de progreso
    progreso = {};
    progresoData?.forEach((p: any) => {
      progreso[p.leccion_id] = {
        estado: p.estado,
        porcentaje: p.porcentaje_completado || 0
      };
    });

    // Calcular estadísticas
    const completadas = progresoData?.filter((p: any) => p.estado === 'completada').length || 0;
    const total = todasLasLecciones.length;
    const porcentaje = total > 0 ? Math.round((completadas / total) * 100) : 0;

    estadisticasProgreso = { completadas, total, porcentaje };

    // Encontrar próxima lección
    encontrarProximaLeccionCurso();
  }

  // Función para cargar progreso de tutorial
  async function cargarProgresoTutorial() {
    if (!contenido?.partes) return;

    const parteIds = contenido.partes.map((p: any) => p.id);
    
    const { data: progresoData, error: progresoError } = await supabase
      .from('progreso_tutorial')
      .select('parte_tutorial_id, completado')
      .eq('usuario_id', $usuario!.id)
      .eq('tutorial_id', contenido.id);

    if (progresoError) {
      console.error('Error cargando progreso tutorial:', progresoError);
      return;
    }

    // Construir mapa de progreso
    progreso = {};
    progresoData?.forEach((p: any) => {
      progreso[p.parte_tutorial_id] = {
        completado: p.completado
      };
    });

    // Calcular estadísticas
    const completadas = progresoData?.filter((p: any) => p.completado).length || 0;
    const total = contenido.partes.length;
    const porcentaje = total > 0 ? Math.round((completadas / total) * 100) : 0;

    estadisticasProgreso = { completadas, total, porcentaje };

    // Encontrar próxima clase
    encontrarProximaClaseTutorial();
  }

  // Función para encontrar próxima lección en curso
  function encontrarProximaLeccionCurso() {
    if (!contenido?.modulos) return;

    for (const modulo of contenido.modulos) {
      const leccionPendiente = modulo.lecciones?.find((l: any) => 
        !progreso[l.id] || progreso[l.id].estado !== 'completada'
      );
      
      if (leccionPendiente) {
        proximaLeccion = {
          leccion: leccionPendiente,
          modulo: modulo,
          ruta: `/cursos/${slug}/${modulo.slug}/${leccionPendiente.slug}`
        };
        break;
      }
    }
  }

  // Función para encontrar próxima clase en tutorial
  function encontrarProximaClaseTutorial() {
    if (!contenido?.partes) return;

    const clasePendiente = contenido.partes.find((p: any) => 
      !progreso[p.id] || !progreso[p.id].completado
    );
    
    if (clasePendiente) {
      proximaLeccion = {
        clase: clasePendiente,
        ruta: `/tutoriales/${slug}/clase/${clasePendiente.slug}`
      };
    }
  }

  // Función para cargar contenido
  async function cargarContenido() {
    if (!slug || !$usuario?.id) return;

    try {
      cargando = true;
      error = null;

      // Primero intentar cargar como curso
      const { curso, error: cursoError } = await obtenerCursoCompletoPorSlug(slug);
      
      if (curso && !cursoError) {
        // Verificar si el usuario está inscrito en el curso
        const { data: inscripcionCurso } = await supabase
          .from('inscripciones')
          .select('*')
          .eq('usuario_id', $usuario.id)
          .eq('curso_id', curso.id)
          .single();

        if (inscripcionCurso) {
          contenido = curso;
          tipoContenido = 'curso';
          await cargarInscripcion();
          await cargarProgreso();
          return;
        }
      }

      // Si no es curso, intentar como tutorial
      const { tutorial, partes, error: tutorialError } = await obtenerTutorialCompletoPorSlug(slug);
      
      if (tutorial && !tutorialError) {
        // Verificar si el usuario está inscrito en el tutorial
        const { data: inscripcionTutorial } = await supabase
          .from('inscripciones')
          .select('*')
          .eq('usuario_id', $usuario.id)
          .eq('tutorial_id', tutorial.id)
          .single();

        if (inscripcionTutorial) {
          contenido = { ...tutorial, partes };
          tipoContenido = 'tutorial';
          await cargarInscripcion();
          await cargarProgreso();
          return;
        }
      }

      // Si llegamos aquí, no se encontró contenido o no está inscrito
      error = 'No tienes acceso a este contenido o no estás inscrito.';
      
    } catch (err) {
      console.error('Error cargando contenido:', err);
      error = 'Error al cargar el contenido. Inténtalo nuevamente.';
    } finally {
      cargando = false;
    }
  }

  // Función para navegar a la próxima lección
  function continuarAprendizaje() {
    if (proximaLeccion?.ruta) {
      goto(proximaLeccion.ruta);
    }
  }

  // Cargar contenido al montar el componente
  onMount(() => {
    if (slug && $usuario?.id) {
      cargarContenido();
    }
  });

  // Recargar cuando cambie el usuario o el slug
  $: if (slug && $usuario?.id) {
    cargarContenido();
  }
</script>

<svelte:head>
  <title>{contenido ? `${contenido.titulo} - Mis Cursos` : 'Mis Cursos'}</title>
  <meta name="description" content="Accede a todas las lecciones y módulos de tu curso" />
</svelte:head>

<div class="contenido-detalle-curso">
  {#if cargando}
    <div class="estado-carga">
      <div class="spinner"></div>
      <h2>Cargando tu contenido...</h2>
      <p>Preparando todos los módulos y lecciones para ti</p>
    </div>
  {:else if error}
    <div class="estado-error">
      <div class="error-icono">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="8" x2="12" y2="12"/>
          <line x1="12" y1="16" x2="12.01" y2="16"/>
        </svg>
      </div>
      <h2>¡Oops! Algo salió mal</h2>
      <p>{error}</p>
      <div class="botones-error">
        <button class="boton-reintentar" on:click={() => cargarContenido()}>
          Intentar de nuevo
        </button>
        <a href="/mis-cursos" class="boton-volver">
          Volver a Mis Cursos
        </a>
      </div>
    </div>
  {:else if contenido}
    <div class="header-contenido">
      <div class="breadcrumb">
        <a href="/mis-cursos">Mis Cursos</a>
        <span class="separador">/</span>
        <span class="actual">{contenido.titulo}</span>
      </div>
      
      <div class="info-principal">
        <div class="imagen-contenido">
          <img 
            src={contenido.imagen_url || '/images/default-curso.jpg'} 
            alt={contenido.titulo}
            loading="lazy"
          />
          <div class="badge-tipo" class:curso={tipoContenido === 'curso'} class:tutorial={tipoContenido === 'tutorial'}>
            {tipoContenido === 'curso' ? 'Curso' : 'Tutorial'}
          </div>
        </div>
        
        <div class="detalles-contenido">
          <h1>{contenido.titulo}</h1>
          <p class="descripcion">{contenido.descripcion}</p>
          
          <div class="metadatos">
            <div class="metadato">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
              </svg>
              <span>
                {#if tipoContenido === 'curso'}
                  {estadisticasProgreso.total} lecciones
                {:else}
                  {estadisticasProgreso.total} clases
                {/if}
              </span>
            </div>
            
            <div class="metadato">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              <span>Nivel {contenido.nivel}</span>
            </div>
            
            {#if inscripcion}
              <div class="metadato">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"/>
                </svg>
                <span>Inscrito el {new Date(inscripcion.fecha_inscripcion).toLocaleDateString('es-ES')}</span>
              </div>
            {/if}
          </div>
        </div>
      </div>
    </div>

    <div class="contenido-principal">
      <div class="columna-izquierda">
        <div class="seccion-progreso">
          <h2>Tu Progreso</h2>
          <BarraProgresoAvanzada 
            {estadisticasProgreso}
            {tipoContenido}
          />
        </div>

        <div class="seccion-navegacion">
          {#if proximaLeccion}
            <div class="acciones-aprendizaje">
              <BotonContinuar 
                {proximaLeccion}
                {tipoContenido}
                on:continuar={continuarAprendizaje}
              />
              <div class="navegacion-hint">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                </svg>
                <span>O explora todos los {tipoContenido === 'curso' ? 'módulos' : 'clases'} abajo</span>
              </div>
            </div>
          {:else}
            <div class="curso-completado">
              <div class="icono-completado">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 12l2 2 4-4"/>
                  <circle cx="12" cy="12" r="10"/>
                </svg>
              </div>
              <h3>¡Felicidades! Has completado este {tipoContenido}</h3>
              <p>Has terminado todas las {tipoContenido === 'curso' ? 'lecciones' : 'clases'} disponibles.</p>
              <a href="/mis-cursos" class="boton-volver-cursos">
                Ver Más Cursos
              </a>
            </div>
          {/if}
        </div>

        <div class="seccion-contenido">
          <div class="contenido-header">
            <h2>
              {#if tipoContenido === 'curso'}
                Todos los Módulos y Lecciones
              {:else}
                Todas las Clases del Tutorial
              {/if}
            </h2>
            <p class="contenido-descripcion">
              {#if tipoContenido === 'curso'}
                Haz clic en cualquier lección para acceder directamente a ella
              {:else}
                Haz clic en cualquier clase para acceder directamente a ella
              {/if}
            </p>
          </div>
          
          {#if tipoContenido === 'curso'}
            <ModulosCurso 
              curso={contenido}
              {progreso}
              {slug}
            />
          {:else}
            <TutorialClases 
              tutorial={contenido}
              {progreso}
              {slug}
            />
          {/if}
        </div>
      </div>

      <div class="columna-derecha">
        <div class="widget-informacion">
          <h3>Información del {tipoContenido === 'curso' ? 'Curso' : 'Tutorial'}</h3>
          <div class="info-widget">
            <div class="stat">
              <div class="stat-numero">{estadisticasProgreso.porcentaje}%</div>
              <div class="stat-label">Completado</div>
            </div>
            <div class="stat">
              <div class="stat-numero">{estadisticasProgreso.completadas}</div>
              <div class="stat-label">{tipoContenido === 'curso' ? 'Lecciones' : 'Clases'} Vistas</div>
            </div>
            <div class="stat">
              <div class="stat-numero">{estadisticasProgreso.total - estadisticasProgreso.completadas}</div>
              <div class="stat-label">Pendientes</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .contenido-detalle-curso {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    min-height: 100vh;
  }

  /* Estados de carga y error */
  .estado-carga,
  .estado-error {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 60vh;
    text-align: center;
    gap: 1.5rem;
  }

  .spinner {
    width: 48px;
    height: 48px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .estado-carga h2,
  .estado-error h2 {
    color: #1e293b;
    margin: 0;
    font-size: 1.5rem;
  }

  .estado-carga p,
  .estado-error p {
    color: #64748b;
    margin: 0;
    font-size: 1rem;
  }

  .error-icono {
    color: #ef4444;
  }

  .botones-error {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
  }

  .boton-reintentar,
  .boton-volver {
    padding: 12px 24px;
    border-radius: 12px;
    font-weight: 600;
    text-decoration: none;
    border: none;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .boton-reintentar {
    background: #3b82f6;
    color: white;
  }

  .boton-reintentar:hover {
    background: #2563eb;
    transform: translateY(-2px);
  }

  .boton-volver {
    background: #f1f5f9;
    color: #475569;
  }

  .boton-volver:hover {
    background: #e2e8f0;
    transform: translateY(-2px);
  }

  /* Header del contenido */
  .header-contenido {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
  }

  .breadcrumb {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 1.5rem;
    font-size: 0.9rem;
  }

  .breadcrumb a {
    color: #3b82f6;
    text-decoration: none;
    transition: color 0.2s ease;
  }

  .breadcrumb a:hover {
    color: #2563eb;
  }

  .separador {
    color: #94a3b8;
  }

  .actual {
    color: #64748b;
    font-weight: 500;
  }

  .info-principal {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 2rem;
    align-items: start;
  }

  .imagen-contenido {
    position: relative;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  }

  .imagen-contenido img {
    width: 100%;
    height: 200px;
    object-fit: cover;
  }

  .badge-tipo {
    position: absolute;
    top: 12px;
    right: 12px;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .badge-tipo.curso {
    background: rgba(59, 130, 246, 0.9);
    color: white;
  }

  .badge-tipo.tutorial {
    background: rgba(168, 85, 247, 0.9);
    color: white;
  }

  .detalles-contenido h1 {
    font-size: 2rem;
    font-weight: 800;
    color: #1e293b;
    margin: 0 0 1rem 0;
    line-height: 1.2;
  }

  .descripcion {
    color: #64748b;
    font-size: 1.1rem;
    line-height: 1.6;
    margin-bottom: 1.5rem;
  }

  .metadatos {
    display: flex;
    flex-wrap: wrap;
    gap: 1.5rem;
  }

  .metadato {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #64748b;
    font-size: 0.9rem;
  }

  .metadato svg {
    color: #3b82f6;
  }

  /* Contenido principal */
  .contenido-principal {
    display: grid;
    grid-template-columns: 1fr 300px;
    gap: 2rem;
  }

  .columna-izquierda {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .seccion-progreso,
  .seccion-navegacion,
  .seccion-contenido {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
  }

  .seccion-progreso h2,
  .seccion-contenido h2 {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 1.5rem 0;
  }

  .curso-completado {
    text-align: center;
    padding: 2rem;
  }

  .icono-completado {
    color: #10b981;
    margin-bottom: 1rem;
  }

  .curso-completado h3 {
    color: #1e293b;
    font-size: 1.25rem;
    font-weight: 700;
    margin: 0 0 0.5rem 0;
  }

  .curso-completado p {
    color: #64748b;
    margin: 0 0 1.5rem 0;
  }

  .boton-volver-cursos {
    display: inline-block;
    background: #3b82f6;
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .boton-volver-cursos:hover {
    background: #2563eb;
    transform: translateY(-2px);
  }

  /* Sección de acciones de aprendizaje */
  .acciones-aprendizaje {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    align-items: center;
  }

  .navegacion-hint {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    color: #64748b;
    font-size: 0.9rem;
    font-weight: 500;
    padding: 0.75rem 1rem;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
  }

  .navegacion-hint svg {
    color: #f59e0b;
  }

  /* Header del contenido */
  .contenido-header {
    margin-bottom: 2rem;
    text-align: center;
  }

  .contenido-header h2 {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 0.5rem 0;
  }

  .contenido-descripcion {
    color: #64748b;
    font-size: 1rem;
    margin: 0;
  }

  /* Columna derecha */
  .widget-informacion {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
    position: sticky;
    top: 2rem;
  }

  .widget-informacion h3 {
    color: #1e293b;
    font-size: 1.25rem;
    font-weight: 700;
    margin: 0 0 1.5rem 0;
  }

  .info-widget {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  .stat {
    text-align: center;
    padding: 1rem;
    background: #f8fafc;
    border-radius: 12px;
    border: 1px solid #e2e8f0;
  }

  .stat-numero {
    font-size: 2rem;
    font-weight: 800;
    color: #3b82f6;
    margin-bottom: 0.5rem;
  }

  .stat-label {
    color: #64748b;
    font-size: 0.875rem;
    font-weight: 500;
  }

  /* Responsive */
  @media (max-width: 1024px) {
    .contenido-principal {
      grid-template-columns: 1fr;
    }
    
    .widget-informacion {
      position: static;
    }
    
    .info-widget {
      flex-direction: row;
      justify-content: space-around;
    }
  }

  @media (max-width: 768px) {
    .contenido-detalle-curso {
      padding: 1rem;
    }
    
    .info-principal {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
    
    .imagen-contenido {
      max-width: 250px;
      margin: 0 auto;
    }
    
    .detalles-contenido h1 {
      font-size: 1.5rem;
    }
    
    .metadatos {
      flex-direction: column;
      gap: 1rem;
    }

    .navegacion-hint {
      font-size: 0.8rem;
      padding: 0.5rem 0.75rem;
    }

    .contenido-header {
      margin-bottom: 1.5rem;
    }

    .contenido-header h2 {
      font-size: 1.25rem;
    }
  }
</style> 