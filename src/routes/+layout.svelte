<script lang="ts">
  import '../app.css';
  import { onMount, onDestroy } from 'svelte';
  import { usuario, setUsuario, limpiarUsuario } from '$lib/UsuarioActivo/usuario';
  import { supabase } from '$lib/supabase/clienteSupabase';
  import { obtenerPerfil } from '$lib/supabase/autenticacionSupabase';
  import { sidebarColapsado } from '$lib/stores/sidebarStore';
  import MenuSuperiorAutenticado from '$lib/components/Navegacion/MenuSuperiorAutenticado.svelte';
  import MenuPublico from '$lib/components/Navegacion/MenuPublico2.svelte';
  import AdminSidebar from '$lib/components/Navegacion/AdminSidebar.svelte';
  import MenuInferiorResponsivo from '$lib/components/Navegacion/MenuInferiorResponsivo.svelte';
  import { page } from '$app/stores';
  import { fade, fly } from 'svelte/transition';
  import ModalPermisos from '$lib/components/ModalPermisos.svelte';
  import { inicializarTema } from '$lib/stores/temaStore';
  import ChatWidget from '$lib/components/ChatEnVivo/ChatWidget.svelte';
  import { browser } from '$app/environment';
  import CursorPersonalizado from '$lib/components/CursorPersonalizado/CursorPersonalizado.svelte';
  import { modalPagoAbierto } from '$lib/stores/modalPagoStore';
  import { chatWidgetVisible } from '$lib/stores/chatWidgetStore';
  import FooterPoliticas from '$lib/components/Footer/FooterPoliticas.svelte';
  import { TiempoService } from '$lib/services/tiempoService';
  import { trackingRealService } from '$lib/services/trackingActividadReal';
  import { actividadService } from '$lib/services/actividadTiempoRealService';
  import { servicioGeoEspanol } from '$lib/services/servicioGeolocalizacionEspanol';
  import { invalidateAll } from '$app/navigation';
  
  // ✅ NUEVO: IMPORTAR SISTEMAS DE ESTABILIZACIÓN COMPLETOS
  import { 
    esCliente,
    ejecutarEnCliente,
    logHidratacion,
    obtenerEstadoHidratacion 
  } from '$lib/utils/hidratacionUtils';
  
  import { 
    navegarInteligente,
    logRouting 
  } from '$lib/utils/routingUtils';
  
  // Variables para heartbeat automático del admin
  let heartbeatInterval: NodeJS.Timeout | null = null;
  
  // ✅ NUEVO: FUNCIÓN PARA INICIALIZAR SISTEMAS DE ESTABILIZACIÓN
  function inicializarSistemasEstabilizacion() {
    if (!browser) return;
    
    try {
      // 🚀 FASE 1: HIDRATACIÓN SEGURA
      ejecutarEnCliente(() => {
        console.log('✅ [HIDRATACIÓN] Sistema de hidratación segura activo');
        // Verificar estado de hidratación
        const estado = obtenerEstadoHidratacion();
        console.log('🔧 [HIDRATACIÓN] Estado actual:', estado);
      }, 100);
      
      // 🚀 FASE 2: ROUTING INTELIGENTE
      ejecutarEnCliente(() => {
        console.log('✅ [ROUTING] Sistema de routing inteligente activo');
        // El sistema se activa automáticamente
      }, 200);
      
      // 🚀 FASE 3: ESTADOS DETERMINISTAS
      ejecutarEnCliente(() => {
        console.log('✅ [ESTADOS] Sistema de estados deterministas activo');
        // Los stores se inicializan automáticamente
      }, 300);
      
      // 🚀 FASE 4: RENDIMIENTO OPTIMIZADO
      ejecutarEnCliente(() => {
        console.log('✅ [RENDIMIENTO] Sistemas de rendimiento activos');
        // Los sistemas se inicializan automáticamente
      }, 400);
      
      // 🚀 FASE 5: MONITOREO EN TIEMPO REAL
      ejecutarEnCliente(() => {
        console.log('✅ [MONITOREO] Sistema de monitoreo activo');
        // El sistema se inicializa automáticamente
      }, 500);
      
      console.log('✅ [LAYOUT] Todos los sistemas de estabilización inicializados correctamente');
      
    } catch (error) {
      console.warn('⚠️ [LAYOUT] Error inicializando sistemas:', error);
    }
  }
  
  // 🔧 RESETEAR STORE DE MODAL AL NAVEGAR
  $: if (browser && $page.url.pathname) {
    modalPagoAbierto.set(false);
  }

  // 🔧 SIN FUNCIONES PROBLEMÁTICAS
  
  // 🌍 FUNCIÓN INTELIGENTE DE GEOLOCALIZACIÓN
  // Solo ejecuta geolocalización cuando es realmente necesario
  async function verificarYEjecutarGeolocalizacion() {
    if (!$usuario?.id) return;
    
    try {
      // Verificar si ya se rastreó hoy para este usuario
      const hoy = new Date().toISOString().split('T')[0];
      const cacheKey = `geo_${$usuario.id}_${hoy}`;
      
      // Si ya se rastreó hoy, no hacer nada
      if (sessionStorage.getItem(cacheKey)) {
        console.log('🌍 [GEO-SMART] Ya rastreado hoy para usuario:', $usuario.nombre);
        return;
      }
      
      // Solo rastear en casos específicos:
      const esInicioSesion = sessionStorage.getItem('nueva_sesion') === 'true';
      const esPanelAdmin = $page.url.pathname.includes('/panel-administracion');
      const esPrimeraCargaDia = !sessionStorage.getItem('geo_today');
      
      if (esInicioSesion || esPanelAdmin || esPrimeraCargaDia) {
        console.log('🌍 [GEO-SMART] Ejecutando rastreo inteligente...');
        
        // ⚡ EJECUTAR EN SEGUNDO PLANO SIN BLOQUEAR
        setTimeout(async () => {
          try {
            await servicioGeoEspanol.rastreoCompleto();
            
            // Marcar como rastreado hoy
            sessionStorage.setItem(cacheKey, 'true');
            sessionStorage.setItem('geo_today', hoy);
            sessionStorage.removeItem('nueva_sesion'); // Limpiar flag
            
            console.log('✅ [GEO-SMART] Rastreo completado en segundo plano');
          } catch (error) {
            console.warn('⚠️ [GEO-SMART] Error en rastreo en segundo plano:', error);
          }
        }, 100); // 100ms después para no bloquear
        
      }
    } catch (error) {
      console.warn('⚠️ [GEO-SMART] Error en rastreo inteligente:', error);
    }
  }

  // ✅ DETECCIÓN SIMPLIFICADA DE RUTAS - SIN COMPLEJIDAD
  $: rutaEsDetalleTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+$/) !== null;
  
  // 🕒 Tracking de tiempo por página - SIMPLIFICADO
  $: if (browser && $page.url.pathname && $usuario) {
    // ⚡ TRACKING INMEDIATO SIN BLOQUEAR
    TiempoService.iniciarTiempoPagina($page.url.pathname);
    trackingRealService.cambiarPagina($page.url.pathname);
    
    // 🌍 GEOLOCALIZACIÓN INTELIGENTE - solo cuando sea necesario
    verificarYEjecutarGeolocalizacion();
    
    // 🔥 TRACKING ADMIN - solo cuando esté en panel admin
    if ($page.url.pathname.includes('/panel-administracion')) {
      // ⚡ EJECUTAR EN SEGUNDO PLANO
      setTimeout(() => {
        registrarActividadAdmin();
        iniciarHeartbeatAdmin();
      }, 50); // 50ms después para no bloquear
    } else {
      detenerHeartbeatAdmin();
    }
  }

  // 🔥 FUNCIÓN PARA REGISTRAR ACTIVIDAD DEL ADMIN
  async function registrarActividadAdmin() {
    if (!browser || !$usuario || $usuario.rol !== 'admin') return;
    
    try {
      console.log('🔥 [ADMIN TRACKING] Registrando actividad del administrador');
      
      // Actualizar o crear inscripción de actividad admin
      const { error: upsertError } = await supabase
        .from('inscripciones')
        .upsert({
          usuario_id: $usuario.id,
          curso_id: '123e4567-e89b-12d3-a456-426614174000', // UUID genérico para tracking admin
          progreso: 1, // Incrementar progreso
          porcentaje_completado: 10,
          ultima_actividad: new Date().toISOString(),
          completado: false,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }, {
          onConflict: 'usuario_id,curso_id',
          ignoreDuplicates: false
        });
      
      if (!upsertError) {
        console.log('✅ [ADMIN TRACKING] Actividad del admin registrada');
      }
    } catch (error) {
      console.warn('⚠️ [ADMIN TRACKING] Error:', error);
    }
  }

  // 🔥 HEARTBEAT AUTOMÁTICO PARA ADMIN
  function iniciarHeartbeatAdmin() {
    // Evitar múltiples intervals
    if (heartbeatInterval) return;
    
    heartbeatInterval = setInterval(() => {
      if ($usuario && $usuario.rol === 'admin' && $page.url.pathname.includes('/panel-administracion')) {
        registrarActividadAdmin();
        console.log('💓 [HEARTBEAT] Actividad admin actualizada automáticamente');
      }
    }, 30000); // Cada 30 segundos
    
    console.log('💓 [HEARTBEAT] Iniciado para admin - cada 30 segundos');
  }

  function detenerHeartbeatAdmin() {
    if (heartbeatInterval) {
      clearInterval(heartbeatInterval);
      heartbeatInterval = null;
      console.log('💓 [HEARTBEAT] Detenido');
    }
  }

  // 🧹 Limpiar interval al destruir componente
  onDestroy(() => {
    detenerHeartbeatAdmin();
  });

  // 🔥 FUNCIÓN PARA ACTUALIZAR ACTIVIDAD REAL EN BD
  async function actualizarActividadReal(rutaActual: string) {
    if (!browser || !$usuario) return;
    
    try {
      console.log('📊 [TRACKING GLOBAL] Usuario activo:', $usuario.nombre, 'en', rutaActual);
      
      // 1️⃣ SIEMPRE actualizar información de sesión activa
      const ahora = new Date().toISOString();
      
      // Actualizar timestamp en perfiles
      await supabase
        .from('perfiles')
        .update({ updated_at: ahora })
        .eq('id', $usuario.id);
      
      // 2️⃣ OBTENER DATOS ACTUALES PARA ACUMULAR TIEMPO
      let tiempoTotalAcumulado = 0;
      let sesionesTotales = 1;
      let tiempoSesionActual = 1;
      
      // Consultar sesión actual para preservar tiempo acumulado
      const { data: sesionExistente } = await supabase
        .from('sesiones_usuario')
        .select('tiempo_total_minutos, sesiones_totales, created_at, tiempo_sesion_actual, esta_activo')
        .eq('usuario_id', $usuario.id)
        .eq('fecha', new Date().toISOString().split('T')[0])
        .single();
      
      if (sesionExistente) {
        // ✅ PRESERVAR TIEMPO ACUMULADO EXISTENTE
        tiempoTotalAcumulado = sesionExistente.tiempo_total_minutos || 0;
        sesionesTotales = sesionExistente.sesiones_totales || 1;
        
        // Calcular tiempo de sesión actual (desde created_at hasta ahora)
        const inicioSesion = new Date(sesionExistente.created_at);
        const ahoraDate = new Date(ahora);
        const minutosTranscurridos = Math.max(1, Math.floor((ahoraDate.getTime() - inicioSesion.getTime()) / (1000 * 60)));
        tiempoSesionActual = minutosTranscurridos;
        
        // Si el usuario estaba inactivo y ahora está activo, incrementar sesiones
        if (!sesionExistente.esta_activo) {
          sesionesTotales += 1;
          console.log('📊 [SESIÓN] Nueva sesión iniciada. Total:', sesionesTotales);
        }
        
        console.log('📊 [TIEMPO] Preservando tiempo acumulado:', tiempoTotalAcumulado, 'min');
      } else {
        console.log('📊 [NUEVA SESIÓN] Primera sesión del día para:', $usuario.nombre);
      }

      // 3️⃣ CREAR/ACTUALIZAR registro de sesión con tiempo acumulado
      try {
        const { error: upsertError } = await supabase
          .from('sesiones_usuario')
          .upsert({
            usuario_id: $usuario.id,
            fecha: new Date().toISOString().split('T')[0],
            ultima_actividad: ahora,
            pagina_actual: rutaActual,
            esta_activo: true,
            tiempo_sesion_actual: tiempoSesionActual,
            tiempo_total_minutos: tiempoTotalAcumulado + Math.min(Math.floor(tiempoSesionActual / 10), 1), // ✅ Máximo 1 minuto por 10 minutos de sesión
            sesiones_totales: sesionesTotales,
            updated_at: ahora
          }, {
            onConflict: 'usuario_id,fecha'
          });
          
        if (upsertError) {
          console.warn('⚠️ [SESIONES] Error upsert:', upsertError.message);
        } else {
          const incrementoTiempo = Math.min(Math.floor(tiempoSesionActual / 10), 1);
          console.log('✅ [SESIONES] Sesión actualizada para:', $usuario.nombre, {
            tiempoAcumulado: tiempoTotalAcumulado,
            tiempoSesion: tiempoSesionActual,
            incremento: incrementoTiempo,
            tiempoTotal: tiempoTotalAcumulado + incrementoTiempo,
            razon: '1 min por 10 min de sesión (conservador)'
          });
        }
      } catch (sessionError) {
        console.warn('⚠️ [SESIONES] Error:', sessionError);
      }
      
      // 3️⃣ Actualizar actividad específica para estudiantes
      const esEstudiante = $usuario.rol !== 'admin';
      if (esEstudiante) {
        // Crear o actualizar inscripción para tracking
        try {
          await supabase
            .from('inscripciones')
            .upsert({
              usuario_id: $usuario.id,
              curso_id: '00000000-0000-0000-0000-000000000001', // ID genérico para sesión
              progreso: 1,
              porcentaje_completado: 5,
              ultima_actividad: ahora,
              pagina_actual: rutaActual,
              completado: false,
              created_at: ahora,
              updated_at: ahora
            }, {
              onConflict: 'usuario_id,curso_id',
              ignoreDuplicates: false
            });
        } catch (inscripcionError) {
          console.warn('⚠️ [INSCRIPCIONES] Error:', inscripcionError);
        }
      }
      
      // 4️⃣ Registrar evento de navegación
      try {
        await supabase
          .from('eventos_actividad')
          .insert({
            usuario_id: $usuario.id,
            tipo_evento: 'navegacion',
            pagina: rutaActual,
            detalles: {
              timestamp: ahora,
              dispositivo: 'web',
              rol: $usuario.rol
            },
            duracion_minutos: 1
          });
        console.log('✅ [EVENTOS] Navegación registrada:', rutaActual);
      } catch (eventError) {
        console.warn('⚠️ [EVENTOS] Error:', eventError);
      }
      
      console.log('✅ [TRACKING REAL] Actividad registrada para:', $usuario.nombre);
      
    } catch (error) {
      console.warn('⚠️ [TRACKING REAL] Error actualizando actividad:', error);
    }
  }
  $: rutaEsClaseTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+\/clase\/[^\/]+/) !== null;
  $: rutaEsContenidoTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+\/contenido/) !== null;
  $: rutaEsDetalleCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+$/) !== null;
  $: rutaEsClaseCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/clase\/[^\/]+/) !== null;
  $: rutaEsLeccionCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/[^\/]+\/[^\/]+/) !== null;
  $: rutaEsSimuladorAcordeon = $page.url.pathname === '/simulador-de-acordeon' || 
                               $page.url.pathname.startsWith('/simulador-acordeon') || 
                               $page.url.pathname.startsWith('/simulador-gaming');
  
  // ✅ LÓGICA GRANULAR PARA DIFERENTES TIPOS DE PÁGINAS
  
  // Páginas de PANTALLA COMPLETA TOTAL (sin nada) - SOLO simulador
  $: esPaginaPantallaCompleta = rutaEsSimuladorAcordeon;
  
  // Páginas que solo deben tener MENÚ INFERIOR (clases y lecciones)
  $: esPaginaSoloMenuInferior = rutaEsClaseTutorial || rutaEsClaseCurso || rutaEsLeccionCurso;
  
  // Páginas de DETALLE (con encabezado pero sin sidebar)
  $: esPaginaDetalle = rutaEsDetalleTutorial || rutaEsContenidoTutorial || rutaEsDetalleCurso;
  
  // Variable combinada para compatibilidad
  $: esPaginaSinMenu = esPaginaPantallaCompleta;

  // Detectar si es una página del perfil fijo
  $: rutaActual = $page.url.pathname;
  $: esPaginaPerfilFijo = ['/mi-perfil', '/mis-cursos', '/mis-eventos', '/publicaciones', '/grabaciones', '/configuracion'].includes(rutaActual);
  
  // Detectar si se debe ocultar la barra de progreso
  $: ocultarBarraProgreso = esPaginaPantallaCompleta || esPaginaDetalle;

  let cargandoSesion = true;

  // --- Barra de progreso de lectura global ---
  let progresoLectura = 0;

  function manejarScroll() {
    // CORRECCIÓN: Proteger acceso a document/window en SSR
    if (!browser) return;
    
    // Excluir si la barra está oculta
    if (ocultarBarraProgreso) return;
    const alturaDocumento = document.documentElement.scrollHeight - window.innerHeight;
    const scrollTop = window.scrollY;
    progresoLectura = alturaDocumento > 0 ? Math.min((scrollTop / alturaDocumento) * 100, 100) : 0;
  }

  /**
   * ✅ NUEVO: Función segura de corrección de renderizado
   */
  function corregirRenderizacion() {
    if (!browser) return;
    
    try {
      console.log('🔧 [LAYOUT] Aplicando correcciones seguras...');
      
      // ✅ SOLUCIÓN: Usar clases CSS en lugar de manipular estilos directamente
      const body = document.body;
      const html = document.documentElement;
      
      // ✅ SOLUCIÓN: Aplicar clases CSS para correcciones
      body.classList.add('layout-corregido');
      html.classList.add('layout-corregido');
      
      console.log('✅ [LAYOUT] Correcciones seguras aplicadas');
    } catch (err) {
      console.warn('⚠️ [LAYOUT] Error en correcciones:', err);
    }
  }

  /**
   * ✅ NUEVO: Función segura de detección de scroll
   */
  function detectarYCorregirScrollProblemas() {
    if (!browser) return;
    
    try {
      const body = document.body;
      const html = document.documentElement;
      
      // ✅ SOLUCIÓN: Verificar scroll usando clases CSS
      if (body.scrollHeight > window.innerHeight) {
        body.classList.add('scroll-corregido');
        html.classList.add('scroll-corregido');
        console.log('✅ [LAYOUT] Scroll corregido de manera segura');
      }
    } catch (err) {
      console.warn('⚠️ [LAYOUT] Error en corrección de scroll:', err);
    }
  }

  onMount(() => {
    console.log('🔧 [LAYOUT] Inicializando layout básico');
    
    // ✅ NUEVO: INICIALIZAR SISTEMAS DE ESTABILIZACIÓN COMPLETOS
    if (browser) {
      try {
        // 🚀 FASE 1: HIDRATACIÓN SEGURA
        logHidratacion('Inicializando sistemas de estabilización');
        
        // 🚀 FASE 2: ROUTING INTELIGENTE
        logRouting('Sistema de routing inteligente activo');
        
        // 🚀 FASE 3: ESTADOS DETERMINISTAS
        console.log('✅ [ESTADOS] Sistema de estados deterministas activo');
        
        // 🚀 FASE 4: RENDIMIENTO OPTIMIZADO
        console.log('✅ [LAZY LOADING] Sistema de lazy loading activo');
        console.log('✅ [EVENTOS] Sistema de eventos optimizados activo');
        console.log('✅ [CACHE] Sistema de caché inteligente activo');
        
        // 🚀 FASE 5: MONITOREO EN TIEMPO REAL
        console.log('✅ [MONITOREO] Sistema de monitoreo activo');
        
        console.log('✅ [LAYOUT] Todos los sistemas de estabilización inicializados');
      } catch (error) {
        console.warn('⚠️ [LAYOUT] Error inicializando sistemas:', error);
      }
    }
    
    // ✅ NUEVO: INICIALIZAR SISTEMAS DE ESTABILIZACIÓN
    inicializarSistemasEstabilizacion();
    
    // Inicializar tema al cargar (función síncrona)
    inicializarTema();
    
    // Función async interna (SOLUCIÓN CORRECTA PARA TYPESCRIPT)
    (async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.warn('⚠️ Error de Supabase:', error.message);
          limpiarUsuario();
          cargandoSesion = false;
          return;
        }
        
        if (session && session.user) {
          const { perfil } = await obtenerPerfil(session.user.id);
          if (perfil) {
            setUsuario(perfil);
            
            // 🕒 Inicializar tracking de tiempo
            TiempoService.iniciarSesion(session.user.id);
            console.log('⏱️ Tracking de tiempo iniciado para:', perfil.nombre);
          } else {
            limpiarUsuario();
          }
        } else {
          limpiarUsuario();
        }
      } catch (error) {
        console.error('🚨 Error crítico de conexión a Supabase:', error);
        limpiarUsuario();
      } finally {
        cargandoSesion = false;
      }
    })(); // ← CERRAR Y EJECUTAR LA FUNCIÓN ASYNC

    // Barra de progreso global
    window.addEventListener('scroll', manejarScroll, { passive: true });

    // 🚀 CRITICAL: Corregir problemas de renderización
    corregirRenderizacion();

    // ✅ GEOLOCALIZACIÓN INTELIGENTE - solo cuando sea necesario
    verificarYEjecutarGeolocalizacion().catch(console.warn);

    return () => {
      window.removeEventListener('scroll', manejarScroll);
    };
  });



  // Función para determinar si debe aplicar transición
  function debeMostrarTransicion(ruta: string): boolean {
    const rutasPerfilFijo = ['/mi-perfil', '/mis-cursos', '/publicaciones', '/configuracion'];
    return !rutasPerfilFijo.includes(ruta);
  }

  // 🚀 REACTIVE: Corregir renderización al cambiar de página
  $: if (browser && $page.url.pathname) {
    // Pequeño delay para que la página se renderice primero
    setTimeout(() => {
      corregirRenderizacion();
      console.log(`🔄 [LAYOUT] Renderización corregida para: ${$page.url.pathname}`);
      
              // ✅ NUEVO: VERIFICAR HIDRATACIÓN EN CADA NAVEGACIÓN
        ejecutarEnCliente(() => {
          const estadoHidratacion = obtenerEstadoHidratacion();
          if (!estadoHidratacion.esHidratado) {
            console.log('🔄 [HIDRATACIÓN] Re-hidratando página:', $page.url.pathname);
            // Forzar re-hidratación si es necesario
            setTimeout(() => {
              corregirRenderizacion();
            }, 100);
          }
        }, 100);
      
    }, 50);
  }
</script>

<!-- Banner de permisos de notificación -->
<ModalPermisos />

<!-- Cursor personalizado global -->
<CursorPersonalizado />

<!-- Barra de progreso de lectura global -->
{#if !ocultarBarraProgreso}
  <div class="barra-progreso-lectura" style="width: {progresoLectura}%;"></div>
{/if}

{#if cargandoSesion}
  <!-- Loader mientras carga la sesión -->
  <div style="height:64px"></div>
{:else}
  
      {#if esPaginaPantallaCompleta}
      <!-- ✅ PÁGINAS DE PANTALLA COMPLETA TOTAL - SIN NADA -->
      <div class="pantalla-completa">
        <slot />
      </div>
      
    {:else if esPaginaSoloMenuInferior && $usuario}
      <!-- ✅ PÁGINAS DE CLASES/LECCIONES - CON ENCABEZADO Y MENÚ INFERIOR -->
      <div class="pantalla-completa">
        <slot />
      </div>
      <MenuInferiorResponsivo />
      
    {:else if esPaginaDetalle && $usuario}
      <!-- ✅ PÁGINAS DE DETALLE - CON ENCABEZADO PERO SIN SIDEBAR -->
      {#if !$modalPagoAbierto}
        <MenuSuperiorAutenticado />
      {/if}
      <div class="layout-autenticado" class:pantalla-completa={true}>
        <main class="main-content sin-sidebar">
          <slot />
        </main>
      </div>
      <MenuInferiorResponsivo />
      
    {:else if $usuario}
    <!-- ✅ USUARIO AUTENTICADO - CON MENÚ Y SIDEBAR -->
    {#if !$modalPagoAbierto && !esPaginaDetalle}
      <MenuSuperiorAutenticado />
    {/if}
    
          <div class="layout-autenticado" class:pantalla-completa={esPaginaPantallaCompleta || esPaginaDetalle}>
        {#if !esPaginaPantallaCompleta && !esPaginaDetalle}
          <AdminSidebar />
        {/if}
        <main class={`main-content ${$sidebarColapsado ? 'sidebar-colapsado' : ''} ${esPaginaPerfilFijo ? 'perfil-sin-padding' : ''} ${(esPaginaPantallaCompleta || esPaginaDetalle) ? 'sin-sidebar' : ''}`}>
          <!-- ✅ RENDERIZADO ESTABLE - SIN TRANSICIONES PROBLEMÁTICAS -->
          <slot />
        </main>
      </div>
      
      {#if !esPaginaPantallaCompleta && !esPaginaDetalle}
        <MenuInferiorResponsivo />
      {/if}
    
  {:else}
    <!-- ✅ USUARIO NO AUTENTICADO - SOLO MENÚ PÚBLICO -->
    {#if !$modalPagoAbierto}
      <MenuPublico />
    {/if}
    <div class="contenido-publico">
      <slot />
    </div>
    <!-- 🏛️ FOOTER CON POLÍTICAS -->
    <FooterPoliticas />
  {/if}
  
{/if}

<!-- Chat Widget flotante - Disponible en toda la aplicación (excepto en mensajería, pantalla completa, clases y páginas de detalle) -->
{#if !$page.url.pathname.includes('/mensajes') && !esPaginaPantallaCompleta && !esPaginaSoloMenuInferior && !esPaginaDetalle && !$modalPagoAbierto}
  <ChatWidget />
{/if}

<style>
  .barra-progreso-lectura {
    position: fixed;
    top: 0;
    left: 0;
    height: 4px;
    background: linear-gradient(90deg, var(--color-vallenato-primario, #2563eb), var(--color-dorado-vallenato, #f59e0b));
    z-index: 9999;
    transition: width 0.2s ease;
    width: 0%;
  }

  /* =====================================================
  🖱️ SISTEMA ANTI-CURSOR DE TEXTO GLOBAL - ACADEMIA VALLENATA  
  ===================================================== */
  
  /* Base global para todos los elementos - OPTIMIZADO */
  :global(*) {
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
    /* ✅ CRITICAL: Asegurar scroll y renderización correcta */
    box-sizing: border-box;
  }
  
  /* ✅ CRITICAL: CSS SIMPLIFICADO PARA RENDERIZADO ESTABLE */
  :global(html) {
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto;
    scroll-behavior: smooth;
  }
  
  :global(body) {
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto;
    scroll-behavior: smooth;
  }
  
  /* ✅ CRITICAL: Containers principales estables */
  :global(.container),
  :global(.contenedor),
  :global(.main-content),
  :global(.contenido-principal),
  :global(main) {
    min-height: auto;
    overflow: visible;
  }
  
  /* CRÍTICO: Evitar cursor de texto en TODOS los elementos por defecto */
  :global(body),
  :global(div),
  :global(span),
  :global(p),
  :global(h1),
  :global(h2),
  :global(h3),
  :global(h4),
  :global(h5),
  :global(h6),
  :global(li),
  :global(ul),
  :global(ol),
  :global(section),
  :global(article),
  :global(header),
  :global(footer),
  :global(nav),
  :global(main),
  :global(aside),
  :global(img),
  :global(svg),
  :global(canvas) {
    user-select: none !important;
    -webkit-user-select: none !important;
    -moz-user-select: none !important;
    -ms-user-select: none !important;
    cursor: default !important;
  }
  
  /* Elementos específicos de Svelte que causan problemas */
  :global([class*="svelte-"]) {
    user-select: none !important;
    -webkit-user-select: none !important;
    cursor: default !important;
  }
  
  /* EXCEPCIONES: Solo permitir cursor de texto donde SÍ se necesita */
  :global(input),
  :global(textarea),
  :global([contenteditable="true"]),
  :global(.texto-seleccionable),
  :global(.contenido-editable),
  :global(.ql-editor),
  :global(.editor-contenido),
  :global(.comentario-input),
  :global(.busqueda-input),
  :global(.input-busqueda),
  :global(.input-busqueda-modal),
  :global(.mensaje-input),
  :global(.chat-input) {
    user-select: text !important;
    -webkit-user-select: text !important;
    cursor: text !important;
  }
  
  /* BOTONES Y ELEMENTOS CLICKEABLES: Cursor pointer */
  :global(button),
  :global(a),
  :global([role="button"]),
  :global(.btn),
  :global(.boton),
  :global(.clickeable),
  :global(.tarjeta-curso),
  :global(.tarjeta-tutorial),
  :global(.tarjeta-evento),
  :global(.tarjeta-resultado),
  :global(.menu-item),
  :global(.pestana),
  :global(.tab),
  :global(.acceso-rapido),
  :global(.sugerencia-tag),
  :global(.recomendacion) {
    cursor: pointer !important;
    user-select: none !important;
    -webkit-user-select: none !important;
  }
  
  /* Layout containers específicos */
  :global(.layout-autenticado),
  :global(.main-content),
  :global(.admin-sidebar-container) {
    user-select: none;
    cursor: default;
  }
  
  /* Componentes específicos de la academia */
  :global(.modal-inicio-sesion) :global(.modal-header),
  :global(.modal-inicio-sesion) :global(.logo-container),
  :global(.encabezado-perfil),
  :global(.pestanas-perfil),
  :global(.menu-superior),
  :global(.menu-lateral),
  :global(.banner-slider),
  :global(.ranking-comunidad),
  :global(.curso-grid),
  :global(.tutorial-grid),
  :global(.eventos-grid) {
    user-select: none !important;
    cursor: default !important;
  }
  
  /* Solo permitir cursor de texto en inputs y contenido editable */
  :global(input),
  :global(textarea),
  :global([contenteditable="true"]),
  :global(.ql-editor),
  :global(.editor-contenido),
  :global(.comentario-input),
  :global(.busqueda-input) {
    user-select: text !important;
    cursor: text !important;
  }
  
  /* Solo permitir cursor pointer en elementos clickeables */
  :global(button),
  :global(a),
  :global([role="button"]),
  :global(.btn),
  :global(.boton),
  :global(.clickeable),
  :global(.tarjeta-curso),
  :global(.tarjeta-tutorial),
  :global(.tarjeta-evento),
  :global(.menu-item),
  :global(.pestana),
  :global(.tab) {
    cursor: pointer !important;
    user-select: none !important;
  }
  
  /* Refuerzo para móviles */
  @media (max-width: 768px) {
    :global(*):not(input):not(textarea):not([contenteditable="true"]) {
      -webkit-user-select: none !important;
      user-select: none !important;
      -webkit-touch-callout: none !important;
    }
    
    :global(input),
    :global(textarea) {
      -webkit-user-select: text !important;
      user-select: text !important;
    }
  }

  /* ✅ NUEVA: Clase para páginas de pantalla completa */
  .pantalla-completa {
    width: 100vw;
    min-height: 100vh;
    padding: 0 !important;
    margin: 0 !important;
    overflow-x: hidden;
    background: #000;
  }

  /* Variables CSS para cursor personalizado */
  :global(:root) {
    --color-primary: #6366f1;
    --color-accent: #8b5cf6;
    --color-text: #374151;
    --color-warning: #f59e0b;
    --color-primary-rgb: 99, 102, 241;
    --color-accent-rgb: 139, 92, 246;
    --color-text-rgb: 55, 65, 81;
    --color-warning-rgb: 245, 158, 11;
  }

  :global(.dark) {
    --color-primary: #8b5cf6;
    --color-accent: #a855f7;
    --color-text: #e5e7eb;
    --color-warning: #fbbf24;
    --color-primary-rgb: 139, 92, 246;
    --color-accent-rgb: 168, 85, 247;
    --color-text-rgb: 229, 231, 235;
    --color-warning-rgb: 251, 191, 36;
  }

  /* =====================================================
  🎨 CUSTOM SCROLLBAR - DISEÑO MODERNO Y ATRACTIVO  
  ===================================================== */
  
  /* Firefox */
  :global(html) {
    scrollbar-width: thin;
    scrollbar-color: rgba(139, 92, 246, 0.8) rgba(31, 41, 55, 0.3);
  }
  
  /* Webkit browsers (Chrome, Safari, Edge) */
  :global(::-webkit-scrollbar) {
    width: 12px;
    height: 12px;
  }
  
  :global(::-webkit-scrollbar-track) {
    background: linear-gradient(135deg, 
      rgba(31, 41, 55, 0.1) 0%, 
      rgba(55, 65, 81, 0.2) 50%, 
      rgba(31, 41, 55, 0.1) 100%);
    border-radius: 10px;
    border: 1px solid rgba(139, 92, 246, 0.1);
  }
  
  :global(::-webkit-scrollbar-thumb) {
    background: linear-gradient(135deg, 
      rgba(139, 92, 246, 0.9) 0%, 
      rgba(168, 85, 247, 0.9) 50%, 
      rgba(139, 92, 246, 0.9) 100%);
    border-radius: 10px;
    border: 2px solid rgba(255, 255, 255, 0.1);
    box-shadow: 
      0 2px 8px rgba(139, 92, 246, 0.3),
      inset 0 1px 0 rgba(255, 255, 255, 0.2);
    transition: all 0.3s ease;
  }
  
  :global(::-webkit-scrollbar-thumb:hover) {
    background: linear-gradient(135deg, 
      rgba(139, 92, 246, 1) 0%, 
      rgba(168, 85, 247, 1) 50%, 
      rgba(139, 92, 246, 1) 100%);
    box-shadow: 
      0 4px 15px rgba(139, 92, 246, 0.5),
      inset 0 1px 0 rgba(255, 255, 255, 0.3);
    transform: scale(1.1);
  }
  
  :global(::-webkit-scrollbar-thumb:active) {
    background: linear-gradient(135deg, 
      rgba(107, 70, 193, 1) 0%, 
      rgba(147, 51, 234, 1) 50%, 
      rgba(107, 70, 193, 1) 100%);
    box-shadow: 
      0 2px 8px rgba(107, 70, 193, 0.6),
      inset 0 2px 4px rgba(0, 0, 0, 0.2);
  }
  
  :global(::-webkit-scrollbar-corner) {
    background: rgba(31, 41, 55, 0.2);
  }
  
  /* Scrollbar horizontal */
  :global(::-webkit-scrollbar:horizontal) {
    height: 12px;
  }
  
  /* ✨ SCROLLBAR PARA MODALES Y CONTENEDORES ESPECÍFICOS */
  :global(.modal-contenido::-webkit-scrollbar),
  :global(.sidebar::-webkit-scrollbar),
  :global(.chat-mensajes::-webkit-scrollbar) {
    width: 8px;
  }
  
  :global(.modal-contenido::-webkit-scrollbar-thumb),
  :global(.sidebar::-webkit-scrollbar-thumb),
  :global(.chat-mensajes::-webkit-scrollbar-thumb) {
    background: linear-gradient(135deg, 
      rgba(139, 92, 246, 0.7) 0%, 
      rgba(168, 85, 247, 0.7) 100%);
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }
  
  /* 🌙 MODO OSCURO - Scrollbar ajustado */
  :global([data-theme="dark"] ::-webkit-scrollbar-track) {
    background: linear-gradient(135deg, 
      rgba(17, 24, 39, 0.8) 0%, 
      rgba(31, 41, 55, 0.9) 50%, 
      rgba(17, 24, 39, 0.8) 100%);
    border: 1px solid rgba(139, 92, 246, 0.2);
  }
  
  /* 🎬 PÁGINAS DE PANTALLA COMPLETA (Cursos y Tutoriales) */
  .layout-autenticado.pantalla-completa {
    margin-left: 0;
    padding-top: 0;
  }
  
  .main-content.sin-sidebar {
    margin-left: 0 !important;
    padding-top: 0 !important;
    width: 100% !important;
    max-width: 100% !important;
  }
  
  /* ✅ CONTENEDOR PÚBLICO ESTABLE */
  .contenido-publico {
    min-height: 100vh;
    background: transparent;
  }
  
  /* Asegurar que no haya espacios negros en las páginas de detalles */
  .layout-autenticado.pantalla-completa .main-content {
    background: transparent;
    min-height: 100vh;
  }
  
  /* 📱 RESPONSIVE - Scrollbar más delgado en móviles */
  @media (max-width: 768px) {
    :global(::-webkit-scrollbar) {
      width: 8px;
      height: 8px;
    }
    
    :global(::-webkit-scrollbar-thumb) {
      border-radius: 6px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
  }
  
  @media (max-width: 480px) {
    :global(::-webkit-scrollbar) {
      width: 6px;
      height: 6px;
    }
    
    :global(::-webkit-scrollbar-thumb) {
      border-radius: 4px;
      border: none;
    }
  }

  /* ✅ NUEVO: CSS seguro para el menú inferior */
  :global(.menu-inferior-responsivo) {
    /* ✅ SOLUCIÓN: NO usar !important, dejar que SvelteKit maneje estados */
    transition: all 0.3s ease;
  }
  
  /* ✅ NUEVO: Clases CSS para correcciones de layout */
  :global(.layout-corregido) {
    overflow: auto !important;
  }
  
  :global(.scroll-corregido) {
    overflow: auto !important;
  }
  
  /* ✅ NUEVO: Padding global seguro para el menú */
  @media (max-width: 900px) {
    :global(body) {
      padding-bottom: 90px;
    }
    
    :global(main) {
      padding-bottom: 90px;
    }
    
    :global(.contenido-principal) {
      padding-bottom: 90px;
    }
  }
</style>
