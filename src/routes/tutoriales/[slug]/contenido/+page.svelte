<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import { obtenerTutorialCompletoPorSlug } from '$lib/services/tutorialService';
  import TutorialClases from '$lib/components/MisCursos/TutorialClases.svelte';
  import BarraProgresoAvanzada from '$lib/components/MisCursos/BarraProgresoAvanzada.svelte';
  import BotonContinuar from '$lib/components/MisCursos/BotonContinuar.svelte';

  // Variables principales
  let slug: string = '';
  let tutorial: any = null;
  let inscripcion: any = null;
  let progreso: any = {};
  let estadisticasProgreso = { completadas: 0, total: 0, porcentaje: 0 };
  let proximaClase: any = null;
  
  // Estados
  let cargando = true;
  let error: string | null = null;

  // Obtener slug de la URL
  $: slug = $page.params.slug;

  // Función para cargar inscripción
  async function cargarInscripcion() {
    if (!$usuario?.id || !tutorial?.id) return;
    
    try {
      const { data: inscripcionData, error: inscripcionError } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario!.id)
        .eq('tutorial_id', tutorial.id)
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

  // Función para cargar progreso de tutorial
  async function cargarProgreso() {
    if (!$usuario?.id || !tutorial?.id) return;

    try {
      if (!tutorial?.partes) return;

      const { data: progresoData, error: progresoError } = await supabase
        .from('progreso_tutorial')
        .select('parte_tutorial_id, completado')
        .eq('usuario_id', $usuario!.id)
        .eq('tutorial_id', tutorial.id);

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
      const total = tutorial.partes.length;
      const porcentaje = total > 0 ? Math.round((completadas / total) * 100) : 0;

      estadisticasProgreso = { completadas, total, porcentaje };

      // Encontrar próxima clase
      encontrarProximaClase();
    } catch (error) {
      console.error('Error cargando progreso:', error);
    }
  }

  // Función para encontrar próxima clase en tutorial
  function encontrarProximaClase() {
    if (!tutorial?.partes) return;

    const clasePendiente = tutorial.partes.find((p: any) => 
      !progreso[p.id] || !progreso[p.id].completado
    );
    
    if (clasePendiente) {
      proximaClase = {
        clase: clasePendiente,
        ruta: `/tutoriales/${slug}/clase/${clasePendiente.slug}`
      };
    }
  }

  // Función para cargar tutorial
  async function cargarTutorial() {
    if (!slug || !$usuario?.id) return;

    try {
      cargando = true;
      error = null;

      // Cargar tutorial completo
      const { tutorial: tutorialData, partes, error: tutorialError } = await obtenerTutorialCompletoPorSlug(slug);
      
      if (tutorialError || !tutorialData) {
        error = 'Tutorial no encontrado.';
        return;
      }

      // TEMPORALMENTE DESHABILITADO: Verificar si el usuario está inscrito
      // TODO: Implementar lógica de acceso más granular (gratuito vs premium)
      
      /* 
      const { data: inscripcionTutorial } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario!.id)
        .eq('tutorial_id', tutorialData.id)
        .single();

      if (!inscripcionTutorial) {
        error = 'No tienes acceso a este tutorial o no estás inscrito.';
        return;
      }
      */

      tutorial = { ...tutorialData, partes };
      await cargarInscripcion();
      await cargarProgreso();
      
    } catch (err) {
      console.error('Error cargando tutorial:', err);
      error = 'Error al cargar el tutorial. Inténtalo nuevamente.';
    } finally {
      cargando = false;
    }
  }

  // Función para navegar a la próxima clase
  function continuarAprendizaje() {
    if (proximaClase?.ruta) {
      goto(proximaClase.ruta);
    }
  }

  // Cargar tutorial al montar el componente
  onMount(() => {
    if (slug && $usuario?.id) {
      cargarTutorial();
    }
  });

  // Recargar cuando cambie el usuario o el slug
  $: if (slug && $usuario?.id) {
    cargarTutorial();
  }
</script>

<svelte:head>
  <title>{tutorial ? `${tutorial.titulo} - Contenido` : 'Contenido del Tutorial'}</title>
  <meta name="description" content="Accede a todas las clases de tu tutorial" />
</svelte:head>

<div class="contenido-detalle-tutorial">
  {#if cargando}
    <div class="estado-carga">
      <div class="spinner"></div>
      <h2>Cargando tu tutorial...</h2>
      <p>Preparando todas las clases para ti</p>
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
        <button class="boton-reintentar" on:click={() => cargarTutorial()}>
          Intentar de nuevo
        </button>
        <a href="/tutoriales" class="boton-volver">
          Volver a Tutoriales
        </a>
      </div>
    </div>
  {:else if tutorial}
    <div class="header-contenido">
      <div class="breadcrumb">
        <a href="/tutoriales">Tutoriales</a>
        <span class="separador">/</span>
        <span class="actual">{tutorial.titulo}</span>
      </div>
      
      <div class="info-principal">
        <div class="imagen-contenido">
          <img 
            src={tutorial.imagen_url || '/images/default-tutorial.jpg'} 
            alt={tutorial.titulo}
            loading="lazy"
          />
          <div class="badge-tipo tutorial">
            Tutorial
          </div>
        </div>
        
        <div class="detalles-contenido">
          <h1>{tutorial.titulo}</h1>
          <p class="descripcion">{tutorial.descripcion}</p>
          
          <div class="metadatos">
            <div class="metadato">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
              </svg>
              <span>{estadisticasProgreso.total} clases</span>
            </div>
            
            <div class="metadato">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
              </svg>
              <span>Nivel {tutorial.nivel}</span>
            </div>
            
            {#if tutorial.artista}
              <div class="metadato">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 18V5l12-2v13"/>
                  <circle cx="6" cy="18" r="3"/>
                  <circle cx="18" cy="16" r="3"/>
                </svg>
                <span>Artista: {tutorial.artista}</span>
              </div>
            {/if}
            
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
            tipoContenido="tutorial"
          />
        </div>

        <div class="seccion-navegacion">
          {#if proximaClase}
            <div class="acciones-aprendizaje">
              <BotonContinuar 
                proximaLeccion={proximaClase}
                tipoContenido="tutorial"
                on:continuar={continuarAprendizaje}
              />
              <div class="navegacion-hint">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
                </svg>
                <span>O explora todas las clases abajo</span>
              </div>
            </div>
          {:else}
            <div class="tutorial-completado">
              <div class="icono-completado">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 12l2 2 4-4"/>
                  <circle cx="12" cy="12" r="10"/>
                </svg>
              </div>
              <h3>¡Felicidades! Has completado este tutorial</h3>
              <p>Has terminado todas las clases disponibles.</p>
              <a href="/tutoriales" class="boton-volver-tutoriales">
                Ver Más Tutoriales
              </a>
            </div>
          {/if}
        </div>

        <div class="seccion-contenido">
          <div class="contenido-header">
            <h2>Todas las Clases del Tutorial</h2>
            <p class="contenido-descripcion">
              Haz clic en cualquier clase para acceder directamente a ella
            </p>
          </div>
          
          <TutorialClases 
            {tutorial}
            {progreso}
            {slug}
          />
        </div>
      </div>

      <div class="columna-derecha">
        <div class="widget-informacion">
          <h3>Información del Tutorial</h3>
          <div class="info-widget">
            <div class="stat">
              <div class="stat-numero">{estadisticasProgreso.porcentaje}%</div>
              <div class="stat-label">Completado</div>
            </div>
            <div class="stat">
              <div class="stat-numero">{estadisticasProgreso.completadas}</div>
              <div class="stat-label">Clases Vistas</div>
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
  .contenido-detalle-tutorial {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
    background: linear-gradient(135deg, #faf5ff 0%, #f3e8ff 100%);
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
    border: 4px solid #e5e7eb;
    border-top: 4px solid #a855f7;
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
    background: #a855f7;
    color: white;
  }

  .boton-reintentar:hover {
    background: #9333ea;
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
    color: #a855f7;
    text-decoration: none;
    transition: color 0.2s ease;
  }

  .breadcrumb a:hover {
    color: #9333ea;
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
    color: #a855f7;
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

  .tutorial-completado {
    text-align: center;
    padding: 2rem;
  }

  .icono-completado {
    color: #10b981;
    margin-bottom: 1rem;
  }

  .tutorial-completado h3 {
    color: #1e293b;
    font-size: 1.25rem;
    font-weight: 700;
    margin: 0 0 0.5rem 0;
  }

  .tutorial-completado p {
    color: #64748b;
    margin: 0 0 1.5rem 0;
  }

  .boton-volver-tutoriales {
    display: inline-block;
    background: #a855f7;
    color: white;
    padding: 12px 24px;
    border-radius: 12px;
    text-decoration: none;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .boton-volver-tutoriales:hover {
    background: #9333ea;
    transform: translateY(-2px);
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
    color: #a855f7;
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
    .contenido-detalle-tutorial {
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