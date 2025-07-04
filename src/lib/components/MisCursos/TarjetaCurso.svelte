<script lang="ts">
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import BarraProgresoGeneral from '$lib/components/VisualiizadorDeLeccionesDeCursos/BarraProgresoGeneral.svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { progresoLecciones } from '$lib/progresoLeccionesStore';
  import { obtenerCursoCompletoPorSlug } from '$lib/services/cursoService';
  import { usuario } from '$lib/UsuarioActivo/usuario';

  // Props
  export let inscripcion: any;
  
  // Variables reactivas
  $: esCurso = !!inscripcion.curso;
  $: esTutorial = !!inscripcion.tutorial;
  $: contenido = esCurso ? inscripcion.curso : inscripcion.tutorial;
  $: titulo = contenido?.titulo || 'Sin título';
  $: imagen = contenido?.imagen_url || '/images/default-curso.jpg';
  $: slug = contenido?.slug || generateSlug(titulo);
  $: progreso = inscripcion.progreso || 0;
  $: completado = inscripcion.completado || false;
  $: fechaInscripcion = inscripcion.fecha_inscripcion ? new Date(inscripcion.fecha_inscripcion).toLocaleDateString('es-ES') : '';
  
  // Determinar texto del botón basado en progreso real del store
  $: progresoReal = $progresoLecciones[esCurso ? inscripcion.curso_id : inscripcion.tutorial_id];
  $: tieneProgreso = progresoReal && (progresoReal.partes_completadas || 0) > 0;
  $: textoBoton = tieneProgreso ? 'Continuar' : 'Empezar';
  $: tipoContenido = esCurso ? 'Curso' : 'Tutorial';
  $: contenidoId = esCurso ? inscripcion.curso_id : inscripcion.tutorial_id;

  // Función que usa el MISMO SERVICIO que funciona en la página de detalles
  async function navegarAContenido() {
    console.log('[TarjetaCurso] navegarAContenido - contenido:', contenido);
    console.log('[TarjetaCurso] navegarAContenido - tipo:', esCurso ? 'curso' : 'tutorial');
    console.log('[TarjetaCurso] tieneProgreso:', tieneProgreso);

    if (esCurso) {
      // LÓGICA PARA CURSOS MEJORADA CON MANEJO DE PROGRESO
      const cursoSlug = contenido.slug || generateSlug(contenido.titulo);
      
      try {
        const { curso: cursoCompleto, error: errCurso } = await obtenerCursoCompletoPorSlug(cursoSlug);
        if (errCurso || !cursoCompleto) {
            console.error('[TarjetaCurso] No se pudo cargar el curso completo para navegación', errCurso);
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
                        console.log('[TarjetaCurso][CURSO][CONTINUAR] Navegando a:', rutaDestino);
                        goto(rutaDestino);
                        return; // Navegación exitosa a la siguiente lección
                    }
                } else {
                  console.error("Error fetching course progress, will navigate to first lesson.", progresoError);
                }
            }
        }

        // FALLBACK: Si no hay progreso, o todo está completo, o hubo un error. Navegar a la primera lección.
        console.log('[TarjetaCurso][CURSO][EMPEZAR/REPASAR] Navegando a primera lección.');
        if (cursoCompleto.modulos && cursoCompleto.modulos.length > 0) {
            const primerModulo = cursoCompleto.modulos.find((m: any) => m.lecciones && m.lecciones.length > 0);
            if (primerModulo) {
                const primeraLeccion = primerModulo.lecciones[0];
                const moduloSlug = primerModulo.slug || generateSlug(primerModulo.titulo);
                const leccionSlug = primeraLeccion.slug || generateSlug(primeraLeccion.titulo);
                const rutaDestino = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
                console.log('[TarjetaCurso][CURSO] rutaDestino Fallback:', rutaDestino);
                goto(rutaDestino);
                return;
            }
        }
        
        console.warn('[TarjetaCurso] No se encontraron lecciones en el curso, navegando a la página de detalles.');
        goto(`/cursos/${cursoSlug}`);

      } catch (error) {
          console.error('[TarjetaCurso] Error en navegación de curso:', error);
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
          console.error('[TarjetaCurso] Error cargando clases del tutorial o no hay clases:', clasesError);
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
              console.log('[TarjetaCurso][TUTORIAL][CONTINUAR] Navegando a:', rutaDestino);
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
        console.log('[TarjetaCurso][TUTORIAL][EMPEZAR/REPASAR] Navegando a:', rutaDestino);
        goto(rutaDestino);
        return;

      } catch (error) {
        console.error('[TarjetaCurso] Error en navegación de tutorial:', error);
        goto(`/tutoriales/${tutorialSlug}`);
        return;
      }
    }

    alert('No se encontró la primera lección o clase.\\n\\nRevisa la consola (F12) para ver la estructura de datos recibida.');
    console.error('[TarjetaCurso][ERROR][GENERAL] contenido:', contenido);
  }
</script>

<article class="tarjeta-curso">
  <div class="imagen-contenedor">
    <img 
      src={imagen} 
      alt={titulo}
      class="imagen-curso"
      loading="lazy"
    />
    <div class="badge-tipo" class:curso={esCurso} class:tutorial={esTutorial}>
      {tipoContenido}
    </div>
    {#if completado}
      <div class="badge-completado">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M9 12l2 2 4-4"/>
          <circle cx="12" cy="12" r="10"/>
        </svg>
        Completado
      </div>
    {/if}
  </div>
  
  <div class="contenido-tarjeta">
    <div class="info-principal">
      <h3 class="titulo-curso">{titulo}</h3>
      <p class="fecha-inscripcion">Inscrito el {fechaInscripcion}</p>
    </div>
    
    <div class="progreso-seccion">
      <BarraProgresoGeneral 
        tipo={esCurso ? 'curso' : 'tutorial'} 
        contenidoId={contenidoId} 
      />
    </div>
    
    <div class="acciones">
      <button on:click={navegarAContenido} class="boton-continuar" class:completado>
        {textoBoton}
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M5 12h14M12 5l7 7-7 7"/>
        </svg>
      </button>
    </div>
  </div>
</article>

<style>
  .tarjeta-curso {
    background: #ffffff;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .tarjeta-curso:hover {
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12);
    transform: translateY(-4px);
  }

  .imagen-contenedor {
    position: relative;
    width: 100%;
    height: 200px;
    overflow: hidden;
  }

  .imagen-curso {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
  }

  .tarjeta-curso:hover .imagen-curso {
    transform: scale(1.05);
  }

  .badge-tipo {
    position: absolute;
    top: 12px;
    left: 12px;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .badge-tipo.curso {
    background: rgba(37, 99, 235, 0.9);
    color: white;
  }

  .badge-tipo.tutorial {
    background: rgba(168, 85, 247, 0.9);
    color: white;
  }

  .badge-completado {
    position: absolute;
    top: 12px;
    right: 12px;
    background: rgba(34, 197, 94, 0.9);
    color: white;
    padding: 4px 8px;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .contenido-tarjeta {
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 16px;
    flex: 1;
  }

  .info-principal {
    flex: 1;
  }

  .titulo-curso {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1f2937;
    margin: 0 0 8px 0;
    line-height: 1.3;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  .fecha-inscripcion {
    font-size: 0.875rem;
    color: #6b7280;
    margin: 0;
  }

  .progreso-seccion {
    margin: 8px 0;
  }

  .acciones {
    margin-top: auto;
  }

  .boton-continuar {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    width: 100%;
    padding: 12px 24px;
    background: #2563eb;
    color: white;
    text-decoration: none;
    border: none;
    border-radius: 12px;
    font-weight: 600;
    font-size: 0.95rem;
    transition: all 0.2s ease;
    cursor: pointer;
    font-family: inherit;
  }

  .boton-continuar:hover {
    background: #1d4ed8;
    transform: translateY(-1px);
  }

  .boton-continuar.completado {
    background: #059669;
  }

  .boton-continuar.completado:hover {
    background: #047857;
  }

  /* Responsivo */
  @media (max-width: 768px) {
    .imagen-contenedor {
      height: 160px;
    }

    .contenido-tarjeta {
      padding: 16px;
      gap: 12px;
    }

    .titulo-curso {
      font-size: 1.1rem;
    }

    .boton-continuar {
      padding: 10px 20px;
      font-size: 0.9rem;
    }
  }
</style> 