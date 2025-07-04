<script lang="ts">
  import { onMount } from 'svelte';
  import { inscripcionesComunidad, cargarInscripcionesComunidad } from '$lib/components/MisCursos/storeMisCursosComunidad';
  import { progresoLecciones } from '$lib/progresoLeccionesStore';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import BarraProgresoGeneral from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraProgresoGeneral.svelte';
  import { obtenerProgresoCurso } from '$lib/services/progresoService';
  import { obtenerProgresoTutorial } from '$lib/services/progresoTutorialService';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';

  let currentIndex = 0;
  let carouselContainer: HTMLElement;
  let itemWidth = 280;

  onMount(async () => {
    await cargarInscripcionesComunidad();
    await cargarProgresoEnStore();
  });

  $: inscripciones = ($inscripcionesComunidad.inscripciones as any[]) || [];
  $: totalItems = inscripciones.length;
  $: maxIndex = Math.max(0, totalItems - 1);

  // Re-cargar progreso cuando cambien las inscripciones o el usuario
  $: if (inscripciones.length > 0 && $usuario?.id) {
    cargarProgresoEnStore();
  }

  // Usar exactamente la misma función que la página de Mis Cursos
  async function cargarProgresoEnStore() {
    if (!$usuario?.id || inscripciones.length === 0) return;

    const progresoMap: any = {};
    
    // Cargar progreso para cada inscripción usando los servicios que ya funcionan
    for (const inscripcion of inscripciones) {
      try {
        if (inscripcion.curso_id) {
          // Es un curso - usar el servicio que funciona
          const { data } = await obtenerProgresoCurso(inscripcion.curso_id);
          if (data) {
            progresoMap[inscripcion.curso_id] = {
              partes_completadas: data.partes_completadas || 0,
              total_partes: data.total_partes || 0,
              progreso: data.progreso || 0
            };
          }
        } else if (inscripcion.tutorial_id) {
          // Es un tutorial - usar el servicio que funciona
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
    progresoLecciones.update(store => ({ ...store, ...progresoMap }));
    console.log('Progreso cargado en slider:', progresoMap);
  }

  function nextSlide() {
    if (currentIndex < maxIndex) {
      currentIndex++;
    }
  }

  function prevSlide() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }

  function goToSlide(index: number) {
    currentIndex = Math.max(0, Math.min(index, maxIndex));
  }

  function determinarTextoBoton(inscripcion: any) {
    const esCurso = !!inscripcion.curso;
    const progresoReal = $progresoLecciones[esCurso ? inscripcion.curso_id : inscripcion.tutorial_id];
    const tieneProgreso = progresoReal && (progresoReal.partes_completadas || 0) > 0;
    
    if (inscripcion.completado) return 'Completado';
    if (tieneProgreso) return 'Continuar';
    return 'Empezar';
  }

  // NAVEGACIÓN INTELIGENTE - COPIADA EXACTAMENTE DE TarjetaCurso.svelte
  async function navegarAContenido(inscripcion: any) {
    const esCurso = !!inscripcion.curso;
    const esTutorial = !!inscripcion.tutorial;
    const contenido = esCurso ? inscripcion.curso : inscripcion.tutorial;
    const progresoReal = $progresoLecciones[esCurso ? inscripcion.curso_id : inscripcion.tutorial_id];
    const tieneProgreso = progresoReal && (progresoReal.partes_completadas || 0) > 0;

    console.log('[SliderCursos] navegarAContenido - contenido:', contenido);
    console.log('[SliderCursos] navegarAContenido - tipo:', esCurso ? 'curso' : 'tutorial');
    console.log('[SliderCursos] tieneProgreso:', tieneProgreso);

    if (esCurso) {
      // LÓGICA PARA CURSOS MEJORADA CON MANEJO DE PROGRESO
      const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
      
      try {
        const { curso: cursoCompleto, error: errCurso } = await obtenerCursoCompletoPorSlug(cursoSlug);
        if (errCurso || !cursoCompleto) {
            console.error('[SliderCursos] No se pudo cargar el curso completo para navegación', errCurso);
            goto(`/cursos/${cursoSlug}`);
            return;
        }

        // Si el usuario tiene progreso, intentar llevarlo a la siguiente lección pendiente
        if (tieneProgreso && $usuario) {
            const todasLasLeccionesIds = cursoCompleto.modulos.flatMap((m: any) => m.lecciones?.map((l: any) => l.id) || []).filter(Boolean);

            if (todasLasLeccionesIds.length > 0) {
                const { data: progresoData, error: progresoError } = await supabase
                    .from('progreso_lecciones')
                    .select('leccion_id, estado')
                    .eq('usuario_id', $usuario.id)
                    .in('leccion_id', todasLasLeccionesIds);
                
                if (!progresoError) {
                    const leccionesCompletadas = new Set(
                        progresoData.filter((p: any) => p.estado === 'completada').map((p: any) => p.leccion_id)
                    );

                    let proximaLeccion = null;
                    let moduloDeLaLeccion = null;

                    for (const modulo of cursoCompleto.modulos) {
                        const leccionEncontrada = modulo.lecciones?.find((l: any) => !leccionesCompletadas.has(l.id));
                        if (leccionEncontrada) {
                            proximaLeccion = leccionEncontrada;
                            moduloDeLaLeccion = modulo;
                            break;
                        }
                    }

                    if (proximaLeccion && moduloDeLaLeccion) {
                        const moduloSlug = moduloDeLaLeccion.slug || generateSlug(moduloDeLaLeccion.titulo);
                        const leccionSlug = proximaLeccion.slug || generateSlug(proximaLeccion.titulo);
                        const rutaDestino = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
                        console.log('[SliderCursos][CURSO][CONTINUAR] Navegando a:', rutaDestino);
                        goto(rutaDestino);
                        return; // Navegación exitosa a la siguiente lección
                    }
                } else {
                  console.error("Error fetching course progress, will navigate to first lesson.", progresoError);
                }
            }
        }

        // FALLBACK: Si no hay progreso, o todo está completo, o hubo un error. Navegar a la primera lección.
        console.log('[SliderCursos][CURSO][EMPEZAR/REPASAR] Navegando a primera lección.');
        if (cursoCompleto.modulos && cursoCompleto.modulos.length > 0) {
            const primerModulo = cursoCompleto.modulos.find((m: any) => m.lecciones && m.lecciones.length > 0);
            if (primerModulo) {
                const primeraLeccion = primerModulo.lecciones[0];
                const moduloSlug = primerModulo.slug || generateSlug(primerModulo.titulo);
                const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
                const rutaDestino = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
                console.log('[SliderCursos][CURSO] rutaDestino Fallback:', rutaDestino);
                goto(rutaDestino);
                return;
            }
        }
        
        console.warn('[SliderCursos] No se encontraron lecciones en el curso, navegando a la página de detalles.');
        goto(`/cursos/${cursoSlug}`);

      } catch (error) {
          console.error('[SliderCursos] Error en navegación de curso:', error);
          goto(`/cursos/${cursoSlug}`);
          return;
      }
    }

    if (esTutorial) {
      // LÓGICA PARA TUTORIALES - AHORA IGUAL DE INTELIGENTE QUE LA DE CURSOS
      const tutorialSlug = contenido.slug || generateSlug(contenido.titulo);

      try {
        // 1. Cargar todas las clases (partes) del tutorial
        const { data: todasLasClases, error: clasesError } = await supabase
          .from('partes_tutorial')
          .select('id, titulo, slug, orden')
          .eq('tutorial_id', contenido.id)
          .order('orden', { ascending: true });

        if (clasesError || !todasLasClases || todasLasClases.length === 0) {
          console.error('[SliderCursos] Error cargando clases del tutorial o no hay clases:', clasesError);
          goto(`/tutoriales/${tutorialSlug}`); // Ir a la página de detalles como fallback
          return;
        }

        // 2. Si el usuario tiene progreso, buscar la siguiente clase
        if (tieneProgreso && $usuario) {
          const { data: progresoData, error: progresoError } = await supabase
            .from('progreso_tutorial')
            .select('parte_tutorial_id, completado')
            .eq('usuario_id', $usuario.id)
            .eq('tutorial_id', contenido.id);

          if (!progresoError) {
            const clasesCompletadas = new Set(
              progresoData
                .filter((p: any) => p.completado)
                .map((p: any) => p.parte_tutorial_id)
            );

            const proximaClase = todasLasClases.find((clase: any) => !clasesCompletadas.has(clase.id));

            if (proximaClase) {
              const claseSlug = proximaClase.slug || generateSlug(proximaClase.titulo);
              const rutaDestino = `/tutoriales/${tutorialSlug}/clase/${claseSlug}`;
              console.log('[SliderCursos][TUTORIAL][CONTINUAR] Navegando a:', rutaDestino);
              goto(rutaDestino);
              return; // Navegación exitosa
            }
          } else {
            console.error("Error fetching tutorial progress, will navigate to first class.", progresoError);
          }
        }

        // 3. FALLBACK: Si no hay progreso, o todo está completo, o hubo un error. Navegar a la primera clase.
        const primeraClase = todasLasClases[0];
        const claseSlug = primeraClase.slug || generateSlug(primeraClase.titulo);
        const rutaDestino = `/tutoriales/${tutorialSlug}/clase/${claseSlug}`;
        console.log('[SliderCursos][TUTORIAL][EMPEZAR/REPASAR] Navegando a:', rutaDestino);
        goto(rutaDestino);
        return;

      } catch (error) {
        console.error('[SliderCursos] Error en navegación de tutorial:', error);
        goto(`/tutoriales/${tutorialSlug}`);
        return;
      }
    }

    alert('No se encontró la primera lección o clase.\\n\\nRevisa la consola (F12) para ver la estructura de datos recibida.');
    console.error('[SliderCursos][ERROR][GENERAL] contenido:', contenido);
  }
</script>

<div class="slider-container">
  <h3 class="slider-title">
    <span class="titulo-icono">🚀</span> Continúa tu aprendizaje
  </h3>

  {#if $inscripcionesComunidad.isLoading}
    <div class="loading-state">
      <div class="spinner"></div>
      <p>Cargando tus cursos...</p>
    </div>
  {:else if $inscripcionesComunidad.error}
    <div class="error-state">
      <p>❌ {$inscripcionesComunidad.error}</p>
    </div>
  {:else if inscripciones.length === 0}
    <div class="empty-state">
      <p>No tienes cursos inscritos aún.</p>
      <a href="/cursos" class="btn-explorar">Explorar cursos</a>
    </div>
  {:else}
    <div class="carousel-wrapper">
      <!-- Botón anterior -->
      {#if currentIndex > 0}
        <button class="nav-btn nav-btn-prev" on:click={prevSlide}>
          &#8249;
        </button>
      {/if}

      <!-- Contenedor del carousel -->
      <div class="carousel-container" bind:this={carouselContainer}>
        <div 
          class="carousel-track" 
          style="transform: translateX(-{currentIndex * (itemWidth + 16)}px)"
        >
          {#each inscripciones as inscripcion (inscripcion.id)}
            <div class="curso-card">
              <div class="imagen-container">
                <img 
                  src={inscripcion.curso?.imagen_url || inscripcion.tutorial?.imagen_url || '/images/default-curso.jpg'} 
                  alt={inscripcion.curso?.titulo || inscripcion.tutorial?.titulo}
                  class="curso-imagen"
                />
                <div class="badge-tipo">
                  {inscripcion.curso ? 'Curso' : 'Tutorial'}
                </div>
              </div>

              <div class="contenido-card">
                <h4 class="titulo-curso">
                  {inscripcion.curso?.titulo || inscripcion.tutorial?.titulo}
                </h4>

                <!-- Usar BarraProgresoGeneral que ya funciona -->
                <div class="progreso-wrapper">
                  <BarraProgresoGeneral 
                    tipo={inscripcion.curso ? 'curso' : 'tutorial'}
                    contenidoId={inscripcion.curso ? inscripcion.curso_id : inscripcion.tutorial_id}
                  />
                </div>

                <button 
                  class="btn-accion {inscripcion.completado ? 'completado' : ''}"
                  on:click={() => navegarAContenido(inscripcion)}
                >
                  {determinarTextoBoton(inscripcion)}
                </button>
              </div>
            </div>
          {/each}
        </div>
      </div>

      <!-- Botón siguiente -->
      {#if currentIndex < maxIndex}
        <button class="nav-btn nav-btn-next" on:click={nextSlide}>
          &#8250;
        </button>
      {/if}
    </div>

    <!-- Indicadores de página -->
    {#if totalItems > 1}
      <div class="pagination-dots">
        {#each Array(totalItems) as _, i}
          <button 
            class="dot {i === currentIndex ? 'active' : ''}"
            on:click={() => goToSlide(i)}
          />
        {/each}
      </div>
    {/if}
  {/if}
</div>

<style>
  .slider-container {
    width: 100%;
    max-width: 280px;
    margin: 0 auto;
  }

  .slider-title {
    font-size: 1rem;
    font-weight: 600;
    margin-bottom: 1rem;
    color: #1f2937;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .titulo-icono {
    font-size: 1.2rem;
  }

  .carousel-wrapper {
    position: relative;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .carousel-container {
    flex: 1;
    overflow: hidden;
    border-radius: 12px;
  }

  .carousel-track {
    display: flex;
    gap: 16px;
    transition: transform 0.3s ease;
  }

  .curso-card {
    min-width: 280px;
    background: white;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    overflow: hidden;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }

  .curso-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
  }

  .imagen-container {
    position: relative;
    height: 120px;
    overflow: hidden;
  }

  .curso-imagen {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .badge-tipo {
    position: absolute;
    top: 8px;
    right: 8px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
    padding: 4px 8px;
    border-radius: 6px;
    font-size: 0.75rem;
    font-weight: 500;
    text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
  }

  .contenido-card {
    padding: 12px;
  }

  .titulo-curso {
    font-size: 0.9rem;
    font-weight: 600;
    margin-bottom: 8px;
    color: #1f2937;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .progreso-wrapper {
    margin-bottom: 12px;
  }

  .btn-accion {
    width: 100%;
    padding: 8px 16px;
    border: none;
    border-radius: 8px;
    font-weight: 600;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.2s ease;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    color: white;
  }

  .btn-accion:hover {
    background: linear-gradient(135deg, #2563eb, #1e40af);
    transform: translateY(-1px);
  }

  .btn-accion.completado {
    background: linear-gradient(135deg, #10b981, #059669);
  }

  .btn-accion.completado:hover {
    background: linear-gradient(135deg, #059669, #047857);
  }

  .nav-btn {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 32px;
    height: 32px;
    border: none;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.9);
    color: #374151;
    font-size: 18px;
    font-weight: bold;
    cursor: pointer;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
    z-index: 10;
    transition: all 0.2s ease;
  }

  .nav-btn:hover {
    background: white;
    transform: translateY(-50%) scale(1.1);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }

  .nav-btn-prev {
    left: -16px;
  }

  .nav-btn-next {
    right: -16px;
  }

  .pagination-dots {
    display: flex;
    justify-content: center;
    gap: 6px;
    margin-top: 12px;
  }

  .dot {
    width: 8px;
    height: 8px;
    border: none;
    border-radius: 50%;
    background: #d1d5db;
    cursor: pointer;
    transition: background-color 0.2s ease;
  }

  .dot.active {
    background: #3b82f6;
  }

  .loading-state, .error-state, .empty-state {
    text-align: center;
    padding: 24px;
    background: #f9fafb;
    border-radius: 12px;
    border: 1px solid #e5e7eb;
  }

  .spinner {
    width: 32px;
    height: 32px;
    margin: 0 auto 12px;
    border: 3px solid #e5e7eb;
    border-top: 3px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .btn-explorar {
    display: inline-block;
    margin-top: 12px;
    padding: 8px 16px;
    background: #3b82f6;
    color: white;
    text-decoration: none;
    border-radius: 8px;
    font-weight: 600;
    transition: background-color 0.2s ease;
  }

  .btn-explorar:hover {
    background: #2563eb;
  }

  /* Responsive */
  @media (max-width: 640px) {
    .slider-container {
      max-width: 240px;
    }

    .curso-card {
      min-width: 240px;
    }

    .nav-btn-prev {
      left: -12px;
    }

    .nav-btn-next {
      right: -12px;
    }
  }
</style> 