<script lang="ts">
  // 🎵 Continuar Aprendiendo - Estilo Platzi
  // Hero principal con última clase visitada
  
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';

  // 📊 Estados
  let cargando = true;
  let ultimaActividad: any = null;
  let error = '';
  
  // 🎠 Estados del slider
  let todasLasActividades: any[] = [];
  let actividadActual = 0;
  let autoPlayInterval: any = null;
  let isPaused = false;
  let isChanging = false;

    // 🎯 LÓGICA EXACTA DE "MIS CURSOS" - COPIADA COMPLETA
  async function cargarUltimaActividad() {
    if (!$usuario?.id) {
      cargando = false;
      return;
    }

    try {
      cargando = true;
      console.log('🎯 [DASHBOARD] Iniciando carga con lógica de Mis Cursos');

      // PASO 1: Obtener TODAS las inscripciones (IGUAL que en Mis Cursos)
      const { data: inscripcionesData, error: inscripcionError } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .order('fecha_inscripcion', { ascending: false });

      if (inscripcionError) {
        console.error('❌ Error obteniendo inscripciones:', inscripcionError);
        throw inscripcionError;
      }

      console.log('📋 [DASHBOARD] Inscripciones encontradas:', inscripcionesData?.length || 0);

      if (!inscripcionesData || inscripcionesData.length === 0) {
        console.log('⚠️ [DASHBOARD] No se encontraron inscripciones');
        ultimaActividad = null;
        return;
      }

      // PASO 2: Separar por tipo (IGUAL que en Mis Cursos)
      const inscripcionesCursos = inscripcionesData.filter((i: any) => i.curso_id);
      const inscripcionesTutoriales = inscripcionesData.filter((i: any) => i.tutorial_id);

      console.log('📊 [DASHBOARD] Distribución:', {
        total: inscripcionesData.length,
        cursos: inscripcionesCursos.length,
        tutoriales: inscripcionesTutoriales.length
      });

      // PASO 3: Obtener datos de CURSOS (IGUAL que en Mis Cursos)
      let cursosData = [];
      if (inscripcionesCursos.length > 0) {
        const cursoIds = inscripcionesCursos.map((i: any) => i.curso_id);
        console.log('📚 [DASHBOARD] Buscando cursos:', cursoIds);
        
        const { data: cursos, error: cursosError } = await supabase
          .from('cursos')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, slug, instructor_id, categoria')
          .in('id', cursoIds);
          
        if (cursosError) {
          console.error('❌ Error obteniendo cursos:', cursosError);
        } else {
          cursosData = cursos || [];
          console.log('✅ [DASHBOARD] Cursos cargados:', cursosData.length);
          console.log('📊 [DASHBOARD] Datos cursos:', cursosData);
        }
      }

      // PASO 4: Obtener datos de TUTORIALES (IGUAL que en Mis Cursos)
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        console.log('🎵 [DASHBOARD] Buscando tutoriales:', tutorialIds);
        
        const { data: tutoriales, error: tutorialesError } = await supabase
          .from('tutoriales')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, artista, acordeonista, tonalidad, instructor_id')
          .in('id', tutorialIds);
          
        if (tutorialesError) {
          console.error('❌ Error obteniendo tutoriales:', tutorialesError);
        } else {
          tutorialesData = tutoriales || [];
          console.log('✅ [DASHBOARD] Tutoriales cargados:', tutorialesData.length);
          console.log('📊 [DASHBOARD] Datos tutoriales:', tutorialesData);
        }
      }

      // PASO 5: Combinar inscripciones con contenido (IGUAL que en Mis Cursos)
      const inscripcionesCombinadas = [
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

      console.log('🔄 [DASHBOARD] Inscripciones combinadas:', inscripcionesCombinadas.length);

      // PASO 6: Calcular progreso REAL usando LÓGICA EXACTA de TarjetaCurso.svelte
      const cursosConProgreso = [];
      
      console.log('🎯 [DASHBOARD] Calculando progreso para', inscripcionesCombinadas.length, 'inscripciones');
      console.log('🎯 [DASHBOARD] Inscripciones detalladas:', inscripcionesCombinadas);
      
      for (const inscripcionCompleta of inscripcionesCombinadas.slice(0, 5)) { // Solo primeros 5
        const esCurso = !!inscripcionCompleta.cursos;
        const contenido = esCurso ? inscripcionCompleta.cursos : inscripcionCompleta.tutoriales;
        const contenidoId = esCurso ? inscripcionCompleta.curso_id : inscripcionCompleta.tutorial_id;
        
        console.log('📊 [DASHBOARD] Procesando:', { 
          tipo: esCurso ? 'curso' : 'tutorial', 
          titulo: contenido?.titulo,
          id: contenidoId 
        });

        if (!contenido || !contenidoId) {
          console.warn('⚠️ [DASHBOARD] Contenido o ID faltante para inscripción');
          continue;
        }
        
        // ===== LÓGICA EXACTA COPIADA DE TarjetaCurso.svelte =====
        let progresoData = { porcentaje: 0, completadas: 0, total: 0 };
        let ultimaLeccionTitulo = null;

        try {
          if (esCurso) {
            // Progreso de curso (COPIA EXACTA)
            const { data: modulos } = await supabase
              .from('modulos')
              .select('id, lecciones(id, titulo, slug, orden)')
              .eq('curso_id', contenidoId);

            if (modulos && modulos.length > 0) {
              const leccionIds = modulos.flatMap((m: any) => m.lecciones?.map((l: any) => l.id) || []);
              
              if (leccionIds.length > 0) {
                const { data: progreso } = await supabase
                  .from('progreso_lecciones')
                  .select('leccion_id, estado')
                  .eq('usuario_id', $usuario.id)
                  .in('leccion_id', leccionIds);

                const completadas = progreso?.filter((p: any) => p.estado === 'completada').length || 0;
                const total = leccionIds.length;
                const porcentaje = total > 0 ? Math.round((completadas / total) * 100) : 0;

                progresoData = { porcentaje, completadas, total };

                // Encontrar siguiente lección
                const leccionesCompletadas = new Set(progreso?.filter((p: any) => p.estado === 'completada').map((p: any) => p.leccion_id) || []);
                const todasLasLecciones = modulos.flatMap((m: any) => m.lecciones || []);
                const siguienteLeccion = todasLasLecciones.find((l: any) => !leccionesCompletadas.has(l.id));
                ultimaLeccionTitulo = siguienteLeccion?.titulo || null;
                
                console.log('📚 [DASHBOARD] Progreso curso:', contenido.titulo, `${completadas}/${total} (${porcentaje}%)`);
              }
            }
          } else {
            // Progreso de tutorial (COPIA EXACTA)
            const { data: partes } = await supabase
              .from('partes_tutorial')
              .select('id, titulo, slug, orden')
              .eq('tutorial_id', contenidoId);

            if (partes && partes.length > 0) {
              const { data: progreso } = await supabase
                .from('progreso_tutorial')
                .select('parte_tutorial_id, completado')
                .eq('usuario_id', $usuario.id)
                .eq('tutorial_id', contenidoId);

              const completadas = progreso?.filter((p: any) => p.completado).length || 0;
              const total = partes.length;
              const porcentaje = total > 0 ? Math.round((completadas / total) * 100) : 0;

              progresoData = { porcentaje, completadas, total };

              // Encontrar siguiente parte
              const partesCompletadas = new Set(progreso?.filter((p: any) => p.completado).map((p: any) => p.parte_tutorial_id) || []);
              const siguienteParte = partes.find((p: any) => !partesCompletadas.has(p.id));
              ultimaLeccionTitulo = siguienteParte?.titulo || null;
              
              console.log('🎵 [DASHBOARD] Progreso tutorial:', contenido.titulo, `${completadas}/${total} (${porcentaje}%)`);
            }
          }

          // Generar slug seguro
          const slugFinal = contenido.slug || generateSlug(contenido.titulo);
          console.log(`🔗 [DASHBOARD] Slug generado para ${contenido.titulo}: ${slugFinal}`);

          // Agregar a la lista
          const cursoParaAgregar = {
            id: contenido.id,
            titulo: contenido.titulo,
            imagen_url: contenido.imagen_url,
            slug: slugFinal, // ✅ Generar slug si no existe
            porcentaje_completado: progresoData.porcentaje,
            ultima_leccion_titulo: ultimaLeccionTitulo || (progresoData.porcentaje === 100 ? '¡Completado!' : 'Sin iniciar'),
            instructor_id: contenido.instructor_id, // ✅ Corregido a instructor_id
            categoria: contenido.categoria || null, // ✅ Puede ser null para tutoriales
            tipo: esCurso ? 'curso' : 'tutorial',
            artista: contenido.artista,
            acordeonista: contenido.acordeonista,
            completadas: progresoData.completadas,
            total: progresoData.total
          };

          cursosConProgreso.push(cursoParaAgregar);
          console.log(`✅ [DASHBOARD] Agregado ${esCurso ? 'curso' : 'tutorial'}:`, cursoParaAgregar);

        } catch (error) {
          console.error('[DASHBOARD] Error calculando progreso para:', contenido.titulo, error);
        }
      }

      // PASO 7: Generar TODAS las actividades para el slider
      if (cursosConProgreso.length > 0) {
        // Convertir cada curso/tutorial en actividad para el slider
        todasLasActividades = [];
        
        console.log('🎠 [SLIDER] Procesando', cursosConProgreso.length, 'cursos para el slider');
        console.log('🎠 [SLIDER] Cursos a procesar:', cursosConProgreso.map(c => ({ titulo: c.titulo, tipo: c.tipo, id: c.id })));
        
        for (const curso of cursosConProgreso) {
          try {
            let rutaEspecifica = null;
            let leccionTexto = curso.ultima_leccion_titulo || 'Continuar';
            let moduloTexto = curso.tipo === 'curso' ? 'Módulo actual' : null;

            if (curso.tipo === 'curso') {
              // 🎯 GENERAR RUTA ESPECÍFICA PARA CURSO
              const { data: modulos } = await supabase
                .from('modulos')
                .select('id, titulo, slug, orden, lecciones(id, titulo, slug, orden)')
                .eq('curso_id', curso.id)
                .order('orden');

              if (modulos && modulos.length > 0) {
                const todasLasLecciones = modulos.flatMap((m: any) => m.lecciones || []);
                const { data: progresoData } = await supabase
                  .from('progreso_lecciones')
                  .select('leccion_id, estado, ultima_actividad')
                  .eq('usuario_id', $usuario.id)
                  .in('leccion_id', todasLasLecciones.map((l: any) => l.id))
                  .not('ultima_actividad', 'is', null)
                  .order('ultima_actividad', { ascending: false })
                  .limit(1);

                // Encontrar próxima lección o última vista
                let leccionFinal: any = null;
                let moduloFinal: any = null;

                // Si hay progreso reciente, usar esa lección
                if (progresoData && progresoData.length > 0) {
                  const ultimoProgreso = progresoData[0];
                  leccionFinal = todasLasLecciones.find((l: any) => l.id === ultimoProgreso.leccion_id);
                  if (leccionFinal) {
                    moduloFinal = modulos.find((m: any) => m.lecciones?.some((l: any) => l.id === leccionFinal.id));
                  }
                }

                // Si no hay progreso reciente, buscar próxima lección pendiente
                if (!leccionFinal) {
                  for (const modulo of modulos) {
                    const leccionPendiente = modulo.lecciones?.find((l: any) => {
                      const progreso = progresoData?.find((p: any) => p.leccion_id === l.id);
                      return !progreso || progreso.estado !== 'completada';
                    });
                    
                    if (leccionPendiente) {
                      leccionFinal = leccionPendiente;
                      moduloFinal = modulo;
                      break;
                    }
                  }
                }

                // Generar ruta específica
                if (leccionFinal && moduloFinal) {
                  const cursoSlug = curso.slug;
                  const moduloSlug = moduloFinal.slug || generateSlug(moduloFinal.titulo);
                  const leccionSlug = leccionFinal.slug || generateSlug(leccionFinal.titulo);
                  rutaEspecifica = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
                  leccionTexto = leccionFinal.titulo;
                  moduloTexto = moduloFinal.titulo;
                }
              }

              // Fallback si no se puede generar ruta específica
              if (!rutaEspecifica) {
                rutaEspecifica = `/cursos/${curso.slug}`;
              }

            } else if (curso.tipo === 'tutorial') {
              // 🎯 GENERAR RUTA ESPECÍFICA PARA TUTORIAL
              const { data: partes } = await supabase
                .from('partes_tutorial')
                .select('id, titulo, slug, orden')
                .eq('tutorial_id', curso.id)
                .order('orden');

              if (partes && partes.length > 0) {
                const { data: progresoData } = await supabase
                  .from('progreso_tutorial')
                  .select('parte_tutorial_id, completado, ultimo_acceso')
                  .eq('usuario_id', $usuario.id)
                  .eq('tutorial_id', curso.id)
                  .not('ultimo_acceso', 'is', null)
                  .order('ultimo_acceso', { ascending: false })
                  .limit(1);

                // Encontrar próxima clase o última vista
                let claseFinal: any = null;

                // Si hay progreso reciente, usar esa clase
                if (progresoData && progresoData.length > 0) {
                  const ultimoProgreso = progresoData[0];
                  claseFinal = partes.find((p: any) => p.id === ultimoProgreso.parte_tutorial_id);
                }

                // Si no hay progreso reciente, buscar próxima clase pendiente
                if (!claseFinal) {
                  claseFinal = partes.find((p: any) => {
                    const progreso = progresoData?.find((pr: any) => pr.parte_tutorial_id === p.id);
                    return !progreso || !progreso.completado;
                  });
                }

                // Generar ruta específica
                if (claseFinal) {
                  const tutorialSlug = curso.slug;
                  const claseSlug = claseFinal.slug || generateSlug(claseFinal.titulo);
                  rutaEspecifica = `/tutoriales/${tutorialSlug}/clase/${claseSlug}`;
                  leccionTexto = claseFinal.titulo;
                }
              }

              // Fallback si no se puede generar ruta específica
              if (!rutaEspecifica) {
                rutaEspecifica = `/tutoriales/${curso.slug}`;
              }
            }

            // Agregar actividad al slider
            todasLasActividades.push({
              id: curso.id,
              tipo: curso.tipo,
              titulo: curso.titulo,
              leccion: leccionTexto,
              modulo: moduloTexto,
              artista: curso.artista,
              acordeonista: curso.acordeonista,
              imagen: curso.imagen_url,
              progreso: curso.porcentaje_completado,
              totalLecciones: curso.total,
              leccionesCompletadas: curso.completadas,
              totalClases: curso.total,
              clasesCompletadas: curso.completadas,
              ruta: rutaEspecifica,
              ultimaActividad: new Date(inscripcionesData[0].created_at)
            });

            console.log(`🎯 [SLIDER] ${curso.tipo} procesado:`, {
              titulo: curso.titulo,
              leccion: leccionTexto,
              ruta: rutaEspecifica
            });

          } catch (error) {
            console.error(`❌ [SLIDER] Error procesando ${curso.tipo}:`, curso.titulo, error);
            
            // Fallback básico en caso de error
            const rutaBase = curso.tipo === 'tutorial' ? '/tutoriales' : '/cursos';
            todasLasActividades.push({
              id: curso.id,
              tipo: curso.tipo,
              titulo: curso.titulo,
              leccion: curso.ultima_leccion_titulo || 'Continuar',
              modulo: curso.tipo === 'curso' ? 'Módulo actual' : null,
              artista: curso.artista,
              acordeonista: curso.acordeonista,
              imagen: curso.imagen_url,
              progreso: curso.porcentaje_completado,
              totalLecciones: curso.total,
              leccionesCompletadas: curso.completadas,
              totalClases: curso.total,
              clasesCompletadas: curso.completadas,
              ruta: `${rutaBase}/${curso.slug}`,
              ultimaActividad: new Date(inscripcionesData[0].created_at)
            });
          }
        }

        // Establecer la primera como actividad actual
        actividadActual = 0;
        ultimaActividad = todasLasActividades[0];

        console.log('✅ [DASHBOARD] Todas las actividades procesadas:', todasLasActividades.length);
        console.log('🎯 [DASHBOARD] Lista completa de actividades:', todasLasActividades);
        console.log('🎯 [DASHBOARD] Actividad inicial:', ultimaActividad);
      } else {
        console.log('⚠️ [DASHBOARD] No se procesó ningún curso con progreso');
        todasLasActividades = [];
        ultimaActividad = null;
      }

    } catch (error) {
      console.error('❌ [DASHBOARD] Error cargando última actividad:', error);
      error = 'Error al cargar la información';
    } finally {
      cargando = false;
      console.log('🏁 [DASHBOARD] Carga finalizada. Última actividad:', ultimaActividad);
    }
  }

  // 🚀 Continuar aprendizaje
  function continuarAprendizaje() {
    if (ultimaActividad?.ruta) {
      console.log('🎯 [NAVEGACIÓN] Navegando a:', ultimaActividad.ruta);
      console.log('🎯 [NAVEGACIÓN] Actividad completa:', ultimaActividad);
      goto(ultimaActividad.ruta);
    } else {
      console.error('❌ [NAVEGACIÓN] No hay ruta disponible para:', ultimaActividad);
    }
  }

  // 🎠 Funciones de navegación del slider
  function anteriorActividad() {
    pausarAutoPlay();
    isChanging = true;
    setTimeout(() => {
      if (actividadActual > 0) {
        actividadActual--;
        ultimaActividad = todasLasActividades[actividadActual];
      }
      setTimeout(() => {
        isChanging = false;
      }, 300);
    }, 100);
    reanudarAutoPlayDespuesDe(10000); // Más tiempo después de interacción manual
  }

  function siguienteActividad() {
    pausarAutoPlay();
    isChanging = true;
    setTimeout(() => {
      if (actividadActual < todasLasActividades.length - 1) {
        actividadActual++;
        ultimaActividad = todasLasActividades[actividadActual];
      } else {
        // Si está en el último, volver al primero
        actividadActual = 0;
        ultimaActividad = todasLasActividades[actividadActual];
      }
      setTimeout(() => {
        isChanging = false;
      }, 300);
    }, 100);
    reanudarAutoPlayDespuesDe(10000); // Más tiempo después de interacción manual
  }

  function irAActividad(index: number) {
    pausarAutoPlay();
    isChanging = true;
    setTimeout(() => {
      actividadActual = index;
      ultimaActividad = todasLasActividades[actividadActual];
      setTimeout(() => {
        isChanging = false;
      }, 300);
    }, 100);
    reanudarAutoPlayDespuesDe(10000); // Más tiempo después de interacción manual
  }

  // 🔄 CONTROL ESTRICTO DE AUTO-PLAY (SIN DUPLICACIONES)
  function iniciarAutoPlay() {
    // 🚨 SIEMPRE limpiar cualquier interval previo
    if (autoPlayInterval) {
      clearInterval(autoPlayInterval);
      autoPlayInterval = null;
    }
    
    // ✅ Solo crear nuevo interval si hay múltiples actividades y no está pausado
    if (todasLasActividades.length > 1 && !isPaused) {
      console.log('🔄 [AUTO-PLAY] Iniciando nuevo interval');
      autoPlayInterval = setInterval(() => {
        siguienteActividadAuto();
      }, 15000); // Cambiar cada 15 segundos
    }
  }

  function siguienteActividadAuto() {
    // 🛡️ Verificar que el auto-play sigue activo
    if (isPaused || !autoPlayInterval) {
      console.log('🛑 [AUTO-PLAY] Cancelado - pausado o sin interval');
      return;
    }
    
    console.log('🎯 [AUTO-PLAY] Cambiando slide automáticamente');
    isChanging = true;
    setTimeout(() => {
      if (actividadActual < todasLasActividades.length - 1) {
        actividadActual++;
      } else {
        actividadActual = 0; // Volver al primero
      }
      ultimaActividad = todasLasActividades[actividadActual];
      setTimeout(() => {
        isChanging = false;
      }, 300);
    }, 150);
  }

  function pausarAutoPlay() {
    console.log('⏸️ [AUTO-PLAY] Pausando...');
    isPaused = true;
    if (autoPlayInterval) {
      clearInterval(autoPlayInterval);
      autoPlayInterval = null;
    }
  }

  function reanudarAutoPlay() {
    console.log('▶️ [AUTO-PLAY] Reanudando...');
    isPaused = false;
    iniciarAutoPlay(); // iniciarAutoPlay ya limpia intervals previos
  }

  function reanudarAutoPlayDespuesDe(ms: number) {
    console.log(`⏰ [AUTO-PLAY] Programado para reanudar en ${ms}ms`);
    setTimeout(() => {
      reanudarAutoPlay();
    }, ms);
  }

  // 🎨 Formatear fecha de última actividad
  function formatearUltimaActividad(fecha: Date): string {
    const ahora = new Date();
    const diferencia = ahora.getTime() - fecha.getTime();
    const horas = Math.floor(diferencia / (1000 * 60 * 60));
    const dias = Math.floor(horas / 24);
    
    if (horas < 1) return 'Hace menos de una hora';
    if (horas < 24) return `Hace ${horas} hora${horas > 1 ? 's' : ''}`;
    if (dias < 7) return `Hace ${dias} día${dias > 1 ? 's' : ''}`;
    return fecha.toLocaleDateString('es-ES', { day: 'numeric', month: 'long' });
  }

  onMount(() => {
    cargarUltimaActividad();
  });

  // 🔄 INICIAR AUTO-PLAY SOLO UNA VEZ AL CARGAR DATOS
  $: if (todasLasActividades.length > 1 && !autoPlayInterval && !isPaused) {
    console.log('📊 [AUTO-PLAY] Datos cargados, programando inicio...');
    setTimeout(() => {
      // 🛡️ Verificar nuevamente antes de iniciar
      if (!autoPlayInterval && !isPaused) {
        iniciarAutoPlay();
      }
    }, 8000); // Esperar 8 segundos antes de iniciar
  }

  onDestroy(() => {
    if (autoPlayInterval) {
      clearInterval(autoPlayInterval);
    }
  });
</script>

<!-- 🎵 CONTINUAR APRENDIENDO - HERO PRINCIPAL -->
<section class="continuar-aprendiendo">
  
  {#if cargando}
    <!-- Estado de carga -->
    <div class="hero-loading">
      <div class="skeleton-hero"></div>
    </div>
    
  {:else if ultimaActividad && todasLasActividades.length > 0}
    <!-- 🎠 SLIDER DE ACTIVIDADES -->
    <div 
      class="slider-container"
      on:mouseenter={pausarAutoPlay}
      on:mouseleave={reanudarAutoPlay}
    >
      
      <!-- Header del slider con navegación -->
      <div class="slider-header">
        <div class="usuario-info">
          <img 
            src={$usuario?.url_foto_perfil || '/images/perfil-portada/default-avatar.png'} 
            alt="Foto de perfil"
            class="avatar-usuario"
            on:click={() => goto('/perfil')}
            role="button"
            tabindex="0"
          />
          <div class="saludo-usuario">
            <span class="saludo">¡Hola {$usuario?.nombre || 'Estudiante'}!</span>
            <span class="submensaje">Continúa aprendiendo 🎵</span>
          </div>
        </div>
        
        {#if todasLasActividades.length > 1}
          <div class="navegacion-externa">
            <button 
              class="nav-btn-external nav-prev" 
              on:click={anteriorActividad} 
              disabled={actividadActual === 0}
              aria-label="Actividad anterior"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M15 18l-6-6 6-6"/>
              </svg>
            </button>
            
            <span class="contador-externo">
              {actividadActual + 1} / {todasLasActividades.length}
              {#if !isPaused && todasLasActividades.length > 1}
                <span class="auto-indicator active">●</span>
              {:else if isPaused && todasLasActividades.length > 1}
                <span class="auto-indicator paused">⏸</span>
              {/if}
            </span>
            
            <button 
              class="nav-btn-external nav-next" 
              on:click={siguienteActividad} 
              disabled={actividadActual === todasLasActividades.length - 1}
              aria-label="Siguiente actividad"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M9 18l6-6-6-6"/>
              </svg>
            </button>
          </div>
        {/if}
      </div>

      <!-- Contenido del slide actual CON transición CSS suave -->
      {#key actividadActual}
        <div class="hero-actividad slide-content" class:changing={isChanging}>
          <div class="contenido-izquierdo">
            <div class="etiqueta-continuar">
              <span class="icono">{ultimaActividad.tipo === 'curso' ? '📚' : '🎵'}</span>
              <span>Continuar Aprendiendo</span>
            </div>
          
          <h2 class="titulo-principal">{ultimaActividad.titulo}</h2>
          
          <div class="info-actividad">
            {#if ultimaActividad.tipo === 'curso'}
              <p class="descripcion">
                <span class="modulo">📖 {ultimaActividad.modulo}</span>
                <span class="separador">•</span>
                <span class="leccion">🎯 {ultimaActividad.leccion}</span>
              </p>
            {:else}
              <p class="descripcion">
                <span class="artista">🎵 {ultimaActividad.artista}</span>
                <span class="separador">•</span>
                <span class="leccion">🎯 {ultimaActividad.leccion}</span>
              </p>
            {/if}
            
            <div class="estadisticas">
              <div class="stat">
                <span class="valor">{ultimaActividad.progreso}%</span>
                <span class="label">completado</span>
              </div>
              <div class="stat">
                <span class="valor">{ultimaActividad.tipo === 'curso' ? ultimaActividad.leccionesCompletadas : ultimaActividad.clasesCompletadas}</span>
                <span class="label">de {ultimaActividad.tipo === 'curso' ? ultimaActividad.totalLecciones : ultimaActividad.totalClases} {ultimaActividad.tipo === 'curso' ? 'lecciones' : 'clases'}</span>
              </div>
            </div>
            
            <div class="progreso-visual">
              <div class="barra-progreso">
                <div class="progreso-fill" style="width: {ultimaActividad.progreso}%"></div>
              </div>
              <span class="progreso-texto">{ultimaActividad.progreso}% completado</span>
            </div>
            
            <p class="ultima-sesion">
              Última actividad: {formatearUltimaActividad(ultimaActividad.ultimaActividad)}
            </p>
          </div>
          
          <button class="boton-continuar" on:click={continuarAprendizaje}>
            <span class="icono-play">▶️</span>
            <span>Continuar {ultimaActividad.tipo === 'curso' ? 'Lección' : 'Clase'}</span>
            <svg class="icono-flecha" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
          </button>
        </div>
        
        <div class="contenido-derecho">
          <div class="imagen-contenedor">
            <img 
              src={ultimaActividad.imagen || '/images/Home/academia-vallenata-1.jpg'} 
              alt={ultimaActividad.titulo}
              class="imagen-curso"
            />
            <div class="overlay-progreso">
              <div class="progreso-circular">
                <div class="circular-chart">
                  <svg viewBox="0 0 36 36" class="circular-chart-svg">
                    <path class="circle-bg"
                      d="M18 2.0845
                        a 15.9155 15.9155 0 0 1 0 31.831
                        a 15.9155 15.9155 0 0 1 0 -31.831"
                    />
                    <path class="circle"
                      stroke-dasharray="{ultimaActividad.progreso}, 100"
                      d="M18 2.0845
                        a 15.9155 15.9155 0 0 1 0 31.831
                        a 15.9155 15.9155 0 0 1 0 -31.831"
                    />
                  </svg>
                  <div class="percentage">{ultimaActividad.progreso}%</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      {/key}

      <!-- Indicadores de slides -->
      {#if todasLasActividades.length > 1}
        <div class="slider-indicators">
          {#each todasLasActividades as actividad, index}
            <button 
              class="indicator {index === actividadActual ? 'active' : ''}"
              on:click={() => irAActividad(index)}
              aria-label="Ir a {actividad.titulo}"
            >
              <span class="tipo-indicator">{actividad.tipo === 'curso' ? '📚' : '🎵'}</span>
            </button>
          {/each}
        </div>
      {/if}

    </div>
    
  {:else}
    <!-- Sin actividad reciente -->
    <div class="hero-sin-actividad">
      <div class="contenido-vacio">
        <div class="icono-vacio">🎵</div>
        <h2>¡Comienza tu viaje musical!</h2>
        <p>Inscríbete en un curso o tutorial para empezar a aprender acordeón</p>
        <div class="botones-accion">
          <button class="boton-principal" on:click={() => goto('/cursos')}>
            📚 Explorar Cursos
          </button>
          <button class="boton-secundario" on:click={() => goto('/tutoriales')}>
            🎵 Ver Tutoriales
          </button>
        </div>
      </div>
    </div>
  {/if}
  
</section>

<style>
  /* 🎵 CONTINUAR APRENDIENDO - ESTILO PLATZI */
  .continuar-aprendiendo {
    margin-bottom: 32px;
  }

  /* 🎠 SLIDER CONTAINER */
  .slider-container {
    position: relative;
    width: 100%;
  }

  /* 📱 HEADER DEL SLIDER */
  .slider-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding: 0 20px;
  }

  .usuario-info {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .avatar-usuario {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    border: 3px solid rgba(255, 255, 255, 0.3);
    cursor: pointer;
    transition: all 0.3s ease;
    object-fit: cover;
  }

  .avatar-usuario:hover {
    border-color: rgba(255, 255, 255, 0.7);
    transform: scale(1.05);
    box-shadow: 0 4px 20px rgba(255, 255, 255, 0.2);
  }

  .saludo-usuario {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .saludo {
    color: white;
    font-size: 1.1rem;
    font-weight: 600;
  }

  .submensaje {
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.9rem;
  }

  .navegacion-externa {
    display: flex;
    align-items: center;
    gap: 16px;
  }

  .nav-btn-external {
    width: 40px;
    height: 40px;
    background: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(20px);
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .nav-btn-external:hover {
    background: rgba(255, 255, 255, 0.25);
    border-color: rgba(255, 255, 255, 0.5);
    transform: scale(1.1);
  }

  .nav-btn-external:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: scale(0.9);
  }

  .nav-btn-external svg {
    width: 20px;
    height: 20px;
  }

  .contador-externo {
    color: white;
    font-weight: 600;
    font-size: 1rem;
    min-width: 50px;
    text-align: center;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
  }

  .auto-indicator {
    font-size: 0.8rem;
    transition: all 0.3s ease;
  }

  .auto-indicator.active {
    color: #10b981;
    animation: autoPlayPulse 3s infinite;
  }

  .auto-indicator.paused {
    color: #f59e0b;
    opacity: 0.8;
  }

  @keyframes autoPlayPulse {
    0%, 100% {
      opacity: 1;
      transform: scale(1);
    }
    50% {
      opacity: 0.6;
      transform: scale(0.9);
    }
  }

  /* ✨ TRANSICIONES CSS MUY SUTILES - NO SVELTE */
  .slide-content {
    /* Sin transiciones globales que afecten layout */
  }

  .slider-container {
    /* Contenedor estable sin animaciones */
    position: relative;
  }

  /* 🎯 TRANSICIONES MUY SUTILES CONTROLADAS */
  .hero-actividad {
    opacity: 1;
    transition: opacity 0.2s ease-in-out;
  }

  .hero-actividad.changing {
    opacity: 0.85;
  }

  /* 🎭 SOLO elementos específicos con transición mínima */
  .titulo-principal,
  .descripcion,
  .imagen-curso {
    transition: opacity 0.15s ease;
  }

  .hero-actividad.changing .titulo-principal,
  .hero-actividad.changing .descripcion,
  .hero-actividad.changing .imagen-curso {
    opacity: 0.7;
  }

  /* 🔄 Indicador muy sutil */
  .slider-container:hover .indicator.active {
    opacity: 0.9;
    transition: opacity 0.3s ease;
  }

  /* 🔄 Loading skeleton */
  .hero-loading {
    padding: 40px;
    background: rgba(99, 102, 241, 0.1);
    border-radius: 20px;
    border: 1px solid rgba(99, 102, 241, 0.2);
  }

  .skeleton-hero {
    height: 200px;
    background: linear-gradient(90deg, 
      rgba(99, 102, 241, 0.1) 0%, 
      rgba(99, 102, 241, 0.2) 50%, 
      rgba(99, 102, 241, 0.1) 100%);
    background-size: 200% 100%;
    animation: skeleton-loading 1.5s ease-in-out infinite;
    border-radius: 12px;
  }

  @keyframes skeleton-loading {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }

  /* 🎯 Hero con actividad */
  .hero-actividad {
    display: grid;
    grid-template-columns: 1fr 300px;
    gap: 40px;
    padding: 40px;
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 50%, #d946ef 100%);
    border-radius: 20px;
    color: white;
    position: relative;
    overflow: hidden;
  }

  .hero-actividad::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.1);
    backdrop-filter: blur(1px);
  }

  .contenido-izquierdo, .contenido-derecho {
    position: relative;
    z-index: 2;
  }

  .etiqueta-continuar {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: rgba(255, 255, 255, 0.2);
    padding: 8px 16px;
    border-radius: 20px;
    font-size: 0.9rem;
    font-weight: 500;
    margin-bottom: 16px;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  .titulo-principal {
    font-size: 2.2rem;
    font-weight: bold;
    margin: 0 0 16px 0;
    line-height: 1.2;
  }

  .info-actividad {
    margin-bottom: 24px;
  }

  .descripcion {
    font-size: 1.1rem;
    margin: 0 0 16px 0;
    opacity: 0.9;
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
  }

  .separador {
    opacity: 0.6;
  }

  .estadisticas {
    display: flex;
    gap: 24px;
    margin-bottom: 20px;
  }

  .stat {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .stat .valor {
    font-size: 1.4rem;
    font-weight: bold;
  }

  .stat .label {
    font-size: 0.85rem;
    opacity: 0.8;
  }

  .progreso-visual {
    margin-bottom: 16px;
  }

  .barra-progreso {
    width: 100%;
    height: 8px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: 8px;
  }

  .progreso-fill {
    height: 100%;
    background: linear-gradient(90deg, #10b981, #34d399);
    border-radius: 4px;
    transition: width 0.8s ease;
  }

  .progreso-texto {
    font-size: 0.9rem;
    opacity: 0.9;
  }

  .ultima-sesion {
    font-size: 0.9rem;
    opacity: 0.8;
    margin: 0;
  }

  .boton-continuar {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    background: rgba(255, 255, 255, 0.15);
    backdrop-filter: blur(20px);
    border: 2px solid rgba(255, 255, 255, 0.3);
    color: white;
    padding: 16px 24px;
    border-radius: 12px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .boton-continuar:hover {
    background: rgba(255, 255, 255, 0.25);
    border-color: rgba(255, 255, 255, 0.5);
    transform: translateY(-2px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
  }

  .icono-flecha {
    width: 20px;
    height: 20px;
  }

  /* 🖼️ Imagen y progreso circular */
  .contenido-derecho {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .imagen-contenedor {
    position: relative;
    width: 250px;
    height: 200px;
    border-radius: 16px;
    overflow: hidden;
  }

  .imagen-curso {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .overlay-progreso {
    position: absolute;
    top: 12px;
    right: 12px;
  }

  .progreso-circular {
    width: 60px;
    height: 60px;
  }

  .circular-chart-svg {
    width: 100%;
    height: 100%;
    transform: rotate(-90deg);
  }

  .circle-bg {
    fill: none;
    stroke: rgba(255, 255, 255, 0.2);
    stroke-width: 2;
  }

  .circle {
    fill: none;
    stroke: #10b981;
    stroke-width: 3;
    stroke-linecap: round;
    transition: stroke-dasharray 0.8s ease;
  }

  .percentage {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    font-size: 0.8rem;
    font-weight: bold;
    color: white;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  }

  /* 🌟 Sin actividad */
  .hero-sin-actividad {
    padding: 60px 40px;
    background: rgba(100, 116, 139, 0.1);
    border-radius: 20px;
    border: 2px dashed rgba(100, 116, 139, 0.3);
    text-align: center;
  }

  .contenido-vacio {
    max-width: 400px;
    margin: 0 auto;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 16px;
  }

  .contenido-vacio h2 {
    font-size: 1.8rem;
    margin: 0 0 12px 0;
    color: white;
  }

  .contenido-vacio p {
    color: #94a3b8;
    margin: 0 0 24px 0;
    font-size: 1.1rem;
  }

  .botones-accion {
    display: flex;
    gap: 16px;
    justify-content: center;
    flex-wrap: wrap;
  }

  .boton-principal, .boton-secundario {
    padding: 12px 24px;
    border-radius: 10px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    border: none;
  }

  .boton-principal {
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    color: white;
  }

  .boton-secundario {
    background: transparent;
    color: #6366f1;
    border: 2px solid #6366f1;
  }

  .boton-principal:hover, .boton-secundario:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(99, 102, 241, 0.3);
  }

  /* 📱 Responsive */
  @media (max-width: 900px) {
    .hero-actividad {
      grid-template-columns: 1fr;
      gap: 24px;
      padding: 24px;
    }

    .titulo-principal {
      font-size: 1.8rem;
    }

    .estadisticas {
      gap: 16px;
    }

    .imagen-contenedor {
      width: 200px;
      height: 150px;
      margin: 0 auto;
    }

    .botones-accion {
      flex-direction: column;
      align-items: center;
    }

    .boton-principal, .boton-secundario {
      width: 100%;
      max-width: 250px;
    }

    /* 🎠 Slider móvil */
    .slider-header {
      padding: 0 10px;
      margin-bottom: 15px;
    }

    .usuario-info {
      gap: 8px;
    }

    .avatar-usuario {
      width: 40px;
      height: 40px;
    }

    .saludo {
      font-size: 1rem;
    }

    .submensaje {
      font-size: 0.8rem;
    }

    .navegacion-externa {
      gap: 12px;
    }

    .nav-btn-external {
      width: 35px;
      height: 35px;
    }

    .nav-btn-external svg {
      width: 18px;
      height: 18px;
    }

    .contador-externo {
      font-size: 0.9rem;
      min-width: 40px;
      gap: 6px;
    }

    .auto-indicator {
      font-size: 0.7rem;
    }

    .auto-indicator.paused {
      font-size: 0.6rem;
    }

    .slider-indicators {
      gap: 8px;
      margin-top: 15px;
    }

    .indicator {
      width: 40px;
      height: 40px;
    }

    .tipo-indicator {
      font-size: 1rem;
    }
  }



  /* 📍 INDICADORES DEL SLIDER */
  .slider-indicators {
    display: flex;
    justify-content: center;
    gap: 12px;
    margin-top: 20px;
    padding: 0 20px;
  }

  .indicator {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    border: 2px solid rgba(255, 255, 255, 0.3);
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    backdrop-filter: blur(10px);
  }

  .indicator:hover {
    background: rgba(255, 255, 255, 0.2);
    border-color: rgba(255, 255, 255, 0.5);
    transform: scale(1.1);
  }

  .indicator.active {
    background: rgba(255, 255, 255, 0.3);
    border-color: rgba(255, 255, 255, 0.7);
    transform: scale(1.15);
    box-shadow: 0 4px 20px rgba(255, 255, 255, 0.2);
  }

  .tipo-indicator {
    font-size: 1.2rem;
  }

  .contador {
    opacity: 0.8;
    font-size: 0.85rem;
    margin-left: 8px;
  }
</style> 