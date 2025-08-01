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
  import { TiempoService } from '$lib/services/tiempoService';
  import { trackingRealService } from '$lib/services/trackingActividadReal';
  import { actividadService } from '$lib/services/actividadTiempoRealService';
  import { servicioGeoEspanol } from '$lib/services/servicioGeolocalizacionEspanol';
  
  // Variables para heartbeat automático del admin
  let heartbeatInterval: NodeJS.Timeout | null = null;
  
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
        await servicioGeoEspanol.rastreoCompleto();
        
        // Marcar como rastreado hoy
        sessionStorage.setItem(cacheKey, 'true');
        sessionStorage.setItem('geo_today', hoy);
        sessionStorage.removeItem('nueva_sesion'); // Limpiar flag
      }
    } catch (error) {
      console.warn('⚠️ [GEO-SMART] Error en rastreo inteligente:', error);
    }
  }

  // Detectar si la ruta es de detalle de tutorial o curso (SIN MENÚ NI SIDEBAR)
  $: rutaEsDetalleTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+$/) !== null;
  
  // 🕒 Tracking de tiempo por página
  $: if (browser && $page.url.pathname) {
    TiempoService.iniciarTiempoPagina($page.url.pathname);
    
    // 🎯 TRACKING ESPECÍFICO DE ACTIVIDAD - solo para usuarios autenticados
    if ($usuario) {
      trackingRealService.cambiarPagina($page.url.pathname);
      
      // 🌍 GEOLOCALIZACIÓN INTELIGENTE - solo cuando sea necesario
      verificarYEjecutarGeolocalizacion();
      
      // También actualizar actividad en inscripciones si está en curso/tutorial
      actualizarActividadReal($page.url.pathname);
    
    // 🔥 TRACKING AUTOMÁTICO MEJORADO - registrar cada navegación
    if ($usuario && $page.url.pathname.includes('/panel-administracion')) {
      // Registrar actividad en panel de admin
      registrarActividadAdmin();
      
      // Iniciar heartbeat para admin (cada 30 segundos)
      iniciarHeartbeatAdmin();
    } else {
      // Detener heartbeat si sale del panel
      detenerHeartbeatAdmin();
    }
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
            tiempo_total_minutos: tiempoTotalAcumulado + Math.floor(tiempoSesionActual / 5), // ✅ Incrementar gradualmente
            sesiones_totales: sesionesTotales,
            updated_at: ahora
          }, {
            onConflict: 'usuario_id,fecha'
          });
          
        if (upsertError) {
          console.warn('⚠️ [SESIONES] Error upsert:', upsertError.message);
        } else {
          console.log('✅ [SESIONES] Sesión actualizada para:', $usuario.nombre);
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
  
  // Páginas de PANTALLA COMPLETA TOTAL (sin nada)
  $: esPaginaPantallaCompleta = rutaEsDetalleTutorial || rutaEsContenidoTutorial || rutaEsDetalleCurso || rutaEsSimuladorAcordeon;
  
  // Páginas que solo deben tener MENÚ INFERIOR (clases y lecciones)
  $: esPaginaSoloMenuInferior = rutaEsClaseTutorial || rutaEsClaseCurso || rutaEsLeccionCurso;
  
  // Variable combinada para compatibilidad
  $: esPaginaSinMenu = esPaginaPantallaCompleta;

  // Detectar si es una página del perfil fijo
  $: rutaActual = $page.url.pathname;
  $: esPaginaPerfilFijo = ['/mi-perfil', '/mis-cursos', '/mis-eventos', '/publicaciones', '/grabaciones', '/configuracion'].includes(rutaActual);
  
  // Detectar si se debe ocultar la barra de progreso
  $: ocultarBarraProgreso = esPaginaPantallaCompleta;

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
   * 🚀 CRITICAL: Corregir problemas de renderización y scroll
   */
  function corregirRenderizacion() {
    if (!browser) return;
    
    // Múltiples intentos para asegurar renderización correcta
    const intentarCorreccion = () => {
      try {
        console.log('🔧 [LAYOUT] Corrigiendo renderización...');
        
        // 1. Forzar reflow del documento
        const body = document.body;
        const html = document.documentElement;
        
        // 2. Corregir overflow y scroll
        body.style.overflow = 'auto';
        html.style.overflow = 'auto';
        body.style.height = 'auto';
        html.style.height = '100%';
        
        // 3. Forzar recálculo de layout
        body.offsetHeight; // Trigger reflow
        html.offsetHeight; // Trigger reflow
        
        // 4. Corregir scroll behavior
        body.style.scrollBehavior = 'smooth';
        html.style.scrollBehavior = 'smooth';
        
        // 5. Asegurar que el scroll funcione
        if (body.scrollHeight <= window.innerHeight) {
          body.style.minHeight = '100vh';
        }
        
        console.log('✅ [LAYOUT] Renderización corregida');
      } catch (err) {
        console.warn('⚠️ [LAYOUT] Error corrigiendo renderización:', err);
      }
    };
    
    // Ejecutar inmediatamente
    intentarCorreccion();
    
    // Ejecutar después de que el DOM esté completamente listo
    setTimeout(intentarCorreccion, 100);
    
    // Ejecutar después de que la hidratación esté completa
    setTimeout(intentarCorreccion, 500);
    
    // Escuchar cambios de ruta para re-corregir
    if (typeof window !== 'undefined') {
      window.addEventListener('popstate', intentarCorreccion);
      
      // 🚨 EMERGENCY: Detectar si el scroll no funciona y corregirlo
      setTimeout(() => {
        detectarYCorregirScrollProblemas();
      }, 1000);
    }
  }

  /**
   * 🚨 EMERGENCY: Detectar y corregir problemas de scroll automáticamente
   */
  function detectarYCorregirScrollProblemas() {
    if (!browser) return;
    
    try {
      const body = document.body;
      const html = document.documentElement;
      
      // Verificar si el contenido es más alto que la ventana pero no se puede hacer scroll
      const contenidoAlto = body.scrollHeight > window.innerHeight;
      const scrollPosible = window.scrollY > 0 || body.scrollTop > 0 || html.scrollTop > 0;
      
      if (contenidoAlto && !scrollPosible) {
        console.warn('🚨 [LAYOUT] Problema de scroll detectado, corrigiendo...');
        
        // Corrección de emergencia
        body.style.overflow = 'auto !important';
        html.style.overflow = 'auto !important';
        body.style.height = 'auto !important';
        body.style.minHeight = '100vh';
        
        // Forzar reflow agresivo
        body.offsetHeight;
        html.offsetHeight;
        
        // Intentar scroll de prueba
        window.scrollTo(0, 1);
        setTimeout(() => window.scrollTo(0, 0), 100);
        
        console.log('✅ [LAYOUT] Corrección de emergencia aplicada');
      }
    } catch (err) {
      console.warn('⚠️ [LAYOUT] Error en detección de scroll:', err);
    }
  }

  onMount(async () => {
    // Inicializar tema al cargar
    inicializarTema();
    
    // Sesión usuario CON MANEJO DE ERRORES
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
    })();

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
    <!-- PÁGINAS DE PANTALLA COMPLETA TOTAL (Simulador, etc.) - SIN NADA -->
    {#key $page.url.pathname}
      <div class="pantalla-completa" transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
        <slot />
      </div>
    {/key}
    
  {:else if esPaginaSoloMenuInferior && $usuario}
    <!-- PÁGINAS DE CLASES/LECCIONES - SOLO MENÚ INFERIOR -->
    {#key $page.url.pathname}
      <div class="pantalla-completa" transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
        <slot />
      </div>
    {/key}
    <MenuInferiorResponsivo />
    
  {:else if $usuario}
    <!-- USUARIO AUTENTICADO - CON MENÚ Y SIDEBAR -->
    <MenuSuperiorAutenticado />
    
    <div class="layout-autenticado">
      <AdminSidebar />
      <main class={`main-content ${$sidebarColapsado ? 'sidebar-colapsado' : ''} ${esPaginaPerfilFijo ? 'perfil-sin-padding' : ''}`}>
        {#if esPaginaPerfilFijo}
          <!-- 🔒 PÁGINAS DE PERFIL - SIN TRANSICIÓN NI KEY BLOCK PARA MÁXIMA ESTABILIDAD -->
          <slot />
        {:else}
          <!-- 🔄 OTRAS PÁGINAS - CON TRANSICIÓN NORMAL -->
          {#key $page.url.pathname}
            <div transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
              <slot />
            </div>
          {/key}
        {/if}
      </main>
    </div>
    
    <MenuInferiorResponsivo />
    
  {:else}
    <!-- USUARIO NO AUTENTICADO - SOLO MENÚ PÚBLICO -->
    <MenuPublico />
    {#key $page.url.pathname}
      <div transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
        <slot />
      </div>
    {/key}
  {/if}
  
{/if}

<!-- Chat Widget flotante - Disponible en toda la aplicación (excepto en mensajería, pantalla completa y clases) -->
{#if !$page.url.pathname.includes('/mensajes') && !esPaginaPantallaCompleta && !esPaginaSoloMenuInferior}
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
  
  /* ✅ CRITICAL: Forzar renderización correcta del body y html */
  :global(html) {
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto !important;
    scroll-behavior: smooth;
  }
  
  :global(body) {
    height: 100%;
    overflow-x: hidden;
    overflow-y: auto !important;
    scroll-behavior: smooth;
    /* Forzar reflow para corregir renderización */
    will-change: scroll-position;
  }
  
  /* ✅ CRITICAL: Corregir elementos que pueden interferir con el scroll */
  :global([style*="position: fixed"]),
  :global([style*="position: absolute"]) {
    backface-visibility: hidden;
  }
  
  /* ✅ CRITICAL: Asegurar que los containers principales funcionen correctamente */
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
</style>
