<script lang="ts">
  import { onMount } from 'svelte';
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { perfilStore } from '$lib/stores/perfilStore';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { goto } from '$app/navigation';
  import { generateSlug } from '$lib/utilidades/utilidadesSlug';
  import TarjetaEstadistica from '$lib/components/DashboardEstudiante/TarjetaEstadistica.svelte';
  import ProgresCircular from '$lib/components/DashboardEstudiante/ProgresCircular.svelte';
  import TarjetaCursoProgreso from '$lib/components/DashboardEstudiante/TarjetaCursoProgreso.svelte';
  import Avatar from '$lib/components/ui/Avatar.svelte';

  // Estados del dashboard
  let cargandoDatos = true;
  let estadisticasEstudiante = {
    cursosInscritos: 0,
    cursosCompletados: 0,
    horasAprendizaje: 0,
    certificadosObtenidos: 0,
    rachaEstudio: 0,
    progresoGeneral: 0
  };
  let cursosEnProgreso: any[] = [];
  let actividadReciente: any[] = [];
  let metasSemanales = {
    horasObjetivo: 10,
    horasCompletadas: 6.5,
    diasEstudio: 4,
    porcentajeCompletado: 65
  };
  let datosGamificacion = {
    xpTotal: 0,
    nivel: 1,
    posicionRanking: null,
    puntuacionTotal: 0,
    logrosObtenidos: 0
  };

  // Saludo dinámico basado en la hora
  function obtenerSaludoDinamico(): string {
    const hora = new Date().getHours();
    const nombre = $usuario?.nombre || 'Estudiante';
    
    if (hora < 12) return `¡Buenos días, ${nombre}! ☀️`;
    if (hora < 18) return `¡Buenas tardes, ${nombre}! 🌅`;
    return `¡Buenas noches, ${nombre}! 🌙`;
  }

  // ===== LÓGICA EXACTA DE "MIS CURSOS" (100% FUNCIONAL) =====
  async function cargarEstadisticasEstudiante() {
    if (!$usuario?.id) {
      console.log('❌ No hay usuario logueado');
      cargandoDatos = false;
      return;
    }

    try {
      cargandoDatos = true;
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
        cargandoDatos = false;
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
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, slug, instructor, categoria')
          .in('id', cursoIds);
          
        if (cursosError) {
          console.error('❌ Error obteniendo cursos:', cursosError);
        } else {
          cursosData = cursos || [];
          console.log('✅ [DASHBOARD] Cursos cargados:', cursosData.length);
        }
      }

      // PASO 4: Obtener datos de TUTORIALES (IGUAL que en Mis Cursos)
      let tutorialesData = [];
      if (inscripcionesTutoriales.length > 0) {
        const tutorialIds = inscripcionesTutoriales.map((i: any) => i.tutorial_id);
        console.log('🎵 [DASHBOARD] Buscando tutoriales:', tutorialIds);
        
        const { data: tutoriales, error: tutorialesError } = await supabase
          .from('tutoriales')
          .select('id, titulo, descripcion, imagen_url, nivel, duracion_estimada, precio_normal, artista, acordeonista, tonalidad, slug, instructor, categoria')
          .in('id', tutorialIds);
          
        if (tutorialesError) {
          console.error('❌ Error obteniendo tutoriales:', tutorialesError);
        } else {
          tutorialesData = tutoriales || [];
          console.log('✅ [DASHBOARD] Tutoriales cargados:', tutorialesData.length);
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

      // PASO 6: Estadísticas básicas
      const cursosInscritos = inscripcionesData.length;
      const cursosCompletados = inscripcionesData.filter((i: any) => i.completado).length;

        // Obtener estadísticas de gamificación si existen
        let xpTotal = 0, nivelActual = 1, rachaMaxima = 0;
        try {
          const { data: experiencia } = await supabase
            .from('experiencia_usuario')
            .select('*')
            .eq('usuario_id', $usuario.id)
            .single();
          
          if (experiencia) {
            xpTotal = experiencia.xp_total;
            nivelActual = experiencia.nivel;
            rachaMaxima = experiencia.racha_maxima;
            console.log('🎮 Datos de gamificación encontrados:', { xpTotal, nivelActual, rachaMaxima });
          }
        } catch (err) {
          console.log('⚠️ No se encontraron datos de gamificación, usando valores por defecto');
        }

        // PASO 7: Calcular progreso REAL usando LÓGICA EXACTA de TarjetaCurso.svelte
        const cursosConProgreso = [];
        
        console.log('🎯 [DASHBOARD] Calculando progreso para', inscripcionesCombinadas.length, 'inscripciones');
        
        for (const inscripcionCompleta of inscripcionesCombinadas.slice(0, 8)) { // Mostrar hasta 8
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

            // Agregar a la lista
            cursosConProgreso.push({
              id: contenido.id,
              titulo: contenido.titulo,
              imagen_url: contenido.imagen_url,
              slug: contenido.slug,
              porcentaje_completado: progresoData.porcentaje,
              ultima_leccion_titulo: ultimaLeccionTitulo || (progresoData.porcentaje === 100 ? '¡Completado!' : 'Sin iniciar'),
              instructor: contenido.instructor,
              categoria: contenido.categoria,
              tipo: esCurso ? 'curso' : 'tutorial',
              tiempo_estimado: calcularTiempoEstimado(progresoData.total - progresoData.completadas),
              completadas: progresoData.completadas,
              total: progresoData.total
            });

          } catch (error) {
            console.error('[DASHBOARD] Error calculando progreso para:', contenido.titulo, error);
          }
        }

        // PASO 8: Calcular progreso general
        let progresoTotalReal = 0;
        if (cursosConProgreso.length > 0) {
          const promedioProgreso = cursosConProgreso.reduce((sum, curso) => sum + curso.porcentaje_completado, 0) / cursosConProgreso.length;
          progresoTotalReal = Math.round(promedioProgreso);
        }

        // PASO 9: Usar datos de gamificación ya obtenidos
        try {
          const { data: experiencia } = await supabase
            .from('experiencia_usuario')
            .select('*')
            .eq('usuario_id', $usuario.id)
            .single();

          if (experiencia) {
            xpTotal = experiencia.xp_total;
            rachaMaxima = experiencia.racha_maxima;
            console.log('🎮 [DASHBOARD] Gamificación obtenida:', { xpTotal, rachaMaxima });
          }
        } catch (err) {
          console.log('⚠️ [DASHBOARD] No se encontraron datos de gamificación');
        }

        // PASO 10: Calcular tiempo de aprendizaje
        const { data: tiempoAprendizaje } = await supabase
          .from('progreso_lecciones')
          .select('tiempo_total')
          .eq('usuario_id', $usuario.id);

        const horasAprendizaje = tiempoAprendizaje 
          ? Math.round(tiempoAprendizaje.reduce((total: number, p: any) => total + (p.tiempo_total || 0), 0) / 3600)
          : 0;

        // PASO 11: Actualizar estados finales
        estadisticasEstudiante = {
          cursosInscritos,
          cursosCompletados,
          horasAprendizaje,
          certificadosObtenidos: cursosCompletados,
          rachaEstudio: rachaMaxima || 0,
          progresoGeneral: progresoTotalReal
        };

        cursosEnProgreso = cursosConProgreso;

        console.log('✅ [DASHBOARD] Estadísticas FINALES:', estadisticasEstudiante);
        console.log('🎵 [DASHBOARD] Cursos en progreso:', cursosEnProgreso.length);

    } catch (error) {
      console.error('❌ [DASHBOARD] Error cargando datos:', error);
    } finally {
      cargandoDatos = false;
    }
  }

  // Función auxiliar para calcular tiempo estimado
  function calcularTiempoEstimado(leccionesPendientes: number): string {
    const minutosPromedioPorLeccion = 15; // 15 minutos promedio por lección
    const totalMinutos = leccionesPendientes * minutosPromedioPorLeccion;
    
    if (totalMinutos < 60) {
      return `${totalMinutos} min restantes`;
    } else {
      const horas = Math.round(totalMinutos / 60 * 10) / 10;
      return `${horas}h restantes`;
    }
  }

  // Variable para almacenar la información de la última clase vista
  let ultimaClaseVista: any = null;

      // Función usando EXACTAMENTE la misma lógica que [slug] y /contenido
  async function obtenerUltimaClaseVista() {
    if (!$usuario?.id) return null;

    try {
      console.log('🔍 [DASHBOARD] Obteniendo inscripciones para usuario:', $usuario.id);

      // PASO 1: Obtener TODAS las inscripciones activas (no solo con ultima_actividad)
      const { data: inscripciones, error: errorInscripcion } = await supabase
        .from('inscripciones')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .order('created_at', { ascending: false })
        .limit(10); // Obtener más para encontrar la mejor con progreso real

              if (errorInscripcion || !inscripciones || inscripciones.length === 0) {
          console.warn('⚠️ [DASHBOARD] No hay inscripciones activas:', errorInscripcion);
          return null;
        }

              console.log('📋 [DASHBOARD] Inscripciones encontradas:', inscripciones.length);

        // PASO 2: Evaluar cuál inscripción tiene actividad más reciente y procesarla
        let mejorInscripcion = null;
        let fechaMasReciente = null;

        // Primero evaluar todas para encontrar la con progreso más reciente
        for (const inscripcion of inscripciones) {
          const esCurso = !!inscripcion.curso_id;
          const esTutorial = !!inscripcion.tutorial_id;

          if (esCurso) {
            // Verificar actividad reciente en cursos
            const { data: actividadCurso } = await supabase
              .from('progreso_lecciones')
              .select('ultima_actividad')
              .eq('usuario_id', $usuario.id)
              .not('ultima_actividad', 'is', null)
              .order('ultima_actividad', { ascending: false })
              .limit(1);
            
            if (actividadCurso && actividadCurso.length > 0) {
              const fechaActividad = new Date(actividadCurso[0].ultima_actividad);
              if (!fechaMasReciente || fechaActividad > fechaMasReciente) {
                fechaMasReciente = fechaActividad;
                mejorInscripcion = inscripcion;
              }
            }
          } else if (esTutorial) {
            // Verificar actividad reciente en tutoriales
            const { data: actividadTutorial } = await supabase
              .from('progreso_tutorial')
              .select('ultimo_acceso')
              .eq('usuario_id', $usuario.id)
              .eq('tutorial_id', inscripcion.tutorial_id)
              .not('ultimo_acceso', 'is', null)
              .order('ultimo_acceso', { ascending: false })
              .limit(1);
            
            if (actividadTutorial && actividadTutorial.length > 0) {
              const fechaActividad = new Date(actividadTutorial[0].ultimo_acceso);
              if (!fechaMasReciente || fechaActividad > fechaMasReciente) {
                fechaMasReciente = fechaActividad;
                mejorInscripcion = inscripcion;
              }
            }
          }
        }

        // Si no encontramos ninguna con actividad reciente, usar la primera
        if (!mejorInscripcion && inscripciones.length > 0) {
          mejorInscripcion = inscripciones[0];
          console.log('📋 [DASHBOARD] No hay actividad reciente, usando primera inscripción');
        }

        // PASO 3: Procesar la mejor inscripción encontrada
        if (mejorInscripcion) {
          console.log('🎯 [DASHBOARD] Procesando inscripción con mayor actividad:', mejorInscripcion.id, fechaMasReciente);
          const inscripcion = mejorInscripcion;
        const esCurso = !!inscripcion.curso_id;
        const esTutorial = !!inscripcion.tutorial_id;

        if (esCurso) {
          console.log('📚 [DASHBOARD] Procesando curso:', inscripcion.curso_id);
          
          // Usar el MISMO SERVICIO que usa [slug]
          const { data: cursoData } = await supabase
            .from('cursos')
            .select('id, titulo, slug, imagen_url, instructor_id')
            .eq('id', inscripcion.curso_id)
            .single();

          if (!cursoData) {
            console.log('⚠️ [DASHBOARD] No se pudo cargar el curso');
            return null;
          }

          // Cargar módulos y lecciones (IGUAL que [slug])
          const { data: modulos } = await supabase
            .from('modulos')
            .select('id, titulo, slug, orden, lecciones(id, titulo, slug, orden)')
            .eq('curso_id', cursoData.id)
            .order('orden');

          if (!modulos || modulos.length === 0) {
            console.log('⚠️ [DASHBOARD] No se encontraron módulos para el curso');
            return null;
          }

          // Obtener progreso (IGUAL que [slug])
          const todasLasLecciones = modulos.flatMap((m: any) => m.lecciones || []);
          if (todasLasLecciones.length === 0) {
            console.log('⚠️ [DASHBOARD] No se encontraron lecciones en los módulos');
            return null;
          }

          const leccionIds = todasLasLecciones.map((l: any) => l.id);
          const { data: progresoData } = await supabase
            .from('progreso_lecciones')
            .select('leccion_id, estado, ultima_actividad')
            .eq('usuario_id', $usuario.id)
            .in('leccion_id', leccionIds)
            .not('ultima_actividad', 'is', null)
            .order('ultima_actividad', { ascending: false })
            .limit(1);

          // Obtener nombre del instructor
          let instructorNombre = 'Instructor';
          if (cursoData.instructor_id) {
            const { data: instructor } = await supabase
              .from('perfiles')
              .select('nombre, apellido')
              .eq('id', cursoData.instructor_id)
              .single();
            
            if (instructor) {
              instructorNombre = `${instructor.nombre || ''} ${instructor.apellido || ''}`.trim();
            }
          }

          // Encontrar próxima lección (IGUAL que [slug])
          let proximaLeccion: any = null;
          let moduloDeProxima: any = null;
          
          for (const modulo of modulos) {
            const leccionPendiente = modulo.lecciones?.find((l: any) => {
              const progresoDeLeccion = progresoData?.find((p: any) => p.leccion_id === l.id);
              return !progresoDeLeccion || progresoDeLeccion.estado !== 'completada';
            });
            
            if (leccionPendiente) {
              proximaLeccion = leccionPendiente;
              moduloDeProxima = modulo;
              break;
            }
          }

          // Si hay una lección más reciente visitada, usarla
          let leccionActual: any = null;
          let moduloActual: any = null;
          if (progresoData && progresoData.length > 0) {
            const ultimoProgreso = progresoData[0];
            leccionActual = todasLasLecciones.find((l: any) => l.id === ultimoProgreso.leccion_id);
            if (leccionActual) {
              moduloActual = modulos.find((m: any) => m.lecciones?.some((l: any) => l.id === leccionActual.id));
            }
          }

          // Usar la lección actual si existe, sino la próxima
          const leccionFinal = leccionActual || proximaLeccion;
          const moduloFinal = moduloActual || moduloDeProxima;

          if (leccionFinal && moduloFinal) {
            // GENERAR SLUGS SI NO EXISTEN (igual que TarjetaCurso)
            const cursoSlug = cursoData.slug || generateSlug(cursoData.titulo);
            const moduloSlug = moduloFinal.slug || generateSlug(moduloFinal.titulo);
            const leccionSlug = leccionFinal.slug || generateSlug(leccionFinal.titulo);
            const rutaFinal = `/cursos/${cursoSlug}/${moduloSlug}/${leccionSlug}`;
            
            console.log('📚 [DASHBOARD] Navegando a curso:', rutaFinal);
            
            return {
              tipo: 'curso',
              fechaActividad: new Date(inscripcion.ultima_actividad),
              curso: { ...cursoData, instructor: instructorNombre },
              leccion: leccionFinal,
              modulo: moduloFinal,
              estado: inscripcion.completado ? 'completada' : 'en_progreso',
              porcentajeCompletado: inscripcion.porcentaje_completado || 0,
              ruta: rutaFinal
            };
          }

        } else if (esTutorial) {
          console.log('🎵 [DASHBOARD] Procesando tutorial:', inscripcion.tutorial_id);

          // Cargar tutorial completo (IGUAL que /contenido)
          const { data: tutorialData } = await supabase
            .from('tutoriales')
            .select('id, titulo, imagen_url, artista, acordeonista')
            .eq('id', inscripcion.tutorial_id)
            .single();

          if (!tutorialData) {
            console.log('⚠️ [DASHBOARD] No se pudo cargar el tutorial');
            return null;
          }

          // Cargar partes del tutorial (IGUAL que /contenido)
          const { data: partes } = await supabase
            .from('partes_tutorial')
            .select('id, titulo, slug, orden')
            .eq('tutorial_id', tutorialData.id)
            .order('orden');

          if (!partes || partes.length === 0) {
            console.log('⚠️ [DASHBOARD] No se encontraron clases para el tutorial');
            return null;
          }

          // Obtener progreso (IGUAL que /contenido)
          const { data: progresoData } = await supabase
            .from('progreso_tutorial')
            .select('parte_tutorial_id, completado, ultimo_acceso')
            .eq('usuario_id', $usuario.id)
            .eq('tutorial_id', tutorialData.id)
            .not('ultimo_acceso', 'is', null)
            .order('ultimo_acceso', { ascending: false })
            .limit(1);

          // Encontrar próxima clase (IGUAL que /contenido)
          let proximaClase: any = null;
          const clasePendiente = partes.find((p: any) => {
            const progresoDeParte = progresoData?.find((pr: any) => pr.parte_tutorial_id === p.id);
            return !progresoDeParte || !progresoDeParte.completado;
          });
          
          proximaClase = clasePendiente;

          // Si hay progreso reciente, usar esa clase
          let claseActual: any = null;
          if (progresoData && progresoData.length > 0) {
            const ultimoProgreso = progresoData[0];
            claseActual = partes.find((p: any) => p.id === ultimoProgreso.parte_tutorial_id);
          }

          const claseFinal = claseActual || proximaClase;
          const tutorialSlug = tutorialData.titulo?.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9\-]/g, '') || `tutorial-${tutorialData.id}`;

          if (claseFinal) {
            // GENERAR SLUG DE CLASE SI NO EXISTE (igual que TarjetaCurso)
            const claseSlug = claseFinal.slug || generateSlug(claseFinal.titulo);
            const rutaFinal = `/tutoriales/${tutorialSlug}/clase/${claseSlug}`;
            
            console.log('🎵 [DASHBOARD] Navegando a tutorial:', rutaFinal, `(clase: ${claseSlug})`);
            
            return {
              tipo: 'tutorial',
              fechaActividad: new Date(inscripcion.ultima_actividad),
              tutorial: { ...tutorialData, slug: tutorialSlug },
              clase: claseFinal,
              completado: inscripcion.completado || false,
              ruta: rutaFinal
            };
          }
        }
              } else {
          console.log('⚠️ [DASHBOARD] No se encontró ninguna inscripción para procesar');
          return null;
        }

        console.log('⚠️ [DASHBOARD] No se pudo procesar la inscripción');
        return null;

    } catch (error) {
      console.error('❌ [DASHBOARD] Error obteniendo última clase vista:', error);
      return null;
    }
  }

  // Cargar datos de gamificación y ranking
  async function cargarDatosGamificacion() {
    if (!$usuario?.id) return;

    try {
      console.log('🎮 Cargando datos de gamificación para:', $usuario.id);

      // Obtener experiencia del usuario
      const { data: experiencia } = await supabase
        .from('experiencia_usuario')
        .select('*')
        .eq('usuario_id', $usuario.id)
        .single();

      if (experiencia) {
        datosGamificacion.xpTotal = experiencia.xp_total;
        datosGamificacion.nivel = experiencia.nivel;
        
        // Actualizar racha y metas semanales con datos reales
        metasSemanales.diasEstudio = Math.min(experiencia.racha_dias, 7);
        metasSemanales.horasCompletadas = Math.round((experiencia.xp_total / 100) * 0.5); // Estimación
      }

      // Obtener posición en ranking
      const { data: ranking } = await supabase
        .from('ranking_global')
        .select('posicion, puntuacion')
        .eq('usuario_id', $usuario.id)
        .eq('tipo_ranking', 'general')
        .eq('activo', true)
        .single();

      if (ranking) {
        datosGamificacion.posicionRanking = ranking.posicion;
        datosGamificacion.puntuacionTotal = ranking.puntuacion;
      }

      // Obtener logros conseguidos
      const { data: logros } = await supabase
        .from('logros_usuario')
        .select('conseguido')
        .eq('usuario_id', $usuario.id)
        .eq('conseguido', true);

      if (logros) {
        datosGamificacion.logrosObtenidos = logros.length;
      }

      console.log('🏆 Datos de gamificación cargados:', datosGamificacion);

    } catch (error) {
      console.log('⚠️ Error cargando datos de gamificación (puede ser normal si es nuevo usuario):', error);
    }
  }

  // Cargar actividad reciente
  async function cargarActividadReciente() {
    if (!$usuario?.id) return;

    try {
      const { data: actividad } = await supabase
        .from('progreso_lecciones')
        .select(`
          *,
          lecciones (
            titulo,
            modulos (
              cursos (titulo, slug)
            )
          )
        `)
        .eq('usuario_id', $usuario.id)
        .order('ultima_actividad', { ascending: false })
        .limit(5);

      if (actividad) {
        actividadReciente = actividad.map((a: any) => ({
          id: a.id,
          tipo: 'leccion',
          titulo: a.lecciones?.titulo || 'Lección sin título',
          curso: a.lecciones?.modulos?.cursos?.titulo || 'Curso',
          fecha: a.ultima_actividad,
          progreso: a.porcentaje_completado
        }));
      }
    } catch (error) {
      console.error('Error cargando actividad reciente:', error);
    }
  }

  // Función para obtener el saludo con motivación
  function obtenerMensajeMotivacion(): string {
    const progreso = estadisticasEstudiante.progresoGeneral;
    const nivel = datosGamificacion.nivel;
    const ranking = datosGamificacion.posicionRanking;
    
    // Mensajes específicos por nivel y progreso
    if (nivel >= 10 && ranking && ranking <= 10) {
      return `¡Eres un maestro nivel ${nivel}! Top ${ranking} en el ranking 🏆👑`;
    }
    if (nivel >= 5 && progreso >= 60) {
      return `¡Nivel ${nivel} desbloqueado! Tu progreso del ${progreso}% es impresionante 🎵✨`;
    }
    if (progreso >= 80) {
      return `¡Increíble progreso del ${progreso}%! Estás dominando el acordeón 🎵🔥`;
    }
    if (progreso >= 60) {
      return `¡Excelente trabajo nivel ${nivel}! Sigues mejorando cada día 🚀`;
    }
    if (progreso >= 40) {
      return `¡Vas muy bien nivel ${nivel}! La práctica hace al maestro 💪`;
    }
    if (progreso >= 20) {
      return `¡Buen comienzo nivel ${nivel}! Cada nota cuenta 🎶`;
    }
    return '¡Empieza tu viaje musical hoy! El acordeón te espera 🪗';
  }

  // Ejecutar cuando se monta el componente
  onMount(async () => {
    if (!$usuario?.id) {
      goto('/auth/login');
      return;
    }

    try {
      cargandoDatos = true;
      
      // Cargar datos del perfil si no están disponibles
      if (!$perfilStore.inicializado) {
        await perfilStore.cargarDatosPerfil();
      }

      // Cargar todas las estadísticas en paralelo
      const [estadisticas, gamificacion, actividad, ultimaClase] = await Promise.all([
        cargarEstadisticasEstudiante(),
        cargarDatosGamificacion(),
        cargarActividadReciente(),
        obtenerUltimaClaseVista()
      ]);
      
      // Asignar la última clase vista
      ultimaClaseVista = ultimaClase;
    } catch (error) {
      console.error('Error inicializando dashboard:', error);
    } finally {
      cargandoDatos = false;
    }
  });

  // Funciones de navegación
  function irACursos() {
    goto('/cursos');
  }

  function irASimulador() {
    goto('/simulador-gaming');
  }

  function irAComunidad() {
    goto('/comunidad');
  }

  function irAEventos() {
    goto('/eventos');
  }
</script>

<svelte:head>
  <title>Mi Aprendizaje - Academia Vallenata</title>
  <meta name="description" content="Dashboard personal de aprendizaje de acordeón vallenato" />
  <meta name="robots" content="noindex" />
</svelte:head>

<div class="dashboard-estudiante">
  <!-- Encabezado principal con bienvenida -->
  <section class="seccion-bienvenida">
    <div class="contenedor-bienvenida">
      <div class="info-usuario-principal">
        <div class="avatar-usuario-grande">
          <Avatar 
            src={$usuario?.url_foto_perfil}
            alt="Mi avatar"
            nombreCompleto={$usuario?.nombre || 'Estudiante'}
            size="large"
          />
        </div>
        <div class="texto-bienvenida">
          <h1 class="saludo-principal">{obtenerSaludoDinamico()}</h1>
          <p class="mensaje-motivacion">{obtenerMensajeMotivacion()}</p>
        </div>
      </div>
      
      <div class="acciones-rapidas">
        <button class="boton-accion-principal" on:click={irACursos}>
          <span class="icono-accion">📚</span>
          Explorar Cursos
        </button>
        <button class="boton-accion-secundario" on:click={irASimulador}>
          <span class="icono-accion">🎮</span>
          Simulador
        </button>
      </div>
    </div>
  </section>

  {#if cargandoDatos}
    <!-- Estado de carga -->
    <div class="estado-carga">
      <div class="spinner-dashboard"></div>
      <p>Cargando tu progreso de aprendizaje...</p>
    </div>
  {:else}
    <!-- Grid principal del dashboard -->
    <div class="grid-dashboard">
      
      <!-- Sección de estadísticas principales -->
      <section class="seccion-estadisticas">
        <h2 class="titulo-seccion">📊 Tu Progreso</h2>
        <div class="grid-estadisticas">
          <TarjetaEstadistica 
            icono="📚"
            valor={estadisticasEstudiante.cursosInscritos}
            titulo="Cursos Inscritos"
            descripcion="Total de cursos"
            color="azul"
          />
          
          <TarjetaEstadistica 
            icono="✅"
            valor={estadisticasEstudiante.cursosCompletados}
            titulo="Completados"
            descripcion="Cursos finalizados"
            color="verde"
            tendencia="subiendo"
            porcentajeCambio={15}
          />
          
          <TarjetaEstadistica 
            icono="⏰"
            valor="{estadisticasEstudiante.horasAprendizaje}h"
            titulo="Horas de Estudio"
            descripcion="Tiempo total"
            color="naranja"
          />
          
          <TarjetaEstadistica 
            icono="🏆"
            valor={estadisticasEstudiante.certificadosObtenidos}
            titulo="Certificados"
            descripcion="Logros obtenidos"
            color="purpura"
          />
          
                     <TarjetaEstadistica 
             icono="🔥"
             valor="{estadisticasEstudiante.rachaEstudio} días"
             titulo="Racha de Estudio"
             descripcion="Días consecutivos"
             color="rojo"
             tendencia="subiendo"
             porcentajeCambio={25}
           />

           <TarjetaEstadistica 
             icono="🎮"
             valor="Nv.{datosGamificacion.nivel}"
             titulo="Nivel Gaming"
             descripcion="{datosGamificacion.xpTotal.toLocaleString()} XP"
             color="purpura"
           />

           {#if datosGamificacion.posicionRanking}
             <TarjetaEstadistica 
               icono="🏆"
               valor="#{datosGamificacion.posicionRanking}"
               titulo="Posición Ranking"
               descripcion="{datosGamificacion.puntuacionTotal.toLocaleString()} puntos"
               color="amarillo"
               tendencia="subiendo"
               porcentajeCambio={5}
             />
           {/if}
        </div>
      </section>

      <!-- Sección de progreso visual -->
      <section class="seccion-progreso-visual">
        <h2 class="titulo-seccion">🎯 Progreso General</h2>
        <div class="contenedor-progreso-principal">
          <ProgresCircular 
            porcentaje={estadisticasEstudiante.progresoGeneral}
            titulo="Progreso Total"
            subtitulo="{estadisticasEstudiante.cursosCompletados} de {estadisticasEstudiante.cursosInscritos} cursos"
            color="azul"
            tamano="grande"
            estiloTexto="expandido"
          />
          
          <div class="metas-semanales">
            <h3 class="titulo-metas">🎯 Metas de esta semana</h3>
            <div class="progreso-metas">
              <div class="meta-item">
                <span class="meta-titulo">Horas de estudio</span>
                <div class="meta-progreso">
                  <div class="meta-barra">
                    <div class="meta-relleno" style="width: {(metasSemanales.horasCompletadas / metasSemanales.horasObjetivo) * 100}%"></div>
                  </div>
                  <span class="meta-numeros">{metasSemanales.horasCompletadas}/{metasSemanales.horasObjetivo}h</span>
                </div>
              </div>
              
              <div class="meta-item">
                <span class="meta-titulo">Días de estudio</span>
                <div class="meta-progreso">
                  <div class="dias-semana">
                    {#each Array(7) as _, index}
                      <div class="dia-semana {index < metasSemanales.diasEstudio ? 'completado' : 'pendiente'}">
                        {['L', 'M', 'X', 'J', 'V', 'S', 'D'][index]}
                      </div>
                    {/each}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- Sección Última Clase Vista -->
      {#if ultimaClaseVista}
        <section class="seccion-ultima-clase">
          <div class="contenedor-ultima-clase">
            <div class="encabezado-ultima-clase">
              <h2 class="titulo-seccion">📖 Última Clase Vista</h2>
              <div class="fecha-actividad">
                Última actividad: {ultimaClaseVista.fechaActividad.toLocaleDateString('es-ES', { 
                  day: 'numeric', 
                  month: 'long', 
                  hour: '2-digit', 
                  minute: '2-digit' 
                })}
              </div>
            </div>
            
            <div class="tarjeta-ultima-clase">
              {#if ultimaClaseVista && ultimaClaseVista.tipo === 'curso'}
                <div class="imagen-clase">
                  <img src={ultimaClaseVista.curso?.imagen_url || '/images/default-curso.jpg'} 
                       alt={ultimaClaseVista.curso?.titulo || 'Curso'} />
                  <div class="badge-tipo curso">Curso</div>
                </div>
                <div class="info-clase">
                  <div class="nombre-curso">{ultimaClaseVista.curso?.titulo || 'Curso sin título'}</div>
                  <div class="nombre-modulo">📚 {ultimaClaseVista.modulo?.titulo || 'Módulo'}</div>
                  <div class="nombre-leccion">
                    🎯 <strong>{ultimaClaseVista.leccion?.titulo || 'Lección'}</strong>
                  </div>
                  <div class="instructor">Por {ultimaClaseVista.curso?.instructor || 'Instructor'}</div>
                  <div class="progreso-leccion">
                    <div class="barra-progreso-mini">
                      <div class="relleno-progreso" style="width: {ultimaClaseVista.porcentajeCompletado}%"></div>
                    </div>
                    <span class="texto-progreso">{ultimaClaseVista.estado === 'completada' ? 'Completado' : `${ultimaClaseVista.porcentajeCompletado}% completado`}</span>
                  </div>
                </div>
                <div class="acciones-clase">
                  <button class="btn-continuar-clase" 
                          on:click={() => goto(ultimaClaseVista.ruta)}>
                    🎯 Ir a la Lección
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M5 12h14M12 5l7 7-7 7"/>
                    </svg>
                  </button>
                </div>
              {:else if ultimaClaseVista && ultimaClaseVista.tipo === 'tutorial'}
                <div class="imagen-clase">
                  <img src={ultimaClaseVista.tutorial?.imagen_url || '/images/default-tutorial.jpg'} 
                       alt={ultimaClaseVista.tutorial?.titulo || 'Tutorial'} />
                  <div class="badge-tipo tutorial">Tutorial</div>
                </div>
                <div class="info-clase">
                  <div class="nombre-curso">{ultimaClaseVista.tutorial?.titulo || 'Tutorial sin título'}</div>
                  <div class="nombre-leccion">
                    🎵 <strong>{ultimaClaseVista.clase?.titulo || 'Clase'}</strong>
                  </div>
                  <div class="instructor">
                    {ultimaClaseVista.tutorial?.artista || 'Artista'} - {ultimaClaseVista.tutorial?.acordeonista || 'Acordeonista'}
                  </div>
                  <div class="progreso-leccion">
                    <div class="estado-tutorial">
                      {ultimaClaseVista.completado ? '✅ Completado' : '⏸️ En progreso'}
                    </div>
                  </div>
                </div>
                <div class="acciones-clase">
                  <button class="btn-continuar-clase" 
                          on:click={() => goto(ultimaClaseVista.ruta)}>
                    🎵 Ir a la Clase
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path d="M5 12h14M12 5l7 7-7 7"/>
                    </svg>
                  </button>
                </div>
              {/if}
            </div>
          </div>
        </section>
      {/if}

      <!-- Sección Continuar Aprendiendo -->
      <section class="seccion-continuar-aprendiendo">
        <div class="encabezado-seccion">
          <h2 class="titulo-seccion">🎵 Todos los Cursos en Progreso</h2>
          <button class="boton-ver-todos" on:click={irACursos}>
            Ver todos
            <svg class="icono-flecha" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M5 12h14M12 5l7 7-7 7"/>
            </svg>
          </button>
        </div>
        
        {#if cursosEnProgreso.length > 0}
          <div class="grid-cursos-progreso">
            {#each cursosEnProgreso as curso (curso.id)}
              <TarjetaCursoProgreso {curso} />
            {/each}
          </div>
        {:else}
          <div class="estado-sin-cursos">
            <div class="icono-vacio">📚</div>
            <h3>¡Comienza tu aprendizaje!</h3>
            <p>Inscríbete en un curso para empezar a tocar acordeón</p>
            <button class="boton-empezar" on:click={irACursos}>
              🚀 Explorar Cursos
            </button>
          </div>
        {/if}
      </section>

      <!-- Sección del Simulador (Espacio reservado) -->
      <section class="seccion-simulador-preview">
        <h2 class="titulo-seccion">🎮 Simulador de Acordeón</h2>
        <div class="contenedor-simulador">
          <div class="preview-simulador" on:click={irASimulador} role="button" tabindex="0"
               on:keydown={(e) => e.key === 'Enter' && irASimulador()}>
            <div class="icono-simulador">🪗</div>
            <h3>Practica en el Simulador</h3>
            <p>Mejora tu técnica con nuestro simulador interactivo</p>
                         <div class="estadisticas-simulador">
               <div class="stat-simulador">
                 <span class="valor-stat">Nv.{datosGamificacion.nivel}</span>
                 <span class="label-stat">Nivel</span>
               </div>
               <div class="stat-simulador">
                 <span class="valor-stat">{datosGamificacion.xpTotal.toLocaleString()}</span>
                 <span class="label-stat">XP Total</span>
               </div>
               <div class="stat-simulador">
                 <span class="valor-stat">
                   {datosGamificacion.posicionRanking ? `#${datosGamificacion.posicionRanking}` : 'N/A'}
                 </span>
                 <span class="label-stat">Ranking</span>
               </div>
             </div>
            <button class="boton-simulador">
              <span>🎵 Practicar Ahora</span>
            </button>
          </div>
        </div>
      </section>

             <!-- Sección de gamificación y cómo ganar puntos -->
       <section class="seccion-gamificacion-info">
         <h2 class="titulo-seccion">🎮 Cómo Ganar XP y Puntos</h2>
         <div class="grid-gamificacion">
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">📚</div>
             <h3>Completar Lecciones</h3>
             <p>+100 XP por cada lección completada</p>
             <div class="puntos-extra">+50 XP extra si obtienes más del 80% de precisión</div>
           </div>
           
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">🎮</div>
             <h3>Usar el Simulador</h3>
             <p>+50 XP por cada sesión de práctica</p>
             <div class="puntos-extra">+25 XP por cada canción completada</div>
           </div>
           
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">🔥</div>
             <h3>Mantener Racha</h3>
             <p>+20 XP por cada día consecutivo de estudio</p>
             <div class="puntos-extra">+100 XP bonus por rachas de 7 días</div>
           </div>
           
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">🏆</div>
             <h3>Desbloquear Logros</h3>
             <p>+200-500 XP según la dificultad del logro</p>
             <div class="puntos-extra">¡Algunos logros te dan títulos especiales!</div>
           </div>
           
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">👥</div>
             <h3>Participar en Comunidad</h3>
             <p>+25 XP por publicación útil</p>
             <div class="puntos-extra">+10 XP por cada like recibido</div>
           </div>
           
           <div class="tarjeta-gamificacion">
             <div class="icono-gamificacion">🎯</div>
             <h3>Completar Cursos</h3>
             <p>+1000 XP por curso completado al 100%</p>
             <div class="puntos-extra">¡Obtienes certificado y título especial!</div>
           </div>
         </div>
         
         <!-- Nivel actual y progreso -->
         {#if datosGamificacion.xpTotal > 0}
           <div class="progreso-nivel-actual">
             <h3>🎯 Tu Progreso Actual</h3>
             <div class="info-nivel">
               <div class="nivel-badge">Nivel {datosGamificacion.nivel}</div>
               <div class="xp-info">
                 <span>{datosGamificacion.xpTotal.toLocaleString()} XP total acumulado</span>
                 {#if datosGamificacion.logrosObtenidos > 0}
                   <span>🏆 {datosGamificacion.logrosObtenidos} logros desbloqueados</span>
                 {/if}
               </div>
             </div>
             
             <!-- Próximo nivel -->
             <div class="proximo-nivel">
               <p>🚀 Sigue practicando para subir al siguiente nivel y desbloquear nuevas funcionalidades</p>
               <a href="/ranking" class="boton-ranking">
                 Ver Mi Posición en el Ranking
                 <svg class="icono-flecha" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                   <path d="M5 12h14M12 5l7 7-7 7"/>
                 </svg>
               </a>
             </div>
           </div>
         {/if}
       </section>

       <!-- Sección de accesos rápidos -->
       <section class="seccion-accesos-rapidos">
        <h2 class="titulo-seccion">⚡ Accesos Rápidos</h2>
        <div class="grid-accesos">
          <button class="tarjeta-acceso" on:click={irAComunidad}>
            <div class="icono-acceso">👥</div>
            <h3>Comunidad</h3>
            <p>Conecta con otros estudiantes</p>
          </button>
          
          <button class="tarjeta-acceso" on:click={irAEventos}>
            <div class="icono-acceso">📅</div>
            <h3>Eventos</h3>
            <p>Masterclasses y conciertos</p>
          </button>
          
          <button class="tarjeta-acceso" on:click={() => goto('/ranking')}>
            <div class="icono-acceso">🏆</div>
            <h3>Ranking</h3>
            <p>Tu posición en la comunidad</p>
          </button>
          
          <button class="tarjeta-acceso" on:click={() => goto('/certificados')}>
            <div class="icono-acceso">🎓</div>
            <h3>Certificados</h3>
            <p>Tus logros académicos</p>
          </button>
        </div>
      </section>

    </div>
  {/if}
</div>

<style>
  .dashboard-estudiante {
    min-height: 100vh;
    background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
    padding: 2rem;
  }

  /* Sección de bienvenida */
  .seccion-bienvenida {
    margin-bottom: 3rem;
  }

  .contenedor-bienvenida {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 24px;
    padding: 3rem;
    color: white;
    display: flex;
    justify-content: space-between;
    align-items: center;
    box-shadow: 0 10px 30px rgba(102, 126, 234, 0.3);
  }

  .info-usuario-principal {
    display: flex;
    align-items: center;
    gap: 2rem;
  }

  .avatar-usuario-grande {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    border: 4px solid rgba(255, 255, 255, 0.3);
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .texto-bienvenida h1 {
    font-size: 2.5rem;
    font-weight: 800;
    margin: 0 0 0.5rem 0;
    line-height: 1.2;
  }

  .mensaje-motivacion {
    font-size: 1.1rem;
    opacity: 0.9;
    margin: 0;
    font-weight: 400;
  }

  .acciones-rapidas {
    display: flex;
    gap: 1rem;
  }

  .boton-accion-principal,
  .boton-accion-secundario {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
    white-space: nowrap;
  }

  .boton-accion-principal {
    background: rgba(255, 255, 255, 0.2);
    color: white;
    backdrop-filter: blur(10px);
  }

  .boton-accion-secundario {
    background: rgba(255, 255, 255, 0.1);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
  }

  .boton-accion-principal:hover,
  .boton-accion-secundario:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
  }

  .icono-accion {
    font-size: 1.2rem;
  }

  /* Estado de carga */
  .estado-carga {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 4rem;
    text-align: center;
  }

  .spinner-dashboard {
    width: 50px;
    height: 50px;
    border: 4px solid #e2e8f0;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  /* Grid principal */
  .grid-dashboard {
    display: grid;
    gap: 2rem;
    grid-template-columns: 1fr;
  }

  /* Secciones */
  .titulo-seccion {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 1.5rem 0;
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  /* Estadísticas */
  .seccion-estadisticas {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
  }

  .grid-estadisticas {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 1.5rem;
  }

  /* Progreso visual */
  .seccion-progreso-visual {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
  }

  .contenedor-progreso-principal {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 3rem;
    align-items: center;
  }

  .metas-semanales {
    flex: 1;
  }

  .titulo-metas {
    font-size: 1.25rem;
    font-weight: 600;
    color: #374151;
    margin: 0 0 1.5rem 0;
  }

  .meta-item {
    margin-bottom: 1.5rem;
  }

  .meta-titulo {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: #6b7280;
    margin-bottom: 0.5rem;
  }

  .meta-progreso {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .meta-barra {
    flex: 1;
    height: 8px;
    background: #f1f5f9;
    border-radius: 4px;
    overflow: hidden;
  }

  .meta-relleno {
    height: 100%;
    background: linear-gradient(90deg, #3b82f6, #1d4ed8);
    border-radius: 4px;
    transition: width 0.8s ease;
  }

  .meta-numeros {
    font-size: 0.875rem;
    font-weight: 600;
    color: #374151;
    white-space: nowrap;
  }

  .dias-semana {
    display: flex;
    gap: 0.5rem;
  }

  .dia-semana {
    width: 32px;
    height: 32px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    font-weight: 600;
    transition: all 0.2s ease;
  }

  .dia-semana.completado {
    background: #22c55e;
    color: white;
  }

  .dia-semana.pendiente {
    background: #f1f5f9;
    color: #9ca3af;
  }

  /* Continuar aprendiendo */
  .seccion-continuar-aprendiendo {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
  }

  .encabezado-seccion {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  .boton-ver-todos {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: transparent;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    color: #64748b;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .boton-ver-todos:hover {
    background: #f8fafc;
    border-color: #cbd5e1;
    color: #374151;
  }

  .icono-flecha {
    width: 16px;
    height: 16px;
  }

  .grid-cursos-progreso {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
    gap: 1.5rem;
  }

  .estado-sin-cursos {
    text-align: center;
    padding: 3rem;
  }

  .icono-vacio {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .estado-sin-cursos h3 {
    font-size: 1.5rem;
    font-weight: 600;
    color: #374151;
    margin: 0 0 0.5rem 0;
  }

  .estado-sin-cursos p {
    color: #6b7280;
    margin: 0 0 2rem 0;
  }

  .boton-empezar {
    padding: 0.75rem 2rem;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .boton-empezar:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  /* Simulador preview */
  .seccion-simulador-preview {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
  }

  .preview-simulador {
    background: linear-gradient(135deg, #f97316 0%, #ea580c 100%);
    border-radius: 16px;
    padding: 2rem;
    text-align: center;
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .preview-simulador:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(249, 115, 22, 0.3);
  }

  .icono-simulador {
    font-size: 4rem;
    margin-bottom: 1rem;
  }

  .preview-simulador h3 {
    font-size: 1.5rem;
    font-weight: 700;
    margin: 0 0 0.5rem 0;
  }

  .preview-simulador p {
    opacity: 0.9;
    margin: 0 0 2rem 0;
  }

  .estadisticas-simulador {
    display: flex;
    justify-content: center;
    gap: 2rem;
    margin-bottom: 2rem;
  }

  .stat-simulador {
    text-align: center;
  }

  .valor-stat {
    display: block;
    font-size: 1.5rem;
    font-weight: 800;
  }

  .label-stat {
    font-size: 0.875rem;
    opacity: 0.8;
  }

  .boton-simulador {
    background: rgba(255, 255, 255, 0.2);
    border: 1px solid rgba(255, 255, 255, 0.3);
    color: white;
    padding: 0.75rem 2rem;
    border-radius: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .boton-simulador:hover {
    background: rgba(255, 255, 255, 0.3);
  }

  /* Accesos rápidos */
  .seccion-accesos-rapidos {
    background: white;
    border-radius: 20px;
    padding: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
  }

  .grid-accesos {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
  }

  .tarjeta-acceso {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 1.5rem;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .tarjeta-acceso:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    background: white;
  }

  .icono-acceso {
    font-size: 2rem;
    margin-bottom: 0.75rem;
  }

  .tarjeta-acceso h3 {
    font-size: 1rem;
    font-weight: 600;
    color: #374151;
    margin: 0 0 0.5rem 0;
  }

     .tarjeta-acceso p {
     font-size: 0.875rem;
     color: #6b7280;
     margin: 0;
   }

   /* Sección de gamificación */
   .seccion-gamificacion-info {
     background: white;
     border-radius: 20px;
     padding: 2rem;
     box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
     border: 1px solid #e2e8f0;
   }

   .grid-gamificacion {
     display: grid;
     grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
     gap: 1.5rem;
     margin-bottom: 2rem;
   }

   .tarjeta-gamificacion {
     background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
     border: 1px solid #e2e8f0;
     border-radius: 12px;
     padding: 1.5rem;
     text-align: center;
     transition: all 0.3s ease;
     position: relative;
     overflow: hidden;
   }

   .tarjeta-gamificacion::before {
     content: '';
     position: absolute;
     top: 0;
     left: -100%;
     width: 100%;
     height: 2px;
     background: linear-gradient(90deg, transparent, #667eea, transparent);
     transition: left 0.5s ease;
   }

   .tarjeta-gamificacion:hover::before {
     left: 100%;
   }

   .tarjeta-gamificacion:hover {
     transform: translateY(-4px);
     box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
     background: white;
   }

   .icono-gamificacion {
     font-size: 2.5rem;
     margin-bottom: 1rem;
     display: block;
   }

   .tarjeta-gamificacion h3 {
     font-size: 1.1rem;
     font-weight: 700;
     color: #374151;
     margin: 0 0 0.5rem 0;
   }

   .tarjeta-gamificacion p {
     color: #6b7280;
     margin: 0 0 0.75rem 0;
     font-weight: 500;
   }

   .puntos-extra {
     font-size: 0.85rem;
     color: #059669;
     background: rgba(5, 150, 105, 0.1);
     padding: 0.5rem;
     border-radius: 8px;
     border: 1px solid rgba(5, 150, 105, 0.2);
     font-weight: 600;
   }

   .progreso-nivel-actual {
     background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
     border-radius: 16px;
     padding: 2rem;
     color: white;
     text-align: center;
   }

   .progreso-nivel-actual h3 {
     font-size: 1.5rem;
     font-weight: 700;
     margin: 0 0 1.5rem 0;
   }

   .info-nivel {
     display: flex;
     flex-direction: column;
     align-items: center;
     gap: 1rem;
     margin-bottom: 1.5rem;
   }

   .nivel-badge {
     background: rgba(255, 255, 255, 0.2);
     backdrop-filter: blur(10px);
     border: 1px solid rgba(255, 255, 255, 0.3);
     padding: 0.75rem 2rem;
     border-radius: 50px;
     font-size: 1.25rem;
     font-weight: 800;
     text-transform: uppercase;
     letter-spacing: 1px;
   }

   .xp-info {
     display: flex;
     flex-direction: column;
     gap: 0.5rem;
     opacity: 0.9;
   }

   .xp-info span {
     font-size: 1rem;
     font-weight: 500;
   }

   .proximo-nivel p {
     opacity: 0.9;
     margin: 0 0 1.5rem 0;
     font-size: 1.1rem;
   }

   .boton-ranking {
     display: inline-flex;
     align-items: center;
     gap: 0.5rem;
     padding: 0.75rem 2rem;
     background: rgba(255, 255, 255, 0.2);
     backdrop-filter: blur(10px);
     border: 1px solid rgba(255, 255, 255, 0.3);
     color: white;
     text-decoration: none;
     border-radius: 12px;
     font-weight: 600;
     transition: all 0.3s ease;
   }

   .boton-ranking:hover {
     background: rgba(255, 255, 255, 0.3);
     transform: translateY(-2px);
     box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
   }

   .boton-ranking .icono-flecha {
     width: 16px;
     height: 16px;
   }

  /* Animaciones */
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }

  /* Responsive */
  @media (max-width: 1200px) {
    .contenedor-progreso-principal {
      grid-template-columns: 1fr;
      gap: 2rem;
      text-align: center;
    }

    .estadisticas-simulador {
      gap: 1.5rem;
    }
  }

  @media (max-width: 768px) {
    .dashboard-estudiante {
      padding: 1rem;
    }

    .contenedor-bienvenida {
      flex-direction: column;
      gap: 2rem;
      text-align: center;
      padding: 2rem;
    }

    .info-usuario-principal {
      flex-direction: column;
      gap: 1rem;
    }

    .texto-bienvenida h1 {
      font-size: 2rem;
    }

    .acciones-rapidas {
      flex-direction: column;
      width: 100%;
    }

    .grid-estadisticas {
      grid-template-columns: 1fr;
    }

    .grid-cursos-progreso {
      grid-template-columns: 1fr;
    }

    .encabezado-seccion {
      flex-direction: column;
      gap: 1rem;
      align-items: stretch;
    }

    .estadisticas-simulador {
      flex-direction: column;
      gap: 1rem;
    }

         .grid-accesos {
       grid-template-columns: repeat(2, 1fr);
     }

     .grid-gamificacion {
       grid-template-columns: repeat(2, 1fr);
     }

     .info-nivel {
       flex-direction: column;
     }
  }

  @media (max-width: 480px) {
         .grid-accesos {
       grid-template-columns: 1fr;
     }

     .grid-gamificacion {
       grid-template-columns: 1fr;
     }

     .tarjeta-gamificacion {
       padding: 1.25rem;
     }

     .progreso-nivel-actual {
       padding: 1.5rem;
     }

    .contenedor-bienvenida {
      padding: 1.5rem;
    }

    .texto-bienvenida h1 {
      font-size: 1.75rem;
    }
  }

  /* Estilos para la sección de última clase vista */
  .seccion-ultima-clase {
    background: white;
    border-radius: 20px;
    padding: 0;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
    border: 1px solid #e2e8f0;
    overflow: hidden;
    margin-bottom: 2rem;
  }

  .contenedor-ultima-clase {
    position: relative;
  }

  .encabezado-ultima-clase {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1.5rem 2rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .encabezado-ultima-clase .titulo-seccion {
    color: white;
    margin: 0;
    font-size: 1.25rem;
    font-weight: 700;
  }

  .fecha-actividad {
    font-size: 0.875rem;
    opacity: 0.9;
    background: rgba(255, 255, 255, 0.15);
    padding: 0.5rem 1rem;
    border-radius: 20px;
    backdrop-filter: blur(10px);
  }

  .tarjeta-ultima-clase {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 1.5rem;
    padding: 2rem;
    align-items: center;
  }

  .imagen-clase {
    position: relative;
    width: 120px;
    height: 80px;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  .imagen-clase img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  .badge-tipo {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    padding: 0.25rem 0.75rem;
    border-radius: 20px;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .badge-tipo.curso {
    background: #3b82f6;
    color: white;
  }

  .badge-tipo.tutorial {
    background: #a855f7;
    color: white;
  }

  .info-clase {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .nombre-curso {
    font-size: 1.25rem;
    font-weight: 700;
    color: #1e293b;
    line-height: 1.3;
  }

  .nombre-modulo {
    font-size: 0.875rem;
    color: #64748b;
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .nombre-leccion {
    font-size: 1rem;
    font-weight: 600;
    color: #374151;
  }

  .instructor {
    font-size: 0.875rem;
    color: #6b7280;
  }

  .progreso-leccion {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-top: 0.5rem;
  }

  .barra-progreso-mini {
    width: 100px;
    height: 6px;
    background: #e5e7eb;
    border-radius: 3px;
    overflow: hidden;
  }

  .relleno-progreso {
    height: 100%;
    background: linear-gradient(90deg, #3b82f6, #1d4ed8);
    border-radius: 3px;
    transition: width 0.3s ease;
  }

  .texto-progreso {
    font-size: 0.875rem;
    color: #374151;
    font-weight: 500;
  }

  .estado-tutorial {
    font-size: 0.875rem;
    font-weight: 600;
    padding: 0.5rem 1rem;
    border-radius: 20px;
    background: #f0f9ff;
    color: #0369a1;
  }

  .acciones-clase {
    display: flex;
    align-items: center;
  }

  .btn-continuar-clase {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    color: white;
    border: none;
    padding: 0.875rem 1.5rem;
    border-radius: 12px;
    font-weight: 600;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
  }

  .btn-continuar-clase:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(59, 130, 246, 0.35);
  }

  .btn-continuar-clase:active {
    transform: translateY(0);
  }

  /* Responsive para última clase */
  @media (max-width: 768px) {
    .tarjeta-ultima-clase {
      grid-template-columns: 1fr;
      gap: 1rem;
      text-align: center;
    }

    .encabezado-ultima-clase {
      flex-direction: column;
      gap: 0.75rem;
      align-items: center;
      text-align: center;
    }

    .imagen-clase {
      width: 100px;
      height: 67px;
      margin: 0 auto;
    }

    .acciones-clase {
      justify-content: center;
    }

    .btn-continuar-clase {
      width: 100%;
      justify-content: center;
    }
  }
</style>
