<script lang="ts">
  import { usuario } from '$lib/UsuarioActivo/usuario';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onMount, onDestroy } from 'svelte';
  
  // 🚨 COMPORTAMIENTO INTELIGENTE DEL MENU
  let menuVisible = false; // 🚨 OCULTO POR DEFECTO
  let timeoutInactividad: NodeJS.Timeout;
  let ultimaActividad = Date.now();
  const TIEMPO_INACTIVIDAD = 2000; // 2 segundos de inactividad (más rápido)

  // Determinar el tipo de usuario y ruta actual
  $: tipoUsuario = $usuario?.rol === 'admin' ? 'admin' : 'estudiante';
  $: rutaActual = $page.url.pathname;

  // Función para verificar si una ruta está activa
  function esRutaActiva(ruta: string): boolean {
    if (ruta === '/panel-administracion' || ruta === '/estudiante') {
      return rutaActual === ruta;
    }
    return rutaActual.startsWith(ruta);
  }

  // Navegación para administradores
  const menuAdmin = [
    {
      id: 'dashboard',
      icono: 'dashboard',
      texto: 'Panel',
      		ruta: '/panel-administracion',
      badge: '3'
    },
    {
      id: 'contenido',
      icono: 'contenido',
      texto: 'Contenido',
      ruta: '/administrador/panel-contenido',
      badge: null
    },
    {
      id: 'mensajes',
      icono: 'mensajes',
      texto: 'Mensajes',
      ruta: '/mensajes',
      badge: '5'
    },
    {
      id: 'comunidad',
      icono: 'comunidad',
      texto: 'Comunidad',
      ruta: '/comunidad',
      badge: '12'
    },
    {
      id: 'perfil',
      icono: 'perfil',
      texto: 'Perfil',
      ruta: '/mi-perfil',
      badge: null
    }
  ];

  // Navegación para estudiantes
  const menuEstudiante = [
    {
      id: 'panel',
      icono: 'dashboard',
      texto: 'Inicio',
      ruta: '/panel-estudiante',
      badge: null
    },
    {
      id: 'comunidad',
      icono: 'comunidad',
      texto: 'Comunidad',
      ruta: '/comunidad',
      badge: '5'
    },
    {
      id: 'cursos',
      icono: 'cursos',
      texto: 'Mis Cursos',
      ruta: '/mis-cursos',
      badge: '75%'
    },
    {
      id: 'blog',
      icono: 'blog',
      texto: 'Blog',
      ruta: '/blog',
      badge: null
    },
    {
      id: 'perfil',
      icono: 'perfil',
      texto: 'Perfil',
      ruta: '/mi-perfil',
      badge: null
    }
  ];

  $: menuItems = tipoUsuario === 'admin' ? menuAdmin : menuEstudiante;

  function navegarA(ruta: string) {
    goto(ruta);
  }
  
  // 🚨 FUNCIONES PARA COMPORTAMIENTO INTELIGENTE
  function detectarActividad() {
    ultimaActividad = Date.now();
    if (!menuVisible) {
      mostrarMenu(); // 🚨 MOSTRAR MENU AL TOCAR
    }
    reiniciarTimeoutInactividad();
  }
  
  // 🚨 FUNCIÓN MEJORADA PARA DETECTAR ACTIVIDAD
  function detectarActividadMejorada(evento: string, elemento: string = '') {
    console.log(`🎯 [MENU] Actividad detectada: ${evento} ${elemento}`);
    detectarActividad();
  }
  
  function ocultarMenu() {
    menuVisible = false;
    console.log('📱 [MENU] Ocultando menu por actividad del usuario');
  }
  
  function mostrarMenu() {
    menuVisible = true;
    console.log('📱 [MENU] Mostrando menu por inactividad');
  }
  
  function reiniciarTimeoutInactividad() {
    if (timeoutInactividad) {
      clearTimeout(timeoutInactividad);
    }
    
    timeoutInactividad = setTimeout(() => {
      if (Date.now() - ultimaActividad >= TIEMPO_INACTIVIDAD) {
        ocultarMenu(); // 🚨 OCULTAR MENU POR INACTIVIDAD
      }
    }, TIEMPO_INACTIVIDAD);
  }
  
  // 🚨 DETECTAR ACTIVIDAD DEL USUARIO - VERSIÓN SIMPLIFICADA
  function configurarDetectoresActividad() {
    console.log('🚀 [MENU] Configurando detectores de actividad...');
    
    // 🚨 EVENTOS BÁSICOS DEL USUARIO
    const eventos = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
    eventos.forEach(evento => {
      document.addEventListener(evento, detectarActividad, { passive: true });
    });
    
    // 🚨 DETECCIÓN DE VIDEO - VERSIÓN SIMPLE
    setTimeout(() => {
      const videos = document.querySelectorAll('video, iframe');
      console.log(`🎥 [MENU] Videos encontrados: ${videos.length}`);
      
      videos.forEach((video, index) => {
        video.addEventListener('play', () => detectarActividadMejorada('play', `video-${index}`));
        video.addEventListener('pause', () => detectarActividadMejorada('pause', `video-${index}`));
        video.addEventListener('seeking', () => detectarActividadMejorada('seeking', `video-${index}`));
      });
    }, 1000); // Esperar 1 segundo para que se carguen los videos
    
    // 🚨 DETECCIÓN DE TABS - VERSIÓN SIMPLE
    setTimeout(() => {
      const tabs = document.querySelectorAll('[role="tab"], .tab, .tab-button');
      console.log(`📑 [MENU] Tabs encontrados: ${tabs.length}`);
      
      tabs.forEach((tab, index) => {
        tab.addEventListener('click', () => detectarActividadMejorada('click', `tab-${index}`));
      });
    }, 1000); // Esperar 1 segundo para que se carguen los tabs
    
    // 🚨 DETECCIÓN DE BOTONES DE NAVEGACIÓN - VERSIÓN SIMPLE
    setTimeout(() => {
      const botones = document.querySelectorAll('button');
      console.log(`🔄 [MENU] Botones encontrados: ${botones.length}`);
      
      botones.forEach((boton, index) => {
        const texto = boton.textContent || '';
        if (texto.includes('Anterior') || texto.includes('Siguiente') || texto.includes('Marcar como completada')) {
          boton.addEventListener('click', () => detectarActividadMejorada('click', `boton-${texto.trim()}`));
        }
      });
    }, 1000); // Esperar 1 segundo para que se carguen los botones
  }

  function obtenerIcono(tipo: string) {
    const iconos: { [key: string]: string } = {
      dashboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect x="3" y="3" width="7" height="9"/>
        <rect x="14" y="3" width="7" height="5"/>
        <rect x="14" y="12" width="7" height="9"/>
        <rect x="3" y="16" width="7" height="5"/>
      </svg>`,
      contenido: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14,2 14,8 20,8"/>
        <line x1="16" y1="13" x2="8" y2="13"/>
        <line x1="16" y1="17" x2="8" y2="17"/>
      </svg>`,
      crear: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
        <polyline points="14,2 14,8 20,8"/>
        <line x1="12" y1="18" x2="12" y2="12"/>
        <line x1="9" y1="15" x2="15" y2="15"/>
      </svg>`,
      cursos: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/>
        <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>
      </svg>`,
      tutoriales: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polygon points="23 7 16 12 23 17 23 7"/>
        <rect x="1" y="5" width="15" height="14" rx="2" ry="2"/>
      </svg>`,
      comunidad: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
        <circle cx="9" cy="7" r="4"/>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
        <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>`,
      perfil: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
        <circle cx="12" cy="7" r="4"/>
      </svg>`,
      mensajes: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
      </svg>`,
      blog: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14,2 14,8 20,8"/>
        <line x1="16" y1="13" x2="8" y2="13"/>
        <line x1="16" y1="17" x2="8" y2="17"/>
        <path d="M10 9h4"/>
      </svg>`
    };
    return iconos[tipo] || iconos.dashboard;
  }
  
  // 🚨 INICIALIZAR COMPORTAMIENTO INTELIGENTE
  onMount(() => {
    try {
      console.log('🚀 [MENU] Menu inferior responsivo montado');
      
      configurarDetectoresActividad();
      reiniciarTimeoutInactividad();
      
    } catch (error) {
      console.error('❌ [MENU] Error al inicializar:', error);
      // Fallback: mostrar menu siempre
      menuVisible = true;
    }
  });
  
  // 🚨 FUNCIÓN SIMPLE: MOSTRAR/OCULTAR MENU
  function toggleMenu() {
    menuVisible = !menuVisible;
    console.log(`📱 [MENU] Menu ${menuVisible ? 'mostrado' : 'oculto'}`);
  }
  
  onDestroy(() => {
    console.log('❌ [MENU] Menu inferior responsivo desmontando');
    if (timeoutInactividad) {
      clearTimeout(timeoutInactividad);
    }
    
    // Limpiar event listeners
    const eventos = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
    eventos.forEach(evento => {
      document.removeEventListener(evento, detectarActividad);
    });
  });
</script>

<!-- Solo mostrar para usuarios logueados y en pantallas móviles -->
{#if $usuario}
  <nav class="menu-inferior-responsivo" class:visible={menuVisible}>
    <div class="menu-container">
      {#each menuItems as item}
        <button 
          class="menu-item cursor-hover" 
          class:activo={esRutaActiva(item.ruta)}
          on:click={() => navegarA(item.ruta)}
          aria-label={item.texto}
        >
          <div class="item-icon">
            {@html obtenerIcono(item.icono)}
          </div>
          <span class="item-text">{item.texto}</span>
          {#if item.badge}
            <div class="item-badge" class:progreso={item.badge.includes('%')} class:nuevo={item.badge === 'Nuevo'}>
              {item.badge}
            </div>
          {/if}
        </button>
      {/each}
    </div>
  </nav>
{/if}

<style>
  .menu-inferior-responsivo {
    position: fixed !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    background: rgba(255, 255, 255, 0.95) !important;
    backdrop-filter: blur(20px) !important;
    border-top: 1px solid #e2e8f0 !important;
    z-index: 999999 !important;
    padding: 0 !important;
    display: block !important; /* 🚨 VISIBLE EN MÓVIL */
    box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.08) !important;
    transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1) !important;
    transform: translateY(100%) !important; /* 🚨 OCULTO POR DEFECTO */
  }
  
  /* 🚨 CLASE PARA MOSTRAR EL MENU */
  .menu-inferior-responsivo.visible {
    transform: translateY(0) !important; /* Visible */
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
  }
  
  /* 🚨 CLASE PARA OCULTAR EL MENU */
  .menu-inferior-responsivo:not(.visible) {
    transform: translateY(100%) !important; /* Oculto */
    opacity: 0 !important;
  }

  /* Mostrar solo en pantallas móviles */
  @media (max-width: 900px) {
    .menu-inferior-responsivo {
      display: block !important;
    }
  }

  .menu-container {
    display: flex;
    justify-content: space-around;
    align-items: center;
    padding: 8px 16px;
    max-width: 100%;
    margin: 0 auto;
    gap: 4px;
  }

  .menu-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 8px 12px;
    background: none;
    border: none;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    border-radius: 16px;
    position: relative;
    min-width: 60px;
    flex: 1;
    max-width: 80px;
  }

  .menu-item:hover {
    background: rgba(102, 126, 234, 0.1);
    transform: translateY(-2px);
  }

  .menu-item.activo {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  .menu-item.activo:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
  }

  .item-icon {
    width: 24px;
    height: 24px;
    margin-bottom: 4px;
    color: #64748b;
    transition: color 0.3s ease;
  }

  .menu-item.activo .item-icon {
    color: white;
  }

  .menu-item:hover .item-icon {
    color: #667eea;
  }

  .menu-item.activo:hover .item-icon {
    color: white;
  }

  .item-text {
    font-size: 11px;
    font-weight: 600;
    color: #64748b;
    text-align: center;
    line-height: 1.2;
    transition: color 0.3s ease;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    max-width: 100%;
  }

  .menu-item.activo .item-text {
    color: white;
  }

  .menu-item:hover .item-text {
    color: #667eea;
  }

  .menu-item.activo:hover .item-text {
    color: white;
  }

  .item-badge {
    position: absolute;
    top: 4px;
    right: 8px;
    background: #ef4444;
    color: white;
    font-size: 9px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 16px;
    text-align: center;
    line-height: 1.2;
    transform: scale(0.9);
    animation: badge-pulse 2s infinite;
  }

  .item-badge.progreso {
    background: #3b82f6;
    animation: none;
  }

  .item-badge.nuevo {
    background: #22c55e;
    animation: badge-bounce 1s ease-in-out infinite alternate;
  }

  .menu-item.activo .item-badge {
    background: rgba(255, 255, 255, 0.9);
    color: #667eea;
  }

  /* Animaciones */
  @keyframes badge-pulse {
    0% { transform: scale(0.9); }
    50% { transform: scale(1.1); }
    100% { transform: scale(0.9); }
  }

  @keyframes badge-bounce {
    0% { transform: scale(0.9) translateY(0); }
    100% { transform: scale(1) translateY(-2px); }
  }

  /* Ajustes para pantallas muy pequeñas */
  @media (max-width: 480px) {
    .menu-container {
      padding: 6px 8px;
      gap: 2px;
    }

    .menu-item {
      padding: 6px 8px;
      min-width: 50px;
      max-width: 70px;
    }

    .item-icon {
      width: 20px;
      height: 20px;
      margin-bottom: 2px;
    }

    .item-text {
      font-size: 10px;
    }

    .item-badge {
      font-size: 8px;
      padding: 1px 4px;
      top: 2px;
      right: 4px;
    }
  }

  /* ✅ PADDING EFECTIVO para evitar que el contenido se oculte detrás del menú */
  @media (max-width: 900px) {
    :global(body) {
      padding-bottom: 130px !important;
    }
    
    /* Asegurar padding en containers principales */
    :global(.pantalla-completa),
    :global(.main-content),
    :global(main),
    :global(.contenido-principal) {
      padding-bottom: 110px !important;
    }
    
    /* Específico para páginas de clases y lecciones */
    :global(.pantalla-completa) {
      min-height: calc(100vh - 110px) !important;
    }
  }
  
  /* 🚨 CSS DE EMERGENCIA - FORZAR VISIBILIDAD SIEMPRE */
  .menu-inferior-responsivo {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
    position: fixed !important;
    bottom: 0 !important;
    left: 0 !important;
    right: 0 !important;
    z-index: 999999 !important;
  }
  
  /* 🚨 SOBRESCRIBIR CUALQUIER ESTILO DEL LAYOUT */
  .menu-inferior-responsivo[style*="display: none"],
  .menu-inferior-responsivo[style*="visibility: hidden"],
  .menu-inferior-responsivo[style*="opacity: 0"],
  .menu-inferior-responsivo[style*="transform: translateY(100%)"] {
    display: block !important;
    visibility: visible !important;
    opacity: 1 !important;
    transform: translateY(0) !important;
  }
</style> 