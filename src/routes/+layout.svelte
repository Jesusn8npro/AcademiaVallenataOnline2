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

  // Detectar si la ruta es de detalle de tutorial o curso (SIN MENÚ NI SIDEBAR)
  $: rutaEsDetalleTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+$/) !== null;
  $: rutaEsClaseTutorial = $page.url.pathname.match(/^\/tutoriales\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsDetalleCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+$/) !== null;
  $: rutaEsClaseCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/clase\/[^\/]+$/) !== null;
  $: rutaEsLeccionCurso = $page.url.pathname.match(/^\/cursos\/[^\/]+\/[^\/]+\/[^\/]+$/) !== null;
  
  // Páginas que NO deben tener menú ni sidebar (PANTALLA COMPLETA)
  $: esPaginaSinMenu = rutaEsDetalleTutorial || rutaEsClaseTutorial || rutaEsDetalleCurso || rutaEsClaseCurso || rutaEsLeccionCurso;

  let cargandoSesion = true;

  // Al montar el layout, consulta sesión y carga el perfil
  onMount(async () => {
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
  });
</script>

{#if cargandoSesion}
  <!-- Loader mientras carga la sesión -->
  <div style="height:64px"></div>
{:else}
  
  {#if esPaginaSinMenu}
    <!-- PÁGINAS SIN MENÚ NI SIDEBAR (Cursos, Tutoriales, Clases) -->
    <slot />
    
  {:else if $usuario}
    <!-- USUARIO AUTENTICADO - CON MENÚ Y SIDEBAR -->
    <MenuSuperiorAutenticado />
    
    <div class="layout-autenticado">
      <AdminSidebar />
      <main class={`main-content ${$sidebarColapsado ? 'sidebar-colapsado' : ''}`}>
        <slot />
      </main>
    </div>
    
    <MenuInferiorResponsivo />
    
  {:else}
    <!-- USUARIO NO AUTENTICADO - SOLO MENÚ PÚBLICO -->
    <MenuPublico />
    <slot />
  {/if}
  
{/if}
