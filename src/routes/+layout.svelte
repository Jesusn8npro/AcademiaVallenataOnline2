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
  import ChatWidget from '$lib/components/ChatEnVivo/ChatWidget.svelte';

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

<!-- Chat Widget flotante - Disponible en toda la aplicación -->
<ChatWidget />

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
  
  /* Base global para todos los elementos */
  :global(*) {
    -webkit-touch-callout: none;
    -webkit-tap-highlight-color: transparent;
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
</style>
