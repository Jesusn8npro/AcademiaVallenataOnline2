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

  // Detectar si la ruta es de detalle de tutorial o curso (SIN MENÚ NI SIDEBAR)
  $: rutaEsDetalleTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+$/) !== null;
  $: rutaEsClaseTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsDetalleCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+$/) !== null;
  $: rutaEsClaseCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsLeccionCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/[^\/]+\/[^\/]+$/) !== null;
  
  // Páginas que NO deben tener menú ni sidebar (PANTALLA COMPLETA)
  $: esPaginaSinMenu = rutaEsDetalleTutorial || rutaEsClaseTutorial || rutaEsDetalleCurso || rutaEsClaseCurso || rutaEsLeccionCurso;

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
      <main class={`main-content ${$sidebarColapsado ? 'sidebar-colapsado' : ''}`}>
        {#key $page.url.pathname}
          <div transition:fly={{ x: 30, opacity: 0, duration: 220 }}>
            <slot />
          </div>
        {/key}
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
</style>
