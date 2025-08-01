<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { goto } from '$app/navigation';
  
  import EstadisticasGenerales from '$lib/components/PanelAdministracion/EstadisticasGenerales.svelte';
  import ActividadTiempoReal from '$lib/components/PanelAdministracion/ActividadTiempoReal.svelte';
  import GestionAlumnos from '$lib/components/PanelAdministracion/GestionAlumnos.svelte';
  import GestionPaquetes from '$lib/components/PanelAdministracion/GestionPaquetes.svelte';
  import GestionArticulosBlog from '$lib/components/PanelAdministracion/GestionArticulosBlog.svelte';
  import { actividadService } from '$lib/services/actividadTiempoRealService';
  
  // 🚀 SISTEMA DE PESTAÑAS ORGANIZADAS
  import PestanasAdministracion from '$lib/components/PanelAdministracion/PestanasAdministracion.svelte';
  
  let cargandoDatos = true;
  let errorCarga = '';
  let autoRefresh = true;
  let ultimaActualizacion = '';
  let estadisticasGenerales: any = null;
  let actividadTiempoReal: any[] = [];
  let alumnosActivos: any[] = [];
  let usuarioActual: any = null;
  let esAdmin = false;
  let intervalId: NodeJS.Timeout | null = null;
  
  // ✅ NUEVAS VARIABLES PARA MODAL DE ALUMNOS
  let mostrarModalAlumnos = false;
  let todosLosAlumnos: any[] = [];
  let cargandoTodosAlumnos = false;

  onMount(async () => {
    await verificarAccesoAdmin();
    if (esAdmin) {
      await cargarDatos();
      iniciarAutoRefresh();
    }
  });

  onDestroy(() => {
    if (intervalId) {
      clearInterval(intervalId);
      intervalId = null;
    }
  });

  async function verificarAccesoAdmin() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        goto('/');
        return;
      }

      const { data: perfil } = await supabase
        .from('perfiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (!perfil || perfil.rol !== 'admin') {
        goto('/');
        return;
      }

      usuarioActual = perfil;
      esAdmin = true;
    } catch (error) {
      goto('/');
    }
  }

  async function cargarDatos() {
    try {
      cargandoDatos = true;
      errorCarga = '';

      await Promise.all([
        cargarEstadisticasGenerales(),
        cargarActividadTiempoReal(),
        cargarAlumnosActivos()
      ]);

      cargandoDatos = false;
      ultimaActualizacion = new Date().toLocaleTimeString();
    } catch (error) {
      errorCarga = 'Error al cargar los datos del panel';
      cargandoDatos = false;
    }
  }

  async function cargarEstadisticasGenerales() {
    try {
      const { data: perfiles } = await supabase
        .from('perfiles')
        .select('id, suscripcion');

      const totalEstudiantes = perfiles?.length || 0;
      const usuariosPremium = perfiles?.filter((p: any) => p.suscripcion && p.suscripcion !== 'free').length || 0;

      const { data: cursos } = await supabase
        .from('cursos')
        .select('id');

      const { data: tutoriales } = await supabase
        .from('tutoriales')
        .select('id');

      const hace30Dias = new Date();
      hace30Dias.setDate(hace30Dias.getDate() - 30);

      const { data: inscripciones } = await supabase
        .from('inscripciones')
        .select('id, created_at, curso_id, tutorial_id')
        .gte('created_at', hace30Dias.toISOString());

      const inicioMes = new Date();
      inicioMes.setDate(1);
      inicioMes.setHours(0, 0, 0, 0);

      const { data: pagosReales } = await supabase
        .from('pagos_epayco')
        .select('*')
        .gte('created_at', inicioMes.toISOString())
        .order('created_at', { ascending: false });

      const pagosFiltrados = pagosReales || [];
      const ventasTotalesMes = pagosFiltrados.reduce((sum: number, p: any) => sum + (parseFloat(p.valor) || 0), 0);
      const transaccionesDelMes = pagosFiltrados.length;
      const pagosAceptados = pagosFiltrados.filter((p: any) => p.estado === 'aceptada').length;
      const pagosPendientes = pagosFiltrados.filter((p: any) => p.estado === 'pendiente').length;
      const pagosRechazados = pagosFiltrados.filter((p: any) => p.estado === 'rechazada').length;
      const ventasCursos = pagosFiltrados.filter((p: any) => p.curso_id).length;
      const ventasTutoriales = pagosFiltrados.filter((p: any) => p.tutorial_id).length;
      const ventasOtros = transaccionesDelMes - ventasCursos - ventasTutoriales;

      estadisticasGenerales = {
        totalUsuarios: totalEstudiantes,
        usuariosPremium,
        totalContenido: (cursos?.length || 0) + (tutoriales?.length || 0),
        cursosActivos: cursos?.length || 0,
        tutorialesActivos: tutoriales?.length || 0,
        inscripcionesRecientes: inscripciones?.length || 0,
        porcentajePremium: totalEstudiantes > 0 ? Math.round((usuariosPremium / totalEstudiantes) * 100) : 0,
        ventasTotalesMes,
        transaccionesDelMes,
        ventasCursos,
        ventasTutoriales,
        ventasOtros,
        pagosAceptados,
        pagosPendientes,
        pagosRechazados
      };
    } catch (error) {
      estadisticasGenerales = null;
    }
  }

  async function cargarActividadTiempoReal() {
    try {
      console.log('🔄 [PANEL ADMIN] Cargando TODOS los usuarios con sesión activa...');
      
      const ahora = new Date();
      const hace5Min = new Date(ahora.getTime() - 5 * 60 * 1000);
      const hace30Min = new Date(ahora.getTime() - 30 * 60 * 1000);
      const hace2Horas = new Date(ahora.getTime() - 2 * 60 * 60 * 1000);
      
      // 1️⃣ OBTENER USUARIOS ACTIVOS DESDE SESIONES_USUARIO (columnas correctas)
      const { data: usuariosSesionActiva, error: errorSesion } = await supabase
        .from('sesiones_usuario')
        .select(`
          usuario_id,
          ultima_actividad,
          pagina_actual,
          esta_activo,
          tiempo_sesion_actual,
          tiempo_total_minutos,
          sesiones_totales,
          perfiles:usuario_id (
            id,
            nombre,
            apellido,
            url_foto_perfil,
            rol
          )
        `)
        .eq('esta_activo', true)
        .gte('ultima_actividad', hace2Horas.toISOString())
        .order('ultima_actividad', { ascending: false })
        .limit(25);

      if (errorSesion) {
        console.error('❌ [PANEL ADMIN] Error obteniendo usuarios activos:', errorSesion);
      }
      
      // 2️⃣ OBTENER SESIONES ACTIVAS SI LA TABLA EXISTE
      let sesionesActivas = [];
      try {
        const { data: sesiones } = await supabase
          .from('sesiones_usuario')
          .select(`
            *,
            perfiles:usuario_id (
              id,
              nombre,
              apellido,
              url_foto_perfil,
              rol
            )
          `)
          .eq('esta_activo', true)
          .gte('ultima_actividad', hace30Min.toISOString())
          .order('ultima_actividad', { ascending: false });
        
        if (sesiones) {
          sesionesActivas = sesiones;
          console.log('📊 [SESIONES] Encontradas:', sesiones.length);
        }
      } catch (sesionError) {
        console.warn('⚠️ [SESIONES] Tabla no disponible');
      }
      
      // 3️⃣ COMBINAR TODAS LAS FUENTES
      const usuariosFinales = new Map();
      
      // Agregar usuarios con sesión activa
      if (usuariosSesionActiva) {
        usuariosSesionActiva.forEach((sesion: any) => {
          if (sesion.perfiles) {
            const minutosDesdeUpdate = Math.floor((ahora.getTime() - new Date(sesion.ultima_actividad).getTime()) / (1000 * 60));
            const esActivoAhora = minutosDesdeUpdate <= 5;
            const esActivoReciente = minutosDesdeUpdate <= 30;
            
            // Formatear nombre de página más legible
            let paginaAmigable = sesion.pagina_actual || '/panel-estudiante';
            if (paginaAmigable.includes('/panel-estudiante')) paginaAmigable = 'Panel Estudiante';
            else if (paginaAmigable.includes('/cursos')) paginaAmigable = 'Cursos';
            else if (paginaAmigable.includes('/tutoriales')) paginaAmigable = 'Tutoriales';
            else if (paginaAmigable.includes('/simulador')) paginaAmigable = 'Simulador';
            else if (paginaAmigable.includes('/comunidad')) paginaAmigable = 'Comunidad';
            else if (paginaAmigable === '/') paginaAmigable = 'Inicio';
            
            usuariosFinales.set(sesion.usuario_id, {
              usuario_id: sesion.usuario_id,
              ultima_actividad: sesion.ultima_actividad,
              pagina_actual: paginaAmigable,
              tiempo_sesion_actual: sesion.tiempo_sesion_actual || Math.max(1, 60 - minutosDesdeUpdate),
              esta_activo: sesion.esta_activo && esActivoReciente,
              perfiles: sesion.perfiles,
              tipo_actividad: esActivoAhora ? 'En línea ahora' : 
                             esActivoReciente ? `Hace ${minutosDesdeUpdate}m` : 
                             'Conectado recientemente',
              tiempo_total_minutos: sesion.tiempo_total_minutos || 0,
              origen: 'sesiones_usuario',
              estado_visual: esActivoAhora ? 'online' : esActivoReciente ? 'reciente' : 'offline',
              es_datos_reales: true  // ✅ Marcar como datos reales
            });
          }
        });
      }
      
      // Agregar sesiones activas (si existen)
              sesionesActivas.forEach((sesion: any) => {
          if (sesion.perfiles && !usuariosFinales.has(sesion.usuario_id)) {
            usuariosFinales.set(sesion.usuario_id, {
              usuario_id: sesion.usuario_id,
              ultima_actividad: sesion.ultima_actividad,
              pagina_actual: sesion.pagina_actual || 'Panel Estudiante',
              tiempo_sesion_actual: sesion.tiempo_sesion_actual || 1,
              esta_activo: true,
              perfiles: sesion.perfiles,
              tipo_actividad: 'Sesión activa',
              tiempo_total_minutos: sesion.tiempo_total_minutos || 0,
              origen: 'sesion_usuario',
              estado_visual: 'online',
              es_datos_reales: true  // ✅ Marcar como datos reales
            });
          }
        });
      
      // 4️⃣ CONVERTIR Y ORDENAR POR PRIORIDAD
      actividadTiempoReal = Array.from(usuariosFinales.values())
        .sort((a: any, b: any) => {
          // 1. Usuarios en línea ahora
          if (a.estado_visual === 'online' && b.estado_visual !== 'online') return -1;
          if (a.estado_visual !== 'online' && b.estado_visual === 'online') return 1;
          
          // 2. Usuarios activos recientemente
          if (a.esta_activo && !b.esta_activo) return -1;
          if (!a.esta_activo && b.esta_activo) return 1;
          
          // 3. Por última actividad
          return new Date(b.ultima_actividad).getTime() - new Date(a.ultima_actividad).getTime();
        })
        .slice(0, 15); // Mostrar más usuarios
      
      console.log(`✅ [PANEL ADMIN] TODOS los usuarios cargados: ${actividadTiempoReal.length} activos`);
      console.log('📊 [DETALLE COMPLETO]:', actividadTiempoReal.map(u => 
        `${u.perfiles?.nombre} - ${u.pagina_actual} (${u.tipo_actividad}) [${u.origen}]`));
      
    } catch (error) {
      console.error('❌ [PANEL ADMIN] Error cargando actividad:', error);
      actividadTiempoReal = [];
    }
  }

  async function cargarAlumnosActivos() {
    try {
      console.log('🔄 [PANEL ADMIN] Cargando alumnos con actividad reciente (últimos 7 días)...');
      
      const ahora = new Date();
      const hace5Min = new Date(ahora.getTime() - 5 * 60 * 1000);
      const hace30Min = new Date(ahora.getTime() - 30 * 60 * 1000);
      const hace7Dias = new Date(ahora.getTime() - 7 * 24 * 60 * 60 * 1000); // ✅ 7 días para mostrar más usuarios
      
      // 1️⃣ OBTENER ESTUDIANTES CON ACTIVIDAD RECIENTE (NO SOLO ACTIVOS)
      const { data: estudiantesActivos } = await supabase
        .from('sesiones_usuario')
        .select(`
          usuario_id,
          ultima_actividad,
          pagina_actual,
          esta_activo,
          tiempo_sesion_actual,
          tiempo_total_minutos,
          sesiones_totales,
          perfiles:usuario_id (
            id,
            nombre,
            apellido,
            url_foto_perfil,
            nivel_habilidad,
            suscripcion,
            rol
          )
        `)
        .gte('ultima_actividad', hace7Dias.toISOString()) // ✅ Últimos 7 días
        .order('ultima_actividad', { ascending: false })
        .limit(50); // ✅ Más usuarios para el modal

      // 2️⃣ OBTENER DATOS DE INSCRIPCIONES PARA MÉTRICAS
      const { data: datosInscripciones } = await supabase
        .from('inscripciones')
        .select(`
          usuario_id,
          progreso,
          porcentaje_completado,
          completado,
          ultima_actividad,
          created_at
        `)
        .not('ultima_actividad', 'is', null);

      // 3️⃣ PROCESAR Y COMBINAR DATOS
      const usuariosMap = new Map();
      
      // Agregar estudiantes activos
      if (estudiantesActivos) {
        estudiantesActivos.forEach((sesion: any) => {
          if (sesion.perfiles && sesion.perfiles.rol === 'estudiante') {
            const minutosDesdeUpdate = Math.floor((ahora.getTime() - new Date(sesion.ultima_actividad).getTime()) / (1000 * 60));
            const horasDesdeUpdate = Math.floor(minutosDesdeUpdate / 60);
            const diasDesdeUpdate = Math.floor(horasDesdeUpdate / 24);
            
            // ✅ DETERMINAR ESTADO BASADO EN BD Y TIEMPO
            const esActivoAhora = sesion.esta_activo && minutosDesdeUpdate <= 5;
            const esActivoReciente = sesion.esta_activo && minutosDesdeUpdate <= 30;
            const esActivoHoy = horasDesdeUpdate <= 24;
            const esActivoSemana = diasDesdeUpdate <= 7;
            
            // ✅ ESTADO VISUAL PRECISO
            let estado_visual = 'offline';
            let estado_texto = 'Desconectado';
            
            if (!sesion.esta_activo) {
              // Usuario marcado como inactivo (cerró sesión)
              estado_visual = 'desconectado';
              estado_texto = `Desconectado hace ${minutosDesdeUpdate <= 60 ? minutosDesdeUpdate + 'm' : horasDesdeUpdate + 'h'}`;
            } else if (esActivoAhora) {
              estado_visual = 'online';
              estado_texto = 'En línea ahora';
            } else if (esActivoReciente) {
              estado_visual = 'reciente';
              estado_texto = `Hace ${minutosDesdeUpdate}m`;
            } else if (esActivoHoy) {
              estado_visual = 'hoy';
              estado_texto = `Hace ${horasDesdeUpdate}h`;
            } else if (esActivoSemana) {
              estado_visual = 'semana';
              estado_texto = `Hace ${diasDesdeUpdate}d`;
            }
            
            // ✅ VERIFICAR SI EL USUARIO YA EXISTE PARA SUMAR TIEMPO DE MÚLTIPLES FECHAS
            const usuarioExistente = usuariosMap.get(sesion.usuario_id);
            
            if (usuarioExistente) {
              // Sumar tiempo de diferentes fechas y mantener la actividad más reciente
              usuarioExistente.tiempo_total_minutos += (sesion.tiempo_total_minutos || 0);
              
              // Actualizar si esta sesión es más reciente
              if (new Date(sesion.ultima_actividad) > new Date(usuarioExistente.ultima_actividad)) {
                usuarioExistente.ultima_actividad = sesion.ultima_actividad;
                usuarioExistente.esta_activo = sesion.esta_activo;
                usuarioExistente.estado_visual = estado_visual;
                usuarioExistente.estado_texto = estado_texto;
                usuarioExistente.minutos_desde_actividad = minutosDesdeUpdate;
              }
            } else {
              // Crear nuevo registro de usuario
              usuariosMap.set(sesion.usuario_id, {
                usuario_id: sesion.usuario_id,
                perfiles: sesion.perfiles,
                ultima_actividad: sesion.ultima_actividad,
                inscripciones_count: 0,
                tiempo_total_minutos: sesion.tiempo_total_minutos || 0, // ✅ Campo correcto
                porcentaje_total: 0,
                cursos_completados: 0,
                esta_activo: sesion.esta_activo, // ✅ Estado real de BD
                estado_visual: estado_visual,
                estado_texto: estado_texto, // ✅ Texto descriptivo
                origen: 'sesiones_usuario',
                minutos_desde_actividad: minutosDesdeUpdate
              });
            }
          }
        });
      }

      // Agregar métricas de inscripciones
      if (datosInscripciones) {
        datosInscripciones.forEach((inscripcion: any) => {
          const userId = inscripcion.usuario_id;
          if (usuariosMap.has(userId)) {
            const usuario = usuariosMap.get(userId);
            usuario.inscripciones_count += 1;
            // ✅ NO tocar tiempo_total_minutos aquí (es de sesiones, no de inscripciones)
            usuario.porcentaje_total += (inscripcion.porcentaje_completado || 0);
            usuario.cursos_completados += (inscripcion.completado ? 1 : 0);
            
            // Actualizar última actividad si es más reciente
            if (inscripcion.ultima_actividad && 
                new Date(inscripcion.ultima_actividad) > new Date(usuario.ultima_actividad)) {
              usuario.ultima_actividad = inscripcion.ultima_actividad;
            }
          }
        });
      }

      // 4️⃣ CONVERTIR A ARRAY CON MÉTRICAS FINALES
      alumnosActivos = Array.from(usuariosMap.values())
        .map((usuario: any) => ({
          usuario_id: usuario.usuario_id,
          perfiles: usuario.perfiles,
          ultima_actividad: usuario.ultima_actividad,
          tiempo_total_minutos: usuario.tiempo_total_minutos, // ✅ Campo correcto
          sesiones_totales: Math.max(1, usuario.inscripciones_count),
          porcentaje_promedio: usuario.inscripciones_count > 0 ? 
            Math.round(usuario.porcentaje_total / usuario.inscripciones_count) : 0,
          cursos_completados: usuario.cursos_completados,
          esta_activo: usuario.esta_activo,
          estado_visual: usuario.estado_visual,
          estado_texto: usuario.estado_texto, // ✅ Texto del estado
          minutos_desde_actividad: usuario.minutos_desde_actividad, // ✅ Para cálculos de tiempo
          origen: usuario.origen,
          es_datos_reales: true  // ✅ Marcar como datos reales
        }))
        .sort((a: any, b: any) => {
          // 1. Usuarios en línea ahora (online)
          if (a.estado_visual === 'online' && b.estado_visual !== 'online') return -1;
          if (a.estado_visual !== 'online' && b.estado_visual === 'online') return 1;
          
          // 2. Usuarios activos recientemente (reciente)
          if (a.estado_visual === 'reciente' && b.estado_visual !== 'reciente') return -1;
          if (a.estado_visual !== 'reciente' && b.estado_visual === 'reciente') return 1;
          
          // 3. Usuarios activos hoy (hoy)
          if (a.estado_visual === 'hoy' && b.estado_visual !== 'hoy') return -1;
          if (a.estado_visual !== 'hoy' && b.estado_visual === 'hoy') return 1;
          
          // 4. Usuarios de esta semana (semana)
          if (a.estado_visual === 'semana' && b.estado_visual !== 'semana') return -1;
          if (a.estado_visual !== 'semana' && b.estado_visual === 'semana') return 1;
          
          // 5. Usuarios desconectados van al final
          if (a.estado_visual === 'desconectado' && b.estado_visual !== 'desconectado') return 1;
          if (a.estado_visual !== 'desconectado' && b.estado_visual === 'desconectado') return -1;
          
          // 6. Por cursos completados
          if (b.cursos_completados !== a.cursos_completados) {
            return b.cursos_completados - a.cursos_completados;
          }
          
          // 7. Por actividad más reciente
          const actividadA = new Date(a.ultima_actividad).getTime();
          const actividadB = new Date(b.ultima_actividad).getTime();
          return actividadB - actividadA;
        })
        .slice(0, 12); // ✅ Vista compacta para el dashboard
      
      console.log(`✅ [PANEL ADMIN] TODOS los alumnos cargados: ${alumnosActivos.length} activos`);
      console.log('📊 [DETALLE ALUMNOS COMPLETO]:', alumnosActivos.map(a => 
        `${a.perfiles?.nombre} - ${a.cursos_completados} cursos - ${a.estado_visual} [${a.origen}]`));
      
    } catch (error) {
      console.error('❌ [PANEL ADMIN] Error cargando alumnos activos:', error);
      alumnosActivos = [];
    }
  }

  // ✅ FUNCIONES PARA MODAL DE GESTIÓN DE ALUMNOS
  async function abrirModalGestionAlumnos() {
    mostrarModalAlumnos = true;
    await cargarTodosLosAlumnos();
  }

  function cerrarModalGestionAlumnos() {
    mostrarModalAlumnos = false;
    todosLosAlumnos = [];
  }

  async function cargarTodosLosAlumnos() {
    try {
      cargandoTodosAlumnos = true;
      console.log('🔄 [MODAL] Cargando TODOS los alumnos registrados...');
      
      const hace30Dias = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      
      // ✅ OBTENER TODOS LOS ESTUDIANTES CON ACTIVIDAD EN LOS ÚLTIMOS 30 DÍAS
      const { data: todosEstudiantes } = await supabase
        .from('sesiones_usuario')
        .select(`
          usuario_id,
          ultima_actividad,
          pagina_actual,
          esta_activo,
          tiempo_sesion_actual,
          tiempo_total_minutos,
          sesiones_totales,
          perfiles:usuario_id (
            id,
            nombre,
            apellido,
            url_foto_perfil,
            nivel_habilidad,
            suscripcion,
            rol,
            created_at
          )
        `)
        .gte('ultima_actividad', hace30Dias.toISOString())
        .order('ultima_actividad', { ascending: false })
        .limit(100); // ✅ Hasta 100 usuarios para el modal

      // ✅ PROCESAR TODOS LOS ESTUDIANTES
      const ahora = new Date();
      todosLosAlumnos = (todosEstudiantes || [])
        .filter(sesion => sesion.perfiles && sesion.perfiles.rol === 'estudiante')
        .map(sesion => {
          const minutosDesdeUpdate = Math.floor((ahora.getTime() - new Date(sesion.ultima_actividad).getTime()) / (1000 * 60));
          const horasDesdeUpdate = Math.floor(minutosDesdeUpdate / 60);
          const diasDesdeUpdate = Math.floor(horasDesdeUpdate / 24);
          
          // ✅ ESTADOS DETALLADOS
          let estado_visual = 'offline';
          let estado_texto = 'Inactivo';
          
          if (minutosDesdeUpdate <= 5) {
            estado_visual = 'online';
            estado_texto = 'En línea ahora';
          } else if (minutosDesdeUpdate <= 30) {
            estado_visual = 'reciente';
            estado_texto = `Hace ${minutosDesdeUpdate}m`;
          } else if (horasDesdeUpdate <= 24) {
            estado_visual = 'hoy';
            estado_texto = `Hace ${horasDesdeUpdate}h`;
          } else if (diasDesdeUpdate <= 7) {
            estado_visual = 'semana';
            estado_texto = `Hace ${diasDesdeUpdate}d`;
          } else {
            estado_visual = 'antiguo';
            estado_texto = `Hace ${diasDesdeUpdate}d`;
          }

          return {
            usuario_id: sesion.usuario_id,
            perfiles: sesion.perfiles,
            ultima_actividad: sesion.ultima_actividad,
            tiempo_total_minutos: sesion.tiempo_total_minutos || 0, // ✅ Ya viene correcto de la BD
            sesiones_totales: sesion.sesiones_totales || 0,
            esta_activo: minutosDesdeUpdate <= 30,
            estado_visual: estado_visual,
            estado_texto: estado_texto,
            minutos_desde_actividad: minutosDesdeUpdate,
            es_datos_reales: true
          };
        })
        .sort((a, b) => {
          // Priorizar por estado y luego por actividad reciente
          const estadoPrioridad = { online: 4, reciente: 3, hoy: 2, semana: 1, antiguo: 0 };
          const prioridadA = estadoPrioridad[a.estado_visual] || 0;
          const prioridadB = estadoPrioridad[b.estado_visual] || 0;
          
          if (prioridadA !== prioridadB) return prioridadB - prioridadA;
          
          return new Date(b.ultima_actividad).getTime() - new Date(a.ultima_actividad).getTime();
        });

      console.log(`✅ [MODAL] Cargados ${todosLosAlumnos.length} alumnos en total`);
      
    } catch (error) {
      console.error('❌ [MODAL] Error cargando todos los alumnos:', error);
      todosLosAlumnos = [];
    } finally {
      cargandoTodosAlumnos = false;
    }
  }

  function iniciarAutoRefresh() {
    if (intervalId) clearInterval(intervalId);
    
    intervalId = setInterval(async () => {
      if (autoRefresh) {
        console.log('🔄 [AUTO REFRESH] Actualizando usuarios en tiempo real...');
        
        // Cargar datos de actividad y alumnos en paralelo
        await Promise.all([
          cargarActividadTiempoReal(),
          cargarAlumnosActivos()
        ]);
        
        ultimaActualizacion = new Date().toLocaleTimeString();
        console.log('✅ [AUTO REFRESH] Datos actualizados');
      }
    }, 10000); // Cada 10 segundos para tiempo real
    
    console.log('🔄 [AUTO REFRESH] Iniciado cada 10 segundos');
  }

  function toggleAutoRefresh() {
    autoRefresh = !autoRefresh;
  }

  function reintentar() {
    cargarDatos();
  }

  function mostrarAyudaSetup(mensaje: string) {
    alert(mensaje);
  }
</script>

<main class="panel-administracion">
  {#if !esAdmin}
    <div class="verificando-acceso">
      <div class="spinner"></div>
      <p>Verificando permisos de administrador...</p>
    </div>
  {:else}
    <!-- ENCABEZADO DEL PANEL -->
    <div class="encabezado-panel">
      <div class="info-panel">
        <div class="icono-panel">
          <i class="fas fa-chart-line"></i>
        </div>
        <div class="detalles-panel">
          <h1>Panel Administración</h1>
          <p>Academia Vallenata Online • {new Date().toLocaleDateString('es-ES', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
          <p class="ultima-actualizacion">Última actualización: {ultimaActualizacion}</p>
        </div>
      </div>
      
      <div class="controles-panel">
        <button 
          class="boton-auto-refresh" 
          class:activo={autoRefresh}
          on:click={toggleAutoRefresh}
        >
          <i class="fas fa-sync-alt"></i>
          Auto {autoRefresh ? 'ON' : 'OFF'}
        </button>
        
                    <button class="boton-refrescar" on:click={cargarDatos}>
          <i class="fas fa-refresh"></i>
          Refrescar
        </button>
      </div>
    </div>

    <!-- INDICADOR DE ERROR -->
    {#if errorCarga}
      <div class="alerta-error">
        <div class="contenido-error">
          <i class="fas fa-exclamation-triangle"></i>
          <div>
            <strong>Error al cargar los datos del panel.</strong>
            <p>Inténtalo de nuevo.</p>
          </div>
          <button class="boton-reintentar" on:click={reintentar}>
            Reintentar
          </button>
        </div>
      </div>
    {/if}

    {#if cargandoDatos}
      <!-- INDICADOR DE CARGA -->
      <div class="cargando-datos">
        <div class="spinner-grande"></div>
        <h3>Cargando estadísticas...</h3>
        <p>Obteniendo métricas de la academia</p>
      </div>
    {:else}
      <!-- CONTENIDO PRINCIPAL DEL PANEL -->
      <div class="contenido-panel">
        
        <!-- ESTADÍSTICAS GENERALES -->
        <div class="seccion-estadisticas">
          <EstadisticasGenerales 
            datos={estadisticasGenerales}
            on:clickCursos={() => goto('/administrador/contenido')}
            on:clickUsuarios={() => goto('/administrador/usuarios')}
          />
        </div>

        <!-- 🚀 SISTEMA DE PESTAÑAS ORGANIZADAS -->
        <div class="seccion-pestañas">
          <PestanasAdministracion 
            {actividadTiempoReal}
            {alumnosActivos}
            {estadisticasGenerales}
            onGestionarTodos={abrirModalGestionAlumnos}
          />
        </div>

      </div>
    {/if}
  {/if}
</main>

<style>
  .panel-administracion {
    min-height: 100vh;
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
    padding: 2rem;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  }

  .verificando-acceso {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 50vh;
    color: white;
    text-align: center;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(255, 255, 255, 0.3);
    border-top: 4px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  .encabezado-panel {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 2rem;
    background: rgba(255, 255, 255, 0.05);
    padding: 2rem;
    border-radius: 20px;
    backdrop-filter: blur(20px);
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .info-panel {
    display: flex;
    align-items: center;
    gap: 1.5rem;
  }

  .icono-panel {
    width: 60px;
    height: 60px;
    background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
    border-radius: 15px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.5rem;
    color: white;
  }

  .detalles-panel h1 {
    margin: 0 0 0.5rem 0;
    font-size: 2rem;
    font-weight: 700;
    color: white;
  }

  .detalles-panel p {
    margin: 0;
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.875rem;
  }

  .ultima-actualizacion {
    margin-top: 0.25rem !important;
    font-size: 0.75rem !important;
    color: rgba(255, 255, 255, 0.5) !important;
  }

  .controles-panel {
    display: flex;
    gap: 1rem;
  }

  .boton-auto-refresh,
  .boton-refrescar {
    padding: 0.75rem 1.5rem;
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    background: rgba(255, 255, 255, 0.1);
    color: white;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.875rem;
    font-weight: 500;
  }

  .boton-auto-refresh:hover,
  .boton-refrescar:hover {
    background: rgba(255, 255, 255, 0.2);
    border-color: rgba(255, 255, 255, 0.3);
  }

  .boton-auto-refresh.activo {
    background: rgba(34, 197, 94, 0.2);
    border-color: rgba(34, 197, 94, 0.4);
    color: #22c55e;
  }

  .alerta-error {
    margin-bottom: 2rem;
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid rgba(239, 68, 68, 0.3);
    border-radius: 15px;
    padding: 1.5rem;
  }

  .contenido-error {
    display: flex;
    align-items: center;
    gap: 1rem;
    color: #ef4444;
  }

  .contenido-error i {
    font-size: 1.5rem;
  }

  .boton-reintentar {
    padding: 0.5rem 1rem;
    background: rgba(239, 68, 68, 0.2);
    border: 1px solid rgba(239, 68, 68, 0.4);
    border-radius: 8px;
    color: #ef4444;
    cursor: pointer;
    transition: all 0.3s ease;
  }

  .boton-reintentar:hover {
    background: rgba(239, 68, 68, 0.3);
  }

  .cargando-datos {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 400px;
    color: white;
    text-align: center;
  }

  .spinner-grande {
    width: 60px;
    height: 60px;
    border: 6px solid rgba(255, 255, 255, 0.3);
    border-top: 6px solid #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 2rem;
  }

  .cargando-datos h3 {
    margin: 0 0 0.5rem 0;
    font-size: 1.5rem;
    font-weight: 600;
  }

  .cargando-datos p {
    margin: 0;
    color: rgba(255, 255, 255, 0.7);
  }

  .contenido-panel {
    display: flex;
    flex-direction: column;
    gap: 2rem;
  }

  .seccion-estadisticas {
    width: 100%;
  }

  .seccion-analytics {
    width: 100%;
    margin-bottom: 2rem;
  }

  /* 🚀 ESTILOS SISTEMA DE PESTAÑAS */
  .seccion-pestañas {
    width: 100%;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  @media (max-width: 1200px) {
    /* Responsive para pestañas se maneja en el componente */
  }

  @media (max-width: 768px) {
    .panel-administracion {
      padding: 1rem;
    }

    .encabezado-panel {
      flex-direction: column;
      gap: 1rem;
    }

    .controles-panel {
      width: 100%;
      justify-content: center;
    }
  }
</style> 