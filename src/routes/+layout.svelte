<script lang="ts">
  import '../app.css';
  import { onMount } from 'svelte';
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
  import BannerPermisosNotificacion from '$lib/components/NotificacionesRealTime/BannerPermisosNotificacion.svelte';
  import { inicializarTema } from '$lib/stores/temaStore';
  
  // 🚀 PWA COMPONENT
  import InstaladorPWA from '$lib/components/PWA/InstaladorPWA.svelte';
  import { funcionesPWA } from '$lib/stores/pwa-store';

  // Detectar si la ruta es de detalle de tutorial o curso (SIN MENÚ NI SIDEBAR)
  $: rutaEsDetalleTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+$/) !== null;
  $: rutaEsClaseTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsDetalleCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+$/) !== null;
  $: rutaEsClaseCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsLeccionCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/[^\/]+\/[^\/]+$/) !== null;
  $: rutaEsSimuladorAcordeon = $page.url.pathname === '/simulador-de-acordeon' || 
                               $page.url.pathname.startsWith('/simulador-acordeon') || 
                               $page.url.pathname.startsWith('/simulador-gaming');
  
  // Páginas que NO deben tener menú ni sidebar (PANTALLA COMPLETA)
  $: esPaginaSinMenu = rutaEsDetalleTutorial || rutaEsClaseTutorial || rutaEsDetalleCurso || rutaEsClaseCurso || rutaEsLeccionCurso || rutaEsSimuladorAcordeon;

  // Detectar si es una página del perfil fijo
  $: rutaActual = $page.url.pathname;
  $: esPaginaPerfilFijo = ['/mi-perfil', '/mis-cursos', '/mis-eventos', '/publicaciones', '/grabaciones', '/configuracion'].includes(rutaActual);
  
  // Detectar si se debe ocultar la barra de progreso
  $: ocultarBarraProgreso = esPaginaSinMenu;

  let cargandoSesion = true;

  // --- Barra de progreso de lectura global ---
  let progresoLectura = 0;

  function manejarScroll() {
    // Excluir si la barra está oculta
    if (ocultarBarraProgreso) return;
    const alturaDocumento = document.documentElement.scrollHeight - window.innerHeight;
    const scrollTop = window.scrollY;
    progresoLectura = alturaDocumento > 0 ? Math.min((scrollTop / alturaDocumento) * 100, 100) : 0;
  }

  onMount(() => {
    // Inicializar tema al cargar
    inicializarTema();
    
    // 🚀 Inicializar PWA
    funcionesPWA.inicializar();
    
    // Sesión usuario
    (async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session && session.user) {
        const { perfil } = await obtenerPerfil(session.user.id);
        if (perfil) {
          setUsuario(perfil);
        } else {
          limpiarUsuario();
        }
      } else {
        limpiarUsuario();
      }
      cargandoSesion = false;
    })();

    // Barra de progreso global
    window.addEventListener('scroll', manejarScroll, { passive: true });

    return () => {
      window.removeEventListener('scroll', manejarScroll);
    };
  });

  // Función para determinar si debe aplicar transición
  function debeMostrarTransicion(ruta: string): boolean {
    const rutasPerfilFijo = ['/mi-perfil', '/mis-cursos', '/publicaciones', '/configuracion'];
    return !rutasPerfilFijo.includes(ruta);
  }
</script>

<!-- Banner de permisos de notificación -->
<BannerPermisosNotificacion />

<!-- 🚀 PWA INSTALADOR - DISPONIBLE GLOBALMENTE -->
<InstaladorPWA />

<!-- Barra de progreso de lectura global -->
{#if !ocultarBarraProgreso}
  <div class="barra-progreso-lectura" style="width: {progresoLectura}%;"></div>
{/if}

{#if cargandoSesion}
  <!-- Loader mientras carga la sesión -->
  <div style="height:64px"></div>
{:else}
  
  {#if esPaginaSinMenu}
    <!-- PÁGINAS SIN MENÚ NI SIDEBAR (Cursos, Tutoriales, Clases) -->
    {#key $page.url.pathname}
      <div transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
        <slot />
      </div>
    {/key}
    
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

  /* === REFUERZO GLOBAL CONTRA CURSOR DE TEXTO === */
  /* Aplicar a toda la aplicación para prevenir cursor de texto molesto */
  
  :global(*) {
    /* Prevenir cursor de texto por defecto en todos los elementos */
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
  }
  
  :global(div):not(:global(.texto-seleccionable)):not(:global(.contenido-editable)):not(:global([contenteditable="true"])) {
    user-select: none;
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    cursor: default;
  }
  
  /* Aplicar a elementos específicos de SvelteKit */
  :global(.svelte-*) {
    user-select: none;
    -webkit-user-select: none;
    cursor: default;
  }
  
  /* Asegurar que elementos de la academia no muestren cursor de texto */
  :global(.academia-vallenata) *:not(input):not(textarea):not([contenteditable="true"]):not(.texto-seleccionable) {
    user-select: none !important;
    -webkit-user-select: none !important;
    cursor: default !important;
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
</style>
